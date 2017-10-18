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
    
    func Run() -> Double {
        var ret: Double = -1.0
        
        let config = URLSessionConfiguration.ephemeral
        if multipath {
            config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.aggregate
        }
        let session = URLSession(configuration: config)
        
        let group = DispatchGroup()
        group.enter()
        
        DispatchQueue.global(qos: .background).async {
            let start = DispatchTime.now()
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
        
        usleep(10000)
        
        // This is quite ugly, but Apple does not provide an easy way to collect this information...
        var saddr = sockaddr()
        var slen: socklen_t = socklen_t(MemoryLayout<sockaddr>.size)
        var tlen: socklen_t = socklen_t(MemoryLayout<tcp_connection_info>.size)
        var tcpi = tcp_connection_info()
        var theFd: Int32 = 0
        // FIXME consider changing this later to adapt to changing fd
        for fd in 0...100 {
            let err = getpeername(Int32(fd), &saddr, &slen)
            if err == -1 {
                //print("Error occurred with fd \(fd): errno is \(errno)")
            } else {
                // FIXME check if the addr is the right one
                print(err, fd, saddr.sa_data, slen, saddr, saddr.sa_len)
                theFd = Int32(fd)
            }
        }
        
        var res = group.wait(timeout: DispatchTime.now() + 0.01)
        while (res == .timedOut) {
            let err2 = getsockopt(theFd, IPPROTO_TCP, TCP_CONNECTION_INFO, &tcpi, &tlen)
            if err2 != 0 {
                print(err2, errno, ENOPROTOOPT)
            } else {
                print(tcpi)
            }
            res = group.wait(timeout: DispatchTime.now() + 0.01)
        }
        
        // group.wait()
        session.finishTasksAndInvalidate()
        
        return ret
    }
}
