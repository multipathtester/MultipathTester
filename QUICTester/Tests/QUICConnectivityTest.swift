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
    var pingCount: Int = 5
    var pingWaitMs: Int = 200
    
    init(ipVer: IPVersion, port: UInt16, testServer: TestServer) {
        let filePrefix = "quictraffic_connectivity_" + String(port) + "_" + ipVer.rawValue
        super.init(traffic: "bulk", ipVer: ipVer, port: port, urlPath: "/connectivityTest", filePrefix: filePrefix)
        setTestServer(testServer: testServer)
        
        // Prepare the run configuration
        runCfg.printBodyVar = true
        runCfg.pingCountVar = pingCount
        runCfg.pingWaitMsVar = pingWaitMs
    }
    
    convenience init(ipVer: IPVersion, port: UInt16) {
        self.init(ipVer: ipVer, port: port, testServer: .fr)
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
            "url": getURL(),
        ]
    }
    
    func getProtocol() -> NetProtocol {
        return .QUIC
    }
    
    func getTestResult() -> TestResult {
        return ConnectivityResult(name: getDescription(), proto: getProtocol(), success: result["success"] as! Bool, result: result["error_msg"] as! String, duration: result["duration"] as! Double, startTime: startTime, waitTime: 0.0, durations: result["durations"] as! [Double])
    }
    
    // Because QUIC cannot do GET without the https:// ...
    override func getURL() -> String {
        let url = super.getURL()
        return "https://" + url
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
            print(text)
            let lines = text.components(separatedBy: .newlines)
            for line in lines {
                if line.contains("It works!") {
                    success = true
                    let mean = durations.averaged()
                    let variance = durations.variance()
                    resultMsg = String(format: "The server %@ is reachable with mean %.1f ms and variance %.1f ms.", testServer.rawValue, mean * 1000.0, variance * 1000000.0)
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
