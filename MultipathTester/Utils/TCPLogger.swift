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
                let dict = IOCTL.getMPTCPInfoClean(fd)
                if dict != nil {
                    tcpInfosNow[String(format: "%d", i)] = dict!
                    count += 1
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
    
    static func logTCPInfosMain(group: DispatchGroup, fds: [Int32], multipath: Bool, logPeriodMs: Int) -> [[String: Any]] {
        var res: DispatchTimeoutResult = .timedOut
        
        var tcpInfos = [[String: Any]]()
        
        while (res == .timedOut) {
            res = group.wait(timeout: DispatchTime.now() + (TimeInterval(logPeriodMs) / 1000.0))
            if res == .success {
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
