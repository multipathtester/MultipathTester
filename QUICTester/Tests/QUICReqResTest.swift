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
        switch ipVer {
        case .v4:
            return getConfig() + " IPv4 Request Response"
        case .v6:
            return getConfig() + " IPv6 Request Response"
        default:
            return getConfig() + " Request Response"
        }
    }
    
    func getBenchDict() -> [String : Any] {
        return [
            "name": "msg",
            "config": [
                "server_port": "8008",
                "query_size": "750",
                "response_size": "750",
                "start_delay_query_response": "0",
                "nb_msgs": "35",
                "interval_time_ms": "400",
                "timeout_sec": "14",
            ],
        ]
    }
    
    func getConfig() -> String {
        if maxPathID > 0 {
            return "MPQUIC"
        } else {
            return "QUIC"
        }
    }
    
    func getTestResult() -> TestResult {
        let delays = result["delays"] as! [Int64]
        var maxDelay = Int64(-1)
        if delays.count > 0 {
            maxDelay = delays.max()!
        }
        return QUICReqResResult(name: getDescription(), runTime: Double(result["run_time"] as! String)!, missed: result["missed"] as! Int64, maxDelay: maxDelay, delays: delays)!
    }
    
    func run() -> [String : Any] {
        startTime = Date().timeIntervalSince1970
        let reqresString = QuictrafficRun(runCfg)
        var delays = [Int64]()
        let lines = reqresString!.components(separatedBy: .newlines)
        if lines[0] != "Exiting client main with error deadline exceeded" && lines[0] != "Exiting client main with error nil" {
            // An error occured...
            result = [
                "delays": [],
                "missed": Int64(35),
                "netcfgs": [],
                "run_time": "-1.0",
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
            "netcfgs": [],
            "run_time": String(format: "%.9f", 14.0),
        ]
        return result
    }
}
