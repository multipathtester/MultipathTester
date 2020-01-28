//
//  TCPConnectivityTest.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 2/24/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class TCPConnectivityTest: BaseConnectivityTest {
    var session: URLSession?
    var multipath: Bool
    
    init(ipVer: IPVersion, port: UInt16, testServer: TestServer, pingCount: Int, pingWaitMs: Int, multipath: Bool) {
        self.multipath = multipath
        
        let filePrefix = "quictraffic_connectivity_" + String(port) + "_" + ipVer.rawValue
        super.init(ipVer: ipVer, port: port, testServer: testServer, pingCount: pingCount, pingWaitMs: pingWaitMs, filePrefix: filePrefix, random: true)
    }
    
    convenience init(ipVer: IPVersion, port: UInt16, testServer: TestServer, pingCount: Int, pingWaitMs: Int) {
        self.init(ipVer: ipVer, port: port, testServer: testServer, pingCount: pingCount, pingWaitMs: pingWaitMs, multipath: false)
    }
    
    override func getProtocol() -> NetProtocol {
        // We used to always try to do MPTCP, but it was a mistake as networks might block it
        // So it might be either TCP or MPTCP
        if multipath {
            return .MPTCP
        }
        return .TCP
    }
    
    func performRequest(session: URLSession, count: Int) -> Bool {
        let group = DispatchGroup()
        let url = URL(string: getURL())!
        group.enter()
        let start = DispatchTime.now()
        let task = session.dataTask(with: url) { (data, resp, error) in
            guard error == nil && data != nil else {
                self.errorMsg = "\(String(describing: error))"
                print("\(String(describing: error))")
                group.leave()
                return
            }
            guard resp != nil else {
                self.errorMsg = "received no response"
                print("received no response")
                group.leave()
                return
            }
            // let length = CGFloat((resp?.expectedContentLength)!) / 1000000.0
            let elapsed = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
            let timeInterval = Double(elapsed) / 1_000_000
            if count > 0 {
                self.durations.append(timeInterval)
            }
            
            group.leave()
        }
        task.resume()
        group.wait()
        
        // Did we got an error?
        if self.errorMsg != "" {
            return false
        }
        
        // Did we obtained the right number of pings?
        if count >= self.pingCount {
            return true
        }
        // Otherwise, wait a little before repinging
        usleep(UInt32(self.pingWaitMs) * 1000)
        return performRequest(session: session, count: count+1)
    }
    
    override func run() {
        super.run()

        let config = URLSessionConfiguration.ephemeral
        if multipath {
            switch runCfg.multipathServiceVar {
            case .aggregate:
                config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.aggregate
            case .handover:
                config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.handover
            case .interactive:
                config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.interactive
            }
        }
            
        session = URLSession(configuration: config)
        
        let group = DispatchGroup()
        group.enter()
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.success = self.performRequest(session: self.session!, count: 0)
            group.leave()
        }
        
        group.wait()
        print(durations)
        
        duration = Date().timeIntervalSince(startTime)
        wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        
        if success && durations.count > 0 {
            let median = durations.median()
            let standardDeviation = durations.standardDeviation()
            self.errorMsg = String(format: "The server %@ is reachable with median %.1f ms and standard deviation %.1f ms.", testServer.rawValue, median, standardDeviation)
        }
        
        // XXX Is it useful to collect tcp_infos here?
        
        wifiBytesSent = wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent
        wifiBytesReceived = wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived
        cellBytesSent = cellInfoEnd.bytesSent - cellInfoStart.bytesSent
        cellBytesReceived = cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived
    }
    
    func runOnePing() {
        // We first performed a run without pingCount; then we continue
        self.runCfg.pingCountVar = 1
        let wifiInfoStartPing = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        let cellInfoStartPing = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        let group = DispatchGroup()
        // To avoid performRequest to detect there were errors (while there are not)
        self.errorMsg = ""
        group.enter()
        DispatchQueue.global(qos: .userInteractive).async {
            self.success = self.performRequest(session: self.session!, count: 1)
            group.leave()
        }
        
        group.wait()
        
        duration = Date().timeIntervalSince(startTime)
        wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        
        if success {
            let median = durations.median()
            let standardDeviation = durations.standardDeviation()
            self.errorMsg = String(format: "The server %@ is reachable with median %.1f ms and standard deviation %.1f ms.", testServer.rawValue, median, standardDeviation)
        }
        
        wifiBytesSent += wifiInfoEnd.bytesSent - wifiInfoStartPing.bytesSent
        wifiBytesReceived += wifiInfoEnd.bytesReceived - wifiInfoStartPing.bytesReceived
        cellBytesSent += cellInfoEnd.bytesSent - cellInfoStartPing.bytesSent
        cellBytesReceived += cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived
    }
    
    // Finish the ping test
    func finish() {
        session?.reset {
            self.session?.finishTasksAndInvalidate()
        }
    }
}
