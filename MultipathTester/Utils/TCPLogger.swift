//
//  TCPLogger.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 3/5/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class TCPLogger {
    static func logTCPInfo(fds: [Int32], multipath: Bool) -> [String: Any] {
        let timeInfo = Date().timeIntervalSince1970
        var tcpInfosNow: [String: Any] = [
            "time": timeInfo,
        ]
        var count = 0
        for i in 0..<fds.count {
            let fd = fds[i]
            if multipath {
                // Because it seems it can crash...
                let group = DispatchGroup()
                let queue = OperationQueue()
                group.enter()
                queue.addOperation {
                    let dict = IOCTL.getMPTCPInfo(fd)
                    if dict != nil {
                        let sDict = dict as! Dictionary<String, Any>
                        tcpInfosNow[String(format: "%d", i)] = sDict
                        count += 1
                    }
                    group.leave()
                }
                // If after 100 ms, we got no response, probably something went wrong
                let res = group.wait(timeout: DispatchTime.now() + 0.1)
                if res == .timedOut {
                    print("I timeout MPTCPInfo!")
                }
            } else {
                var slen: socklen_t = socklen_t(MemoryLayout<tcp_connection_info>.size)
                var tcpi = tcp_connection_info()
                let err2 = getsockopt(fd, IPPROTO_TCP, TCP_CONNECTION_INFO, &tcpi, &slen)
                if err2 == 0 {
                    let tcpInfo = tcpInfoToDict(tcpi: tcpi)
                    tcpInfosNow[String(format: "%d", i)] = tcpInfo
                    count += 1
                }
            }
        }
        // Don't create an entry if there is nothing
        if count == 0 {
            return [:]
        }
        return tcpInfosNow
    }
    
    static func logTCPInfosMain(group: DispatchGroup, fds: [Int32], multipath: Bool, logPeriodMs: Int, test: Test) -> [[String: Any]] {
        var res: DispatchTimeoutResult = .timedOut
        
        var tcpInfos = [[String: Any]]()
        
        while (res == .timedOut) {
            res = group.wait(timeout: DispatchTime.now() + (TimeInterval(logPeriodMs) / 1000.0))
            if res == .success {
                break
            }
            if test.getStopped() {
                break
            }
            let toAdd = TCPLogger.logTCPInfo(fds: fds, multipath: multipath)
            if toAdd.count > 0 {
                tcpInfos.append(toAdd)
            }
            res = group.wait(timeout: DispatchTime.now())
        }
        
        // Go for a last TCP info before closing
        let toAdd = TCPLogger.logTCPInfo(fds: fds, multipath: multipath)
        if toAdd.count > 0 {
            tcpInfos.append(toAdd)
        }
        
        return tcpInfos
    }

}
