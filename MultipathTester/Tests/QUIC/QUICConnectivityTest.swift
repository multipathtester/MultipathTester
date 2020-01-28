//
//  QUICConnectivityTest.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 11/29/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Quictraffic

class QUICConnectivityTest: BaseConnectivityTest {
    convenience init(ipVer: IPVersion, port: UInt16, testServer: TestServer, pingCount: Int, pingWaitMs: Int) {
        let filePrefix = "quictraffic_connectivity_" + String(port) + "_" + ipVer.rawValue
        self.init(ipVer: ipVer, port: port, testServer: testServer, pingCount: pingCount, pingWaitMs: pingWaitMs, filePrefix: filePrefix, random: false)
    }
    
    override func getProtocol() -> NetProtocol {
        return .QUIC
    }
    
    override func run() {
        super.run()
        let group = DispatchGroup()
        let queue = OperationQueue()
        var durationString: String? = ""
        group.enter()
        queue.addOperation {
            durationString = QuictrafficRun(self.runCfg)
            group.leave()
        }
        var res = group.wait(timeout: .now() + TimeInterval(0.1))
        while res == .timedOut {
            if self.stopped {
                break
            }
            res = group.wait(timeout: .now() + TimeInterval(0.1))
        }
        duration = Date().timeIntervalSince(startTime)
        wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        wifiBytesSent = wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent
        wifiBytesReceived = wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived
        cellBytesSent = cellInfoEnd.bytesSent - cellInfoStart.bytesSent
        cellBytesReceived = cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived
        
        if self.stopped {
            success = false
            errorMsg = "ERROR: Test stopped"

            return
        }
        
        let durationsArray = durationString!.components(separatedBy: .newlines)
        durations = Utils.parseSeveralInMs(durationsString: durationsArray)
        do {
            let text = try String(contentsOf: outFileURL, encoding: .utf8)
            let lines = text.components(separatedBy: .newlines)
            for line in lines {
                if line.contains("It works!") {
                    success = true
                    let median = durations.median()
                    let standardDeviation = durations.standardDeviation()
                    self.errorMsg = String(format: "The server %@ is reachable with median %.1f ms and standard deviation %.1f ms.", testServer.rawValue, median, standardDeviation)
                }
                if line.contains("ERROR") {
                    self.errorMsg = line.components(separatedBy: "ERROR: ")[1]
                }
            }
        } catch { print("Nope...") }
    }
}
