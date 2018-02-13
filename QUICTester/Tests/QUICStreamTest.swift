//
//  QUICStreamTest.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/22/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Quictraffic

class QUICStreamTest: BaseTest, Test {
    // MARK: Properties
    var maxPathID: UInt8
    var runTime: Int
    
    init(ipVer: IPVersion, maxPathID: UInt8, runTime: Int, waitTime: Double) {
        self.maxPathID = maxPathID
        self.runTime = runTime

        let filePrefix = "quictraffic_stream_" + ipVer.rawValue
        super.init(traffic: "stream", ipVer: ipVer, port: 5202, urlPath: nil, filePrefix: filePrefix, waitTime: waitTime)
        
        // Prepare the run configuration
        runCfg.maxPathIDVar = Int(maxPathID)
        runCfg.logPeriodMsVar = 100
        runCfg.runTimeVar = runTime
    }
    
    convenience init(ipVer: IPVersion, maxPathID: UInt8, runTime: Int) {
        self.init(ipVer: ipVer, maxPathID: maxPathID, runTime: runTime, waitTime: 3.0)
    }
    
    
    func getDescription() -> String {
        let baseConfig = getProtocol().rawValue
        switch ipVer {
        case .v4:
            return baseConfig + " IPv4 Stream"
        case .v6:
            return baseConfig + " IPv6 Stream"
        default:
            return baseConfig + " Stream"
        }
    }
    
    func getConfigDict() -> [String : Any] {
        return [
            "url": getURL(),
            "port": self.port,
            "upload_chunk_size": "2000",
            "download_chunk_size": "2000",
            "duration": String(runTime) + ".0",
            "upload_interval_time": "0.1",
            "download_interval_time": "0.1",
        ]
    }
    
    func getProtocol() -> NetProtocol {
        if maxPathID > 0 {
            return .MPQUIC
        }
        return .QUIC
    }
    
    func getTestResult() -> TestResult {
        
        let upDelays = result["up_delays"] as! [DelayData]
        let downDelays = result["down_delays"] as! [DelayData]
        var maxUpDelay = DelayData(time: -1, delayUs: 0)
        if upDelays.count > 0 {
            maxUpDelay = upDelays.max { a, b in a.delayUs < b.delayUs }!
        }
        var maxDownDelay = DelayData(time: -1, delayUs: 0)
        if downDelays.count > 0 {
            maxDownDelay = downDelays.max { a, b in a.delayUs < b.delayUs }!
        }
        let success = result["success"] as! Bool
        var resultText = ""
        if success {
            resultText = "Maximum upload delay of " + String(Double(maxUpDelay.delayUs) / 1000.0) + " ms, maximum download delay of " + String(Double(maxDownDelay.delayUs) / 1000.0) + " ms"
        } else {
            resultText = result["error_msg"] as! String
        }
        let duration = Double(result["duration"] as! String)!
        let wifiBytesSent = result["wifi_bytes_sent"] as! UInt32
        let wifiBytesReceived = result["wifi_bytes_received"] as! UInt32
        let cellBytesSent = result["cell_bytes_sent"] as! UInt32
        let cellBytesReceived = result["cell_bytes_received"] as! UInt32
        return StreamResult(name: getDescription(), proto: getProtocol(), success: success, result: resultText, duration: duration, startTime: startTime, waitTime: waitTime, wifiBytesReceived: wifiBytesReceived, wifiBytesSent: wifiBytesSent, cellBytesReceived: cellBytesReceived, cellBytesSent: cellBytesSent, multipathService: runCfg.multipathServiceVar, upDelays: upDelays, downDelays: downDelays, errorMsg: result["error_msg"] as! String)
    }
    
    override func run() -> [String : Any] {
        _ = super.run()
        let streamString = QuictrafficRun(runCfg)
        let duration = Date().timeIntervalSince(startTime)
        wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        let lines = streamString!.components(separatedBy: .newlines)
        let errorMsg = lines[0]
        if lines.count < 3 {
            result = [
                "duration": String(format: "%.9f", duration),
                "error_msg": errorMsg,
                "success": false,
                "wifi_bytes_sent": wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent,
                "wifi_bytes_received": wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived,
                "cell_bytes_sent": cellInfoEnd.bytesSent - cellInfoStart.bytesSent,
                "cell_bytes_received": cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived,
            ]
            return result
        }
        var upDelays = [DelayData]()
        var downDelays = [DelayData]()
        let splitted_up_line = lines[1].components(separatedBy: " ")
        let up_count = Int(splitted_up_line[1])!
        if up_count > 0 {
            for i in 2...up_count {
                let splitted_line = lines[i].components(separatedBy: ",")
                let ts = Double(splitted_line[0])! / 1000000000.0
                let delayUs = UInt64(splitted_line[1])!
                upDelays.append(DelayData(time: ts, delayUs: delayUs))
            }
        }
        let splitted_down_line = lines[up_count+2].components(separatedBy: " ")
        let down_count = Int(splitted_down_line[1])!
        if down_count > 0 {
            for i in up_count+3...up_count+2+down_count {
                let splitted_line = lines[i].components(separatedBy: ",")
                let ts = Double(splitted_line[0])! / 1000000000.0
                let delayUs = UInt64(splitted_line[1])!
                downDelays.append(DelayData(time: ts, delayUs: delayUs))
            }
        }
        
        var success = false
        if errorMsg.contains("nil") || errorMsg.contains("deadline exceeded") || errorMsg.contains("PeerGoingAway") {
            success = true
        }

        result = [
            "duration": String(format: "%.9f", duration),
            "error_msg": errorMsg,
            "down_delays": downDelays,
            "up_delays": upDelays,
            "success": success,
            "wifi_bytes_sent": wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent,
            "wifi_bytes_received": wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived,
            "cell_bytes_sent": cellInfoEnd.bytesSent - cellInfoStart.bytesSent,
            "cell_bytes_received": cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived,
        ]
        return result
    }
    
    // MARK: Specific to that test
    func getProgressDelays() -> ([DelayData], [DelayData]) {
        var upDelays = [DelayData]()
        var downDelays = [DelayData]()
        let delaysStr = QuictrafficGetStreamProgressResult(getNotifyID())
        let lines = delaysStr!.components(separatedBy: .newlines)
        if lines.count < 2 {
            return ([], [])
        }
        let splitted_up_line = lines[0].components(separatedBy: " ")
        let up_count = Int(splitted_up_line[1])!
        if up_count > 0 {
            for i in 1...up_count {
                let splitted_line = lines[i].components(separatedBy: ",")
                let ts = Double(splitted_line[0])! / 1000000000.0
                let delayUs = UInt64(splitted_line[1])!
                upDelays.append(DelayData(time: ts, delayUs: delayUs))
            }
        }
        let splitted_down_line = lines[up_count+1].components(separatedBy: " ")
        let down_count = Int(splitted_down_line[1])!
        if down_count > 0 {
            for i in up_count+2...up_count+1+down_count {
                let splitted_line = lines[i].components(separatedBy: ",")
                let ts = Double(splitted_line[0])! / 1000000000.0
                let delayUs = UInt64(splitted_line[1])!
                downDelays.append(DelayData(time: ts, delayUs: delayUs))
            }
        }
        return (upDelays, downDelays)
    }
}

