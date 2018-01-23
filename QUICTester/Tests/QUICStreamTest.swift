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
        runCfg.runTimeVar = 150
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
            "chunk_server_siwe": "2000",
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
        print(streamString)

        result = [
            "duration": String(format: "%.9f", 14.0),
        ]
        return result
    }
}

