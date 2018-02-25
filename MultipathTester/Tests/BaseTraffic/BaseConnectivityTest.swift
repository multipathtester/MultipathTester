//
//  BaseConnectivityTest.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 2/25/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class BaseConnectivityTest: BaseTest, Test {
    // MARK: Properties
    var pingCount: Int
    var pingWaitMs: Int
    var durations: [Double] = []
    var errorMsg: String = ""
    
    init(ipVer: IPVersion, port: UInt16, testServer: TestServer, pingCount: Int, pingWaitMs: Int, filePrefix: String) {
        self.pingCount = pingCount
        self.pingWaitMs = pingWaitMs
        
        super.init(traffic: "bulk", ipVer: ipVer, port: port, urlPath: "/connectivityTest", filePrefix: filePrefix, waitTime: 0.0)
        setTestServer(testServer: testServer)
        
        // Prepare the run configuration
        runCfg.printBodyVar = true
        runCfg.pingCountVar = pingCount
        runCfg.pingWaitMsVar = pingWaitMs
    }
    
    convenience init(ipVer: IPVersion, port: UInt16, testServer: TestServer, pingCount: Int, pingWaitMs: Int) {
        let filePrefix = "base_connectivity_" + String(port) + "_" + ipVer.rawValue
        self.init(ipVer: ipVer, port: port, testServer: testServer, pingCount: pingCount, pingWaitMs: pingWaitMs, filePrefix: filePrefix)
    }
    
    convenience init(ipVer: IPVersion, port: UInt16, testServer: TestServer) {
        self.init(ipVer: ipVer, port: port, testServer: testServer, pingCount: 5, pingWaitMs: 200)
    }
    
    convenience init(ipVer: IPVersion, port: UInt16) {
        self.init(ipVer: ipVer, port: port, testServer: .fr)
    }
    
    func getDescription() -> String {
        let proto = getProtocol().rawValue
        switch ipVer {
        case .v4:
            return proto + " Ping IPv4"
        case .v6:
            return proto + " Ping IPv6"
        default:
            if port != 443 {
                return proto + " Ping port " + String(port)
            }
            return proto + " Ping " + testServer.rawValue
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
    
    override func getRunTime() -> Double {
        return 2.0
    }
    
    // Because we provide an URL, we must specify the https://, especially for QUIC...
    override func getURL() -> String {
        return "https://" + super.getURL()
    }
    
    func getProtocol() -> NetProtocol {
        fatalError("Must Override")
    }
    
    func getTestResult() -> TestResult {
        let resultMsg = result["error_msg"] as? String ?? "None"
        let duration = Double(result["duration"] as? String ?? "0.0")!
        let success = result["success"] as? Bool ?? false
        let wifiBytesSent = result["wifi_bytes_sent"] as? UInt32 ?? 0
        let wifiBytesReceived = result["wifi_bytes_received"] as? UInt32 ?? 0
        let cellBytesSent = result["cell_bytes_sent"] as? UInt32 ?? 0
        let cellBytesReceived = result["cell_bytes_received"] as? UInt32 ?? 0
        let durations = result["durations"] as? [Double] ?? []
        return ConnectivityResult(name: getDescription(), proto: getProtocol(), success: success, result: resultMsg, duration: duration, startTime: startTime, waitTime: waitTime, wifiBytesReceived: wifiBytesReceived, wifiBytesSent: wifiBytesSent, cellBytesReceived: cellBytesReceived, cellBytesSent: cellBytesSent, multipathService: runCfg.multipathServiceVar, durations: durations)
    }
}
