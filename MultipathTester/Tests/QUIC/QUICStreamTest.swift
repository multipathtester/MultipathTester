//
//  QUICStreamTest.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/22/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Quictraffic

class QUICStreamTest: BaseStreamTest {
    // MARK: Properties
    var maxPathID: UInt8
    
    init(ipVer: IPVersion, maxPathID: UInt8, runTime: Int, waitTime: Double, filePrefix: String) {
        self.maxPathID = maxPathID
        super.init(ipVer: ipVer, runTime: runTime, waitTime: waitTime, filePrefix: filePrefix)
        // Prepare the run configuration
        runCfg.maxPathIDVar = Int(maxPathID)
    }
    
    convenience init(ipVer: IPVersion, maxPathID: UInt8, runTime: Int, waitTime: Double) {
        let filePrefix = "quictraffic_stream_" + ipVer.rawValue
        self.init(ipVer: ipVer, maxPathID: maxPathID, runTime: runTime, waitTime: waitTime, filePrefix: filePrefix)
    }
    
    convenience init(ipVer: IPVersion, maxPathID: UInt8, runTime: Int) {
        self.init(ipVer: ipVer, maxPathID: maxPathID, runTime: runTime, waitTime: 3.0)
    }
    
    override func getProtocol() -> NetProtocol {
        if maxPathID > 0 {
            return .MPQUIC
        }
        return .QUIC
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
    override func getProgressDelays() -> ([DelayData], [DelayData]) {
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
    
    override func stopTraffic() {
        QuictrafficStopStream(getNotifyID())
    }
    
    override func notifyReachability() {
        QuictrafficNotifyReachability(getNotifyID())
    }
}

