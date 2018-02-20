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
    var pingCount: Int
    var pingWaitMs: Int
    
    init(ipVer: IPVersion, port: UInt16, testServer: TestServer, pingCount: Int, pingWaitMs: Int) {
        self.pingCount = pingCount
        self.pingWaitMs = pingWaitMs
        
        let filePrefix = "quictraffic_connectivity_" + String(port) + "_" + ipVer.rawValue
        super.init(traffic: "bulk", ipVer: ipVer, port: port, urlPath: "/connectivityTest", filePrefix: filePrefix, waitTime: 0.0)
        setTestServer(testServer: testServer)
        
        // Prepare the run configuration
        runCfg.printBodyVar = true
        runCfg.pingCountVar = pingCount
        runCfg.pingWaitMsVar = pingWaitMs
    }
    
    convenience init(ipVer: IPVersion, port: UInt16, testServer: TestServer) {
        self.init(ipVer: ipVer, port: port, testServer: testServer, pingCount: 5, pingWaitMs: 200)
    }
    
    convenience init(ipVer: IPVersion, port: UInt16) {
        self.init(ipVer: ipVer, port: port, testServer: .fr)
    }
    
    func getDescription() -> String {
        switch ipVer {
        case .v4:
            return "QUIC Ping IPv4"
        case .v6:
            return "QUIC Ping IPv6"
        default:
            if port != 443 {
                return "QUIC Ping port " + String(port)
            }
            return "QUIC Ping " + testServer.rawValue
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
    
    override func getRunTime() -> Double {
        return 2.0
    }
    
    // Because QUIC cannot do GET without the https:// ...
    override func getURL() -> String {
        let url = super.getURL()
        return "https://" + url
    }
    
    override func run() -> [String:Any] {
        _ = super.run()
        var success = false
        var resultMsg = ""
        let durationString = QuictrafficRun(runCfg)
        let elapsed = Date().timeIntervalSince(startTime)
        wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        let durationsArray = durationString!.components(separatedBy: .newlines)
        let durations = Utils.parseSeveralInMs(durationsString: durationsArray)
        do {
            let text = try String(contentsOf: outFileURL, encoding: .utf8)
            let lines = text.components(separatedBy: .newlines)
            for line in lines {
                if line.contains("It works!") {
                    success = true
                    let median = durations.median()
                    let standardDeviation = durations.standardDeviation()
                    resultMsg = String(format: "The server %@ is reachable with median %.1f ms and standard deviation %.1f ms.", testServer.rawValue, median, standardDeviation)
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
            "wifi_bytes_sent": wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent,
            "wifi_bytes_received": wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived,
            "cell_bytes_sent": cellInfoEnd.bytesSent - cellInfoStart.bytesSent,
            "cell_bytes_received": cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived,
        ]
        return result
    }
}
