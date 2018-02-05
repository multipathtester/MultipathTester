//
//  QUICConnectivityTest.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 11/29/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Quictraffic

class QUICConnectivityTest: BaseTest, Test {
    // MARK: Properties
    var ipVer: IPVersion
    var port: Int16
    var url: String
    
    var pingCount: Int = 5
    var pingWaitMs: Int = 200
    
    init(port: Int16, ipVer: IPVersion) {
        self.port = port
        self.ipVer = ipVer
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
        
        url = "https://" + baseURL + ":" + String(self.port) + "/connectivityTest"
        let filePrefix = "quictraffic_connectivity_" + String(self.port) + "_" + suffix
        super.init(traffic: "bulk", url: url, filePrefix: filePrefix)
        
        // Prepare the run configuration
        runCfg.printBodyVar = true
        runCfg.pingCountVar = pingCount
        runCfg.pingWaitMsVar = pingWaitMs
    }
    
    func getDescription() -> String {
        switch ipVer {
        case .v4:
            return "QUIC IPv4 Connectivity"
        case .v6:
            return "QUIC IPv6 Connectivity"
        default:
            return "QUIC Connectivity port " + String(port)
        }
    }
    
    func getConfigDict() -> [String : Any] {
        return [
            "ping_count": pingCount,
            "ping_wait_ms": pingWaitMs,
            "port": self.port,
            "url": self.url,
        ]
    }
    
    func getProtocol() -> NetProtocol {
        return .QUIC
    }
    
    func getTestResult() -> TestResult {
        return ConnectivityResult(name: getDescription(), proto: getProtocol(), success: result["success"] as! Bool, result: result["error_msg"] as! String, duration: result["duration"] as! Double, startTime: startTime, waitTime: 0.0, durations: result["durations"] as! [Double])
    }
    
    func run() -> [String:Any] {
        startTime = Date()
        var success = false
        var resultMsg = ""
        let durationString = QuictrafficRun(runCfg)
        let elapsed = startTime.timeIntervalSinceNow
        let durationsArray = durationString!.components(separatedBy: .newlines)
        let durations = Utils.parseSeveral(durationsString: durationsArray)
        do {
            let text = try String(contentsOf: outFileURL, encoding: .utf8)
            let lines = text.components(separatedBy: .newlines)
            for line in lines {
                if line.contains("It works!") {
                    success = true
                    let mean = durations.averaged()
                    let variance = durations.variance()
                    resultMsg = String(format: "The server is reachable with mean %.1f ms and variance %.1f ms.", mean * 1000.0, variance * 1000000.0)
                }
                if line.contains("ERROR") {
                    resultMsg = line.components(separatedBy: "ERROR: ")[1]
                }
            }
        } catch { print("Nope...") }
        
        result = [
            "duration": elapsed,
            "durations": durations,
            "error_msg": resultMsg,
            "success": success,
        ]
        return result
    }
}
