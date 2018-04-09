//
//  BasePerfTest.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 2/28/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class BasePerfTest: BaseTest, Test {
    // Properties of additional results, to be set in run()
    var cwinData = [String: [CWinData]]()
    var intervals = [IntervalData]()
    var totalRetrans: UInt64 = 0
    var totalSent: UInt64 = 0
    
    
    init(ipVer: IPVersion, filePrefix: String, waitTime: Float) {
        super.init(traffic: "qperf", ipVer: ipVer, port: 5201, urlPath: nil, filePrefix: filePrefix, waitTime: 3.0)
        
        // Prepare the run configuration
        runCfg.logPeriodMsVar = 100
        runCfg.runTimeVar = 7
    }
    
    func getDescription() -> String {
        let baseConfig = getProtocol().rawValue
        switch ipVer {
        case .v4:
            return baseConfig + " IPv4 IPerf"
        case .v6:
            return baseConfig + " IPv6 IPerf"
        default:
            return baseConfig + " IPerf"
        }
    }
    
    func getConfigDict() -> [String : Any] {
        return [
            "download": false,
            "duration": runCfg.runTimeVar,
            "port": self.port,
            "url": getURL(),
        ]
    }
    
    func getTestResult() -> TestResult {
        var resultText = errorMsg
        if success {
            resultText = "Achieved a mean goodput of " + String(format: "%.3f", Double(intervals[intervals.count-1].globalBandwidth * 8) / 1000000.0) + " Mbps."
            shortResult = String(format: "%.3f Mbps", Double(intervals[intervals.count-1].globalBandwidth * 8) / 1000000.0)
        } else {
            shortResult = "Failed"
        }
        
        return PerfResult(name: getDescription(), proto: getProtocol(), success: success, result: resultText, duration: duration, startTime: startTime, waitTime: waitTime, wifiBytesReceived: wifiBytesReceived, wifiBytesSent: wifiBytesSent, cellBytesReceived: cellBytesReceived, cellBytesSent: cellBytesSent, multipathService: runCfg.multipathServiceVar, totalRetrans: totalRetrans, totalSent: totalSent, intervals: intervals, cwins: cwinData)
    }
    
    
}
