//
//  TCPClientBulk.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 9/13/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class TCPClientBulk {
    var multipath: Bool
    var url: URL
    
    init(multipath: Bool, url: String) {
        self.multipath = multipath
        self.url = (URL(string: url))!
    }
    
    func Run() -> [String: Any] {
        var ret: Double = -1.0
        
        let config = URLSessionConfiguration.ephemeral
        if multipath {
            config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.aggregate
        }
        let session = URLSession(configuration: config)
        
        let group = DispatchGroup()
        let group2 = DispatchGroup()
        group.enter()
        group2.enter()
        
        DispatchQueue.global(qos: .userInteractive).async {
            let start = DispatchTime.now()
            group2.leave()
            let task = session.dataTask(with: self.url) { (data, resp, error) in
                guard error == nil && data != nil else {
                    print("\(String(describing: error))")
                    ret = -2.0
                    group.leave()
                    return
                }
                guard resp != nil else {
                    print("received no response")
                    ret = -1.0
                    group.leave()
                    return
                }
                let length = CGFloat((resp?.expectedContentLength)!) / 1000000.0
                let elapsed = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
                let timeInterval = Double(elapsed) / 1_000_000_000
                
                print("\(timeInterval)s for \(length) MB")
                ret = timeInterval
                group.leave()
            }
            task.resume()
        }
        
        // To be completely sure connection started
        group2.wait()
        usleep(10000)
        
        var slen: socklen_t = socklen_t(MemoryLayout<tcp_connection_info>.size)
        var tcpi = tcp_connection_info()
        var res: DispatchTimeoutResult = .timedOut
        // TODO fix hardcoded address
        var fd = findTCPFileDescriptor(expectedIP: "5.196.169.232", expectedPort: 80)
        if (fd < 0) {
            while (res == .timedOut && fd < 0) {
                res = group.wait(timeout: DispatchTime.now() + 0.01)
                print("We missed it once, try again...")
                // Retry, we might have missed the good one thinking it's and old one
                fd = findTCPFileDescriptor(expectedIP: "5.196.169.232", expectedPort: 80)
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
                fd = findTCPFileDescriptor(expectedIP: "5.196.169.232", expectedPort: 80)
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
        
        // group.wait()
        session.finishTasksAndInvalidate()
        
        return [
            "time": ret,
            "tcpInfo": tcpInfos,
        ]
    }
}
