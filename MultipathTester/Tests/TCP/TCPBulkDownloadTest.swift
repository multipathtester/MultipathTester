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
    
    // REMOVE ME
    override func getTestServerHostname() -> String {
        return "mptcp4.qdeconinck.be"
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
        
        let url = URL(string: getURL() + self.urlPath)!
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
        
        var slen: socklen_t = socklen_t(MemoryLayout<tcp_connection_info>.size)
        var tcpi = tcp_connection_info()
        var res: DispatchTimeoutResult = .timedOut
        let ips = ipsOf(hostname: getTestServerHostname())
        var fd = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), startAt: 3)
        if (fd < 0) {
            while (res == .timedOut && fd < 0) {
                res = group.wait(timeout: DispatchTime.now() + 0.01)
                print("We missed it once, try again...")
                // Retry, we might have missed the good one thinking it's and old one
                fd = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), startAt: 3)
            }
        }
        print("FD is \(fd)")
        
        var tcpInfos = [Any]()
        
        while (res == .timedOut) {
            res = group.wait(timeout: DispatchTime.now() + 0.01)
            let timeInfo = Date().timeIntervalSince1970
            let err2 = getsockopt(fd, IPPROTO_TCP, TCP_CONNECTION_INFO, &tcpi, &slen)
            if err2 != 0 {
                print(err2, errno, ENOPROTOOPT)
                fd = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), startAt: 3)
                print(fd)
            } else {
                tcpInfos.append(tcpInfoToDict(time: timeInfo, tcpi: tcpi))
            }
            res = group.wait(timeout: DispatchTime.now() + 0.01)
        }
        
        // Go for a last TCP info before closing
        let timeInfo = Date().timeIntervalSince1970
        let err2 = getsockopt(fd, IPPROTO_TCP, TCP_CONNECTION_INFO, &tcpi, &slen)
        if err2 != 0 {
            print(err2, errno, ENOPROTOOPT)
        } else {
            tcpInfos.append(tcpInfoToDict(time: timeInfo, tcpi: tcpi))
        }
        
        print(tcpInfos)
        // TODO process TCP INFO
        // TODO collect MPTCP info if needed
        
        wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        
        result = [
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
