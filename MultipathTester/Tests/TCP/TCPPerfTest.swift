//
//  TCPPerfTest.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 2/28/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class TCPPerfTest: BasePerfTest {
    var multipath: Bool
    var endTime = Date()
    var stop = false
    
    init(ipVer: IPVersion, multipath: Bool) {
        self.multipath = multipath
        
        let filePrefix = "quictraffic_tperf_" + ipVer.rawValue
        super.init(ipVer: ipVer, filePrefix: filePrefix, waitTime: 3.0)
    }
    
    override func getProtocol() -> NetProtocol {
        if multipath {
            return .MPTCP
        }
        return .TCP
    }
    
    func setupMetaConnection(session: URLSession) -> (URLSessionStreamTask, UInt64, Bool) {
        let group = DispatchGroup()
        group.enter()
        var ok = false
        let metaConn = session.streamTask(withHostName: self.getTestServerHostname(), port: Int(self.port))
        metaConn.resume()
        let connID: UInt64 = UInt64(arc4random_uniform(UInt32.max)) * (UInt64(UInt32.max) + 1) + UInt64(arc4random_uniform(UInt32.max))
        let runTimeNs = UInt64(self.runCfg.runTimeVar * 1_000_000_000)
        // [Length(4)|'M'(1)|{'U' or 'D'(1)}|connID(8)|runTimeNs(8)]
        let data = NSMutableData()
        Binary.putUInt32(18, to: data)
        Binary.putUInt8(77, to: data) // 'M'
        // Only do upload so far, download will be implemented later
        Binary.putUInt8(85, to: data) // 'U'
        Binary.putUInt64(connID, to: data)
        Binary.putUInt64(runTimeNs, to: data)
        
        metaConn.write(data as Data, timeout: 10.0, completionHandler: { (error) in
            if let err = error {
                print("An write error occurred", err)
            }
        })
        metaConn.readData(ofMinLength: 1, maxLength: 1, timeout: 10.0) { (data, atEOF, error) in
            defer { group.leave() }
            guard error == nil && data != nil else {
                //self.errorMsg = "\(String(describing: error))"
                print("\(String(describing: error))")
                return
            }
            // ['1'(1)]
            let bytes = [UInt8](data!)
            guard bytes[0] == 49 else {
                print("Unexpected answer on meta conn", bytes[0])
                return
            }
            
            ok = true
        }
        group.wait()
        return (metaConn, connID, ok)
    }
    
    func setupDataConnection(session: URLSession, connID: UInt64) -> (URLSessionStreamTask, Bool) {
        let group = DispatchGroup()
        group.enter()
        var ok = false
        let upConn = session.streamTask(withHostName: self.getTestServerHostname(), port: Int(self.port))
        upConn.resume()
        // [Length(4)|'D'(1)|connID(8)]
        let data = NSMutableData()
        Binary.putUInt32(9, to: data)
        Binary.putUInt8(68, to: data) // 'D'
        Binary.putUInt64(connID, to: data)
        
        upConn.write(data as Data, timeout: 10.0, completionHandler: { (error) in
            if let err = error {
                print("An write error occurred", err)
                group.leave()
                return
            }
            ok = true
            group.leave()
        })
        group.wait()
        return (upConn, ok)
    }
    
    override func run() -> [String : Any] {
        _ = super.run()
        intervals = [IntervalData]()
        
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
        DispatchQueue.global(qos: .userInteractive).async {
            defer { group.leave() }
            let (metaConn, connID, okMeta) = self.setupMetaConnection(session: session)
            guard okMeta else { return }
            let (dataConn, okData) = self.setupDataConnection(session: session, connID: connID)
            guard okData else { return }
            self.endTime = Date().addingTimeInterval(TimeInterval(self.runCfg.runTimeVar))
            print(self.endTime.timeIntervalSinceNow)
            while Date().compare(self.endTime) == .orderedAscending && !self.stop {
                // Important to avoid overloading read calls
                let group2 = DispatchGroup()
                group2.enter()
                dataConn.resume()
                let stringData = String(repeating: "0123456789", count: 4000)
                dataConn.write(stringData.data(using: .utf8)!, timeout: self.endTime.timeIntervalSinceNow, completionHandler: { (error) in
                    defer { group2.leave() }
                    if let err = error {
                        print("An write error occurred", err)
                    }
                })
                group2.wait()
            }
        }
        
        var res: DispatchTimeoutResult = .timedOut
        let ips = ipsOf(hostname: getTestServerHostname())
        var fdMeta = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), startAt: 0)
        if (fdMeta < 0) {
            while (res == .timedOut && fdMeta < 0) {
                res = group.wait(timeout: DispatchTime.now() + 0.01)
                //print("We missed it once, try again...")
                // Retry, we might have missed the good one thinking it's and old one
                fdMeta = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), startAt: 0)
            }
        }
        print("FDMeta is \(fdMeta)")
        
        var fd = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), startAt: fdMeta + 1)
        if (fd < 0) {
            while (res == .timedOut && fd < 0) {
                res = group.wait(timeout: DispatchTime.now() + 0.01)
                //print("We missed it once, try again...")
                // Retry, we might have missed the good one thinking it's and old one
                fd = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), startAt: fdMeta + 1)
            }
        }
        print("FD is \(fd)")
        
        var lastInterval: TimeInterval = Date().timeIntervalSince1970
        
        // This will perform the wait on the group; once this call returns, the traffic is over
        var tcpInfos = [[String: Any]]()
        if fd > 0 {
            tcpInfos = TCPLogger.logTCPInfosMain(group: group, fds: [fd], multipath: multipath, logPeriodMs: runCfg.logPeriodMsVar)
        }
        let elapsed = Date().timeIntervalSince(startTime)
        wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        print(errorMsg)
        
        var transferredLastSecond: UInt64 = 0
        var retransmittedLastSecond: UInt64 = 0
        var transferredNow: UInt64 = 0
        var retransmittedNow: UInt64 = 0
        var counter = 0
        
        for tcpInfo in tcpInfos {
            let timeInfo = tcpInfo["time"] as! TimeInterval
            if multipath {
                let mptcpInfoFd = tcpInfo["0"] as! [String: Any]
                let subflowsInfo = mptcpInfoFd["subflows"] as! [String: Any]
                for sfID in subflowsInfo.keys {
                    let subflowInfo = subflowsInfo[sfID] as! [String: Any]
                    var label = "Path \(sfID)"
                    let isWiFi = subflowInfo["tcpi_if_wifi"] as? UInt8 ?? 0
                    let isCell = subflowInfo["tcpi_if_cell"] as? UInt8 ?? 0
                    if isWiFi > 0 {
                        label += " (WiFi)"
                    }
                    if isCell > 0 {
                        label += " (Cellular)"
                    }
                    label += " Congestion Window"
                    if cwinData[label] == nil {
                        cwinData[label] = [CWinData]()
                    }
                    cwinData[label]!.append(CWinData(time: timeInfo, cwin: UInt64(subflowInfo["tcpi_snd_cwnd"] as! UInt32)))
                }
            } else {
                if cwinData["Congestion Window"] == nil {
                    cwinData["Congestion Window"] = [CWinData]()
                }
                let tcpInfoFd = tcpInfo["0"] as! [String: Any]
                cwinData["Congestion Window"]!.append(CWinData(time: timeInfo, cwin: UInt64(tcpInfoFd["tcpi_snd_cwnd"] as! UInt32)))
            }
            if timeInfo - lastInterval > (1.0 - TimeInterval(runCfg.logPeriodMsVar) / 1000.0) {
                if multipath {
                    let mptcpInfoFd = tcpInfo["0"] as! [String: Any]
                    transferredNow = mptcpInfoFd["txbytes"] as! UInt64
                    let subflowsInfo = mptcpInfoFd["subflows"] as! [String: Any]
                    retransmittedNow = 0
                    for sfID in subflowsInfo.keys {
                        let subflowInfo = subflowsInfo[sfID] as! [String: Any]
                        let retransmittedSf = subflowInfo["tcpi_txretransmitbytes"] as! UInt64
                        retransmittedNow += retransmittedSf
                    }
                } else {
                    let tcpInfoFd = tcpInfo["0"] as! [String: Any]
                    transferredNow = tcpInfoFd["tcpi_txbytes"] as! UInt64
                    retransmittedNow = tcpInfoFd["tcpi_txretransmitbytes"] as! UInt64
                }
                let nxtCounter = counter + 1
                let interval = IntervalData(interval: "\(counter)-\(nxtCounter)", transferredLastSecond: transferredNow - transferredLastSecond, globalBandwidth: transferredNow / UInt64(nxtCounter), retransmittedLastSecond: retransmittedNow - retransmittedLastSecond)
                intervals.append(interval)
                transferredLastSecond = transferredNow
                retransmittedLastSecond = retransmittedNow
                lastInterval = timeInfo
                counter += 1
            }
        }
        
        var totalRetrans: UInt64 = 0
        var totalSent: UInt64 = 0
        if tcpInfos.count > 0 {
            let tcpInfo = tcpInfos[tcpInfos.count - 1]
            if multipath {
                let mptcpInfoFd = tcpInfo["0"] as! [String: Any]
                totalSent = mptcpInfoFd["txbytes"] as! UInt64
                // FIXME no retransmission info for MPTCP so far...
            } else {
                let tcpInfoFd = tcpInfo["0"] as! [String: Any]
                totalSent = tcpInfoFd["tcpi_txbytes"] as! UInt64
                totalRetrans = tcpInfoFd["tcpi_txretransmitbytes"] as! UInt64
            }
        }
        
        var success = false
        if errorMsg == "" || errorMsg.contains("Operation timed out") {
            if intervals.count > 0 {
                success = true
            } else {
                self.errorMsg = self.errorMsg + " (could not collect metadata)"
            }
        }
        
        result = [
            "intervals": intervals,
            "tcp_infos": tcpInfos,
            "duration": String(format: "%.9f", elapsed),
            "success": success,
            "total_retrans": totalRetrans,
            "total_sent": totalSent,
            "wifi_bytes_sent": wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent,
            "wifi_bytes_received": wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived,
            "cell_bytes_sent": cellInfoEnd.bytesSent - cellInfoStart.bytesSent,
            "cell_bytes_received": cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived,
        ]
        return result
    }
}
