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
    var url: String
    
    init(maxPathID: UInt8, ipVer: IPVersion) {
        self.ipVer = ipVer
        self.maxPathID = maxPathID
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
        runCfg.runTimeVar = 10
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
            "chunk_client_size": "2000",
            "chunk_server_size": "2000",
            "duration": "14.0",
            "interval_client_time": "0.1",
            "interval_server_time": "0.1",
        ]
    }
    
    func getProtocol() -> NetProtocol {
        if maxPathID > 0 {
            return .MPQUIC
        }
        return .QUIC
    }
    
    func getTestResult() -> TestResult {
        let delays = result["delays"] as! [Int64]
        var maxDelay = Int64(-1)
        if delays.count > 0 {
            maxDelay = delays.max()!
        }
        // FIXME
        // TODO
        let duration = Double(result["duration"] as! String)!
        let missed = result["missed"] as! Int64
        let resultText = "Maximum delay of " + String(maxDelay) + " ms, " + String(missed) + " missed"
        return ReqResResult(name: getDescription(), proto: getProtocol(), success: true, result: resultText, duration: duration, startTime: startTime, waitTime: 0.0, missed: missed, maxDelay: maxDelay, delays: delays)
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

