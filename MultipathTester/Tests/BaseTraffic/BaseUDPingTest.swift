//
//  BaseUDPing.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 5/17/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import Foundation
import Quictraffic

class BaseUDPingTest: BaseTest, Test {
    // MARK: Properties configurations of the test
    var wifiProbe: Bool
    
    // MARK: Additional results of the test, to be updated by the run() function
    var delays: [DelayData] = []
    
    
    init(port: UInt16, testServer: TestServer, wifiProbe: Bool, filePrefix: String) {
        self.wifiProbe = wifiProbe
        
        super.init(traffic: "udping", ipVer: .any, port: port, urlPath: "", filePrefix: filePrefix, waitTime: 0.0)
        setTestServer(testServer: testServer)
        
        // Prepare the run configuration
        runCfg.wifiProbeVar = self.wifiProbe
    }
    
    func getDescription() -> String {
        let proto = getProtocol().rawValue
        switch ipVer {
        case .v4:
            return proto + " UDPing IPv4"
        case .v6:
            return proto + " UDPing IPv6"
        default:
            if port != 443 {
                return proto + " UDPing port " + String(port)
            }
            return proto + " UDPing " + testServer.rawValue
        }
    }
    
    func getConfigDict() -> [String : Any] {
        // It is not really a test, so it has no config file...
        return [:]
    }
    
    override func getRunTime() -> Double {
        // It is not really a test...
        return 0.0
    }
    
    func getTestResult() -> TestResult {
        // No test...
        fatalError()
    }
    
    override func stop() {
        QuictrafficStopUdping(runCfg.notifyIDVar)
        stopped = true
    }
    
    override func run() {
        super.run()
        let udpingString = QuictrafficRun(self.runCfg)
        
        let lines = udpingString!.components(separatedBy: .newlines)
        print(lines.count, self.wifiProbe)
        for i in 0..<lines.count {
            let splitted_line = lines[i].components(separatedBy: ",")
            // The last line do not have any entry
            if splitted_line.count == 2 {
                let ts = Double(splitted_line[0])! / 1000000000.0
                let delayUs = UInt64(splitted_line[1])!
                delays.append(DelayData(time: ts, delayUs: delayUs))
            }
        }
        success = true
    }
}
