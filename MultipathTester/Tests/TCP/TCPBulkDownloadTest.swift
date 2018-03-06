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
        let tcpInfos = result["tcp_infos"] as! [[String: Any]]
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
    
    override func run() -> [String:Any] {
        _ = super.run()
        var success = false
        
        let config = URLSessionConfiguration.ephemeral
        if multipath {
            if runCfg.multipathServiceVar == .aggregate {
                config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.aggregate
            } else if runCfg.multipathServiceVar == .handover {
                // TODO FIXME
                config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.interactive
            }
        }
        
        let session = URLSession(configuration: config)
        
        let group = DispatchGroup()
        group.enter()
        
        let url = URL(string: getURL())!
        var elapsed = Date().timeIntervalSince(startTime)
        
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
                elapsed = Date().timeIntervalSince(self.startTime)
                print(CGFloat((resp?.expectedContentLength)!) / 1000000.0)
                success = true
                group.leave()
            }
            task.resume()
        }
        
        var res: DispatchTimeoutResult = .timedOut
        let ips = ipsOf(hostname: getTestServerHostname())
        var fd = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), startAt: 3)
        print("We tried once, at least...")
        if (fd < 0) {
            while (res == .timedOut && fd < 0) {
                res = group.wait(timeout: DispatchTime.now() + 0.01)
                print("We missed it once, try again...")
                // Retry, we might have missed the good one thinking it's and old one
                fd = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), startAt: 3)
            }
        }
        print("FD is \(fd)")
        
        // This will perform the wait on the group; once this call returns, the traffic is over
        var tcpInfos = [[String: Any]]()
        if fd > 0 {
            tcpInfos = TCPLogger.logTCPInfosMain(group: group, fds: [fd], multipath: multipath, logPeriodMs: runCfg.logPeriodMsVar)
        }
        
        wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        
        result = [
            "tcp_infos": tcpInfos,
            "duration": String(format: "%.9f", elapsed),
            "error_msg": self.errorMsg,
            "success": success,
            "wifi_bytes_sent": wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent,
            "wifi_bytes_received": wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived,
            "cell_bytes_sent": cellInfoEnd.bytesSent - cellInfoStart.bytesSent,
            "cell_bytes_received": cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived,
        ]
        return result
    }
}
