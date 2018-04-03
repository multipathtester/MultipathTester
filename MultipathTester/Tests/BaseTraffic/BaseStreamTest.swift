//
//  BaseStreamTest.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 2/25/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class BaseStreamTest: BaseTest, Test {
    // Constants
    let uploadIntervalTimeCst: UInt64 = 100 * 1_000_000 // 100 ms, in ns
    let downloadIntervalTimeCst: UInt64 = 100 * 1_000_000 // 100 ms, in ns
    let uploadChunkSize: UInt32 = 2000
    let downloadChunkSize: UInt32 = 2000
    
    var runTime: Int
    
    // Properties of additional results to be set in run()
    var upDelays: [DelayData] = []
    var downDelays: [DelayData] = []
    
    init(ipVer: IPVersion, runTime: Int, waitTime: Double, filePrefix: String) {
        self.runTime = runTime
        
        super.init(traffic: "stream", ipVer: ipVer, port: 8080, urlPath: nil, filePrefix: filePrefix, waitTime: waitTime)
        
        // Prepare the run configuration
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
            "url": getURL(),
            "port": self.port,
            "upload_chunk_size": uploadChunkSize,
            "download_chunk_size": downloadChunkSize,
            "duration": String(runTime) + ".0",
            "upload_interval_time": String(format: "%.3f", Float(Float(uploadIntervalTimeCst) / 1_000_000_000.0)),
            "download_interval_time": String(format: "%.3f", Float(Float(uploadIntervalTimeCst) / 1_000_000_000.0)),
        ]
    }
    
    func getTestResult() -> TestResult {
        var maxUpDelay = DelayData(time: -1, delayUs: 0)
        if upDelays.count > 0 {
            maxUpDelay = upDelays.max { a, b in a.delayUs < b.delayUs }!
        }
        var maxDownDelay = DelayData(time: -1, delayUs: 0)
        if downDelays.count > 0 {
            maxDownDelay = downDelays.max { a, b in a.delayUs < b.delayUs }!
        }
        var resultText = errorMsg
        if success {
            resultText = "Maximum upload delay of " + String(Double(maxUpDelay.delayUs) / 1000.0) + " ms, maximum download delay of " + String(Double(maxDownDelay.delayUs) / 1000.0) + " ms"
        }
        return StreamResult(name: getDescription(), proto: getProtocol(), success: success, result: resultText, duration: duration, startTime: startTime, waitTime: waitTime, wifiBytesReceived: wifiBytesReceived, wifiBytesSent: wifiBytesSent, cellBytesReceived: cellBytesReceived, cellBytesSent: cellBytesSent, multipathService: runCfg.multipathServiceVar, upDelays: upDelays, downDelays: downDelays, errorMsg: errorMsg)
    }
    
    func getProgressDelays() -> ([DelayData], [DelayData]) {
        // MUST BE OVERRIDEN
        return ([], [])
    }
    
    func stopTraffic() {
        // MUST BE OVERRIDEN
    }
    
    func notifyReachability() {
        // Does nothing by default, but should be overriden for QUIC traffic
    }
    
}
