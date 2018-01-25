//
//  QUICReqResTest.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/6/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Quictraffic

class QUICReqResTest: BaseTest, Test {
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
        
        url = baseURL + ":8080"
        let filePrefix = "quictraffic_reqres_" + suffix
        
        super.init(traffic: "reqres", url: url, filePrefix: filePrefix)
        
        // Prepare the run configuration
        runCfg.maxPathIDVar = Int(maxPathID)
        runCfg.logPeriodMsVar = 100
    }

    
    func getDescription() -> String {
        let baseConfig = getProtocol().rawValue
        switch ipVer {
        case .v4:
            return baseConfig + " IPv4 Request Response"
        case .v6:
            return baseConfig + " IPv6 Request Response"
        default:
            return baseConfig + " Request Response"
        }
    }
    
    func getConfigDict() -> [String : Any] {
        return [
            "url": url,
            "port": "8080",
            "query_size": "750",
            "response_size": "750",
            "start_delay_query_response": "0",
            "nb_msgs": "35",
            "interval_time_ms": "400",
            "timeout_sec": "14",
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
        let duration = Double(result["duration"] as! String)!
        let missed = result["missed"] as! Int64
        let success = result["success"] as! Bool
        var resultText = ""
        if success {
            resultText = "Maximum delay of " + String(maxDelay) + " ms."
        } else {
            resultText = result["error_msg"] as! String
        }
        return ReqResResult(name: getDescription(), proto: getProtocol(), success: success, result: resultText, duration: duration, startTime: startTime, waitTime: 0.0, missed: missed, maxDelay: maxDelay, delays: delays)
    }
    
    func run() -> [String : Any] {
        startTime = Date()
        let reqresString = QuictrafficRun(runCfg)
        var delays = [Int64]()
        let lines = reqresString!.components(separatedBy: .newlines)
        if lines[0] != "Exiting client main with error deadline exceeded" && lines[0] != "Exiting client main with error nil" {
            // An error occured...
            result = [
                "delays": [],
                "missed": Int64(35),
                "duration": "-1.0",
                "error_msg": lines[0],
                "success": false,
            ]
            return result
        }
        for i in 2..<lines.count-1 {
            delays.append(Int64(lines[i])!)
        }
        let missed = 35 - delays.count
        result = [
            "delays": delays,
            "missed": Int64(missed),
            "duration": String(format: "%.9f", 14.0), // FIXME
            "success": true,
        ]
        return result
    }
}
