//
//  TCPBulkDownloadTest.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 2/25/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class TCPBulkDownloadTest: BaseBulkDownloadTest {
    var multipath: Bool
    
    init(ipVer: IPVersion, urlPath: String, multipath: Bool) {
        self.multipath = multipath
        let filePrefix = "mptcp_bulk_" + urlPath.dropFirst() + "_" + ipVer.rawValue
        
        super.init(traffic: "bulk", ipVer: ipVer, port: 443, urlPath: urlPath, filePrefix: filePrefix, waitTime: 2.0)
        
        // Prepare the run configuration
        runCfg.logPeriodMsVar = 100
    }
    
    override func getProtocol() -> NetProtocol {
        if multipath {
            return .MPTCP
        }
        return .TCP
    }
    
    override func getTestResult() -> TestResult {
        rcvBytesDatas = [RcvBytesData]()
        for ti in tcpInfos {
            guard let connInfo = ti["0"] as? [String: Any] else {continue}
            let time = ti["time"] as! Double
            // The format is different in TCP and MPTCP
            if multipath {
                let rcvBytes = connInfo["rxbytes"] as! UInt64
                rcvBytesDatas.append(RcvBytesData(time: time, rcvBytes: rcvBytes))
            } else {
                let rcvBytes = connInfo["tcpi_rxbytes"] as! UInt64
                rcvBytesDatas.append(RcvBytesData(time: time, rcvBytes: rcvBytes))
            }
        }
        return super.getTestResult()
    }
    
    override func run() {
        super.run()
        
        let config = URLSessionConfiguration.ephemeral
        if multipath {
            switch runCfg.multipathServiceVar {
            case .aggregate:
                config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.aggregate
            case .handover:
                // Don't run handover here, but interactive instead
                runCfg.multipathServiceVar = .interactive
                config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.interactive
            case .interactive:
                config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.interactive
            }
        }
        
        let session = URLSession(configuration: config)
        
        let group = DispatchGroup()
        group.enter()
        
        let url = URL(string: getURL())!
        duration = Date().timeIntervalSince(startTime)
        
        DispatchQueue.global(qos: .userInteractive).async {
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
                self.duration = Date().timeIntervalSince(self.startTime)
                self.success = true
                group.leave()
            }
            task.resume()
        }
        
        var res: DispatchTimeoutResult = .timedOut
        let ips = ipsOf(hostname: getTestServerHostname())
        var fd = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), exclude: -1)
        print("We tried once, at least...")
        if (fd < 0) {
            while (res == .timedOut && fd < 0) {
                res = group.wait(timeout: DispatchTime.now() + 0.01)
                print("We missed it once, try again...")
                // Retry, we might have missed the good one thinking it's and old one
                fd = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), exclude: -1)
            }
        }
        print("FD is \(fd)")
        
        // This will perform the wait on the group; once this call returns, the traffic is over
        if fd > 0 {
            tcpInfos = TCPLogger.logTCPInfosMain(group: group, fds: [fd], multipath: multipath, logPeriodMs: runCfg.logPeriodMsVar, test: self)
        }
        
        wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        
        wifiBytesSent = wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent
        wifiBytesReceived = wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived
        cellBytesSent = cellInfoEnd.bytesSent - cellInfoStart.bytesSent
        cellBytesReceived = cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived
    }
}
