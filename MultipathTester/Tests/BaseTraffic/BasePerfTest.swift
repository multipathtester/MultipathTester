//
//  BasePerfTest.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 2/28/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class BasePerfTest: BaseTest, Test {
    // Properties
    var cwinData = [String: [CWinData]]()
    var intervals = [IntervalData]()
    var errorMsg: String = ""
    
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
        let duration = Double(result["duration"] as? String ?? "0.0")!
        let totalRetrans = UInt64(result["total_retrans"] as? String ?? "0")!
        let totalSent = UInt64(result["total_sent"] as? String ?? "0")!
        let success = result["success"] as? Bool ?? false
        var resultText = ""
        if success {
            resultText = "Achieved a mean goodput of " + String(format: "%.3f", Double(intervals[intervals.count-1].globalBandwidth * 8) / 1000000.0) + " Mbps."
        } else {
            resultText = result["error_msg"] as? String ?? "None"
        }
        let wifiBytesSent = result["wifi_bytes_sent"] as? UInt32 ?? 0
        let wifiBytesReceived = result["wifi_bytes_received"] as? UInt32 ?? 0
        let cellBytesSent = result["cell_bytes_sent"] as? UInt32 ?? 0
        let cellBytesReceived = result["cell_bytes_received"] as? UInt32 ?? 0
        return PerfResult(name: getDescription(), proto: getProtocol(), success: success, result: resultText, duration: duration, startTime: startTime, waitTime: waitTime, wifiBytesReceived: wifiBytesReceived, wifiBytesSent: wifiBytesSent, cellBytesReceived: cellBytesReceived, cellBytesSent: cellBytesSent, multipathService: runCfg.multipathServiceVar, totalRetrans: totalRetrans, totalSent: totalSent, intervals: intervals, cwins: cwinData)
    }
    
    
}
