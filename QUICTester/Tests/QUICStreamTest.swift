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
    var ipVer: IPVersion
    var maxPathID: UInt8
    var runTime: Int
    var url: String
    
    init(maxPathID: UInt8, ipVer: IPVersion, runTime: Int) {
        self.ipVer = ipVer
        self.maxPathID = maxPathID
        self.runTime = runTime
        var baseURL: String = "traffic.multipath-quic.org"
        var suffix: String
        switch ipVer {
        case .v4:
            baseURL = "v4.traffic.multipath-quic.org"
            suffix = "4"
        case .v6:
            baseURL = "v6.traffic.multipath-quic.org"
            suffix = "6"
        default:
            baseURL = "traffic.multipath-quic.org"
            suffix = "any"
        }
        
        url = baseURL + ":5202"
        let filePrefix = "quictraffic_stream_" + suffix
        
        super.init(traffic: "stream", url: url, filePrefix: filePrefix)
        
        // Prepare the run configuration
        runCfg.maxPathIDVar = Int(maxPathID)
        runCfg.logPeriodMsVar = 100
        runCfg.runTimeVar = runTime
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
            "url": url,
            "port": "5202",
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
        return StreamResult(name: getDescription(), proto: getProtocol(), success: true, result: resultText, duration: duration, startTime: startTime, waitTime: 0.0, upDelays: upDelays, downDelays: downDelays, errorMsg: result["error_msg"] as! String)
    }
    
    func run() -> [String : Any] {
        startTime = Date()
        let streamString = QuictrafficRun(runCfg)
        let duration = Date().timeIntervalSince(startTime)
        let lines = streamString!.components(separatedBy: .newlines)
        let errorMsg = lines[0]
        if lines.count < 3 {
            result = [
                "duration": String(format: "%.9f", duration),
                "error_msg": errorMsg,
                "success": false,
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
        if errorMsg.contains("nil") || errorMsg.contains("deadline exceeded") {
            success = true
        }

        result = [
            "duration": String(format: "%.9f", duration),
            "error_msg": errorMsg,
            "down_delays": downDelays,
            "up_delays": upDelays,
            "success": success,
        ]
        return result
    }
    
    // MARK: Specific to that test
    func getProgressDelays() -> ([DelayData], [DelayData]) {
        var upDelays = [DelayData]()
        var downDelays = [DelayData]()
        let delaysStr = QuictrafficGetStreamProgressResult()
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

