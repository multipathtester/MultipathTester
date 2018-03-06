//
//  TCPStreamTest.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 2/25/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class TCPStreamTest: BaseStreamTest {
    var delaysMutex = pthread_mutex_t()
    var multipath: Bool
    var upDelays = [DelayData]()
    var downDelays = [DelayData]()
    var endTime = Date()
    var nxtAckMsgID: UInt32 = 0
    var nxtMessageID: UInt32 = 0
    var sentTimes: [Int: Date] = [:]
    var stop = false
    
    init(ipVer: IPVersion, runTime: Int, waitTime: Double, multipath: Bool) {
        self.multipath = multipath
        let filePrefix = "mptcp_stream_" + ipVer.rawValue
        
        super.init(ipVer: ipVer, runTime: runTime, waitTime: waitTime, filePrefix: filePrefix)
        
        // Prepare the run configuration
        runCfg.logPeriodMsVar = 100
    }
    
    convenience init(ipVer: IPVersion, runTime: Int, multipath: Bool) {
        self.init(ipVer: ipVer, runTime: runTime, waitTime: 3.0, multipath: multipath)
    }
    
    override func getProtocol() -> NetProtocol {
        if multipath {
            return .MPTCP
        }
        return .TCP
    }
    
    func setupDownConnection(session: URLSession) -> (URLSessionStreamTask, UInt64, Bool) {
        let group = DispatchGroup()
        group.enter()
        var ok = false
        let downConn = session.streamTask(withHostName: self.getTestServerHostname(), port: Int(self.port))
        downConn.resume()
        let connID: UInt64 = UInt64(arc4random_uniform(UInt32.max)) * (UInt64(UInt32.max) + 1) + UInt64(arc4random_uniform(UInt32.max))
        let runTimeNs = UInt64(self.runCfg.runTimeVar * 1_000_000_000)
        // [Length(4)|'S'(1)|connID(8)|runTimeNs(8)|uploadChunkSize(4)|downloadChunkSize(4)|downloadIntervalTimeNs(8)]
        let data = NSMutableData()
        Binary.putUInt32(33, to: data)
        Binary.putUInt8(83, to: data) // 'S'
        Binary.putUInt64(connID, to: data)
        Binary.putUInt64(runTimeNs, to: data)
        Binary.putUInt32(self.uploadChunkSize, to: data)
        Binary.putUInt32(self.downloadChunkSize, to: data)
        Binary.putUInt64(self.downloadIntervalTimeCst, to: data)
        
        downConn.write(data as Data, timeout: 10.0, completionHandler: { (error) in
            if let err = error {
                print("An write error occurred", err)
            }
        })
        downConn.readData(ofMinLength: 9, maxLength: 9, timeout: 10.0) { (data, atEOF, error) in
            defer { group.leave() }
            guard error == nil && data != nil else {
                //self.errorMsg = "\(String(describing: error))"
                print("\(String(describing: error))")
                return
            }
            // [Length(4)|'A'(1)|msgID(4)]
            let bytes = [UInt8](data!)
            let ackLen = Binary.getUInt32(bytes: bytes, startIndex: 0)
            guard ackLen == 5 else {
                print("Unexpected ackLen", ackLen)
                return
            }
            guard bytes[4] == 65 else { // 'A'
                print("Unexpected prefix", bytes[4])
                return
            }
            let msgID = Binary.getUInt32(bytes: bytes, startIndex: 5)
            guard msgID == 0 else {
                print("Unexpected msgID", msgID)
                return
            }

            ok = true
        }
        group.wait()
        return (downConn, connID, ok)
    }
    
    func setupUpConnection(session: URLSession, connID: UInt64) -> (URLSessionStreamTask, Bool) {
        let group = DispatchGroup()
        group.enter()
        var ok = false
        let upConn = session.streamTask(withHostName: self.getTestServerHostname(), port: Int(self.port))
        upConn.resume()
        // [Length(4)|'U'(1)|connID(8)]
        let data = NSMutableData()
        Binary.putUInt32(9, to: data)
        Binary.putUInt8(85, to: data) // 'U'
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
    
    func sendData(tcpConn: URLSessionStreamTask) -> Bool {
        // [Length(4)|'D'(1)|msgID(4)|padding]
        let data = NSMutableData()
        Binary.putUInt32(uploadChunkSize-4, to: data)
        Binary.putUInt8(68, to: data) // 'D'
        Binary.putUInt32(nxtMessageID, to: data)
        // Padding
        for _ in 9..<uploadChunkSize {
            Binary.putUInt8(0, to: data)
        }
        let sentTime = Date()
        tcpConn.resume()
        tcpConn.write(data as Data, timeout: endTime.timeIntervalSinceNow) { (error) in
            //print("sent up")
            if error != nil {
                self.errorMsg = error.debugDescription
            }
        }
        pthread_mutex_lock(&delaysMutex)
        sentTimes[Int(nxtMessageID)] = sentTime
        pthread_mutex_unlock(&delaysMutex)
        nxtMessageID += 1
        return true
    }
    
    func clientSenderUp(tcpConn: URLSessionStreamTask) {
        while Date().compare(endTime) == .orderedAscending && !stop {
            if !sendData(tcpConn: tcpConn) {
                //break
            }
            usleep(useconds_t(uploadIntervalTimeCst / 1_000)) // ns to us
        }
        tcpConn.cancel()
    }
    
    func checkFormatServerAck(bytes: [UInt8]) -> (UInt32, Bool) {
        // [Length(4)|'A'(1)|ackMsgID(4)]
        let ackLen = Binary.getUInt32(bytes: bytes, startIndex: 0)
        guard ackLen == 5 else {
            print("Unexpected ackLen", ackLen)
            return (0, false)
        }
        guard bytes[4] == 65 else { // 'A'
            print("Unexpected prefix", bytes[4])
            return (0, false)
        }
        let ackMsgID = Binary.getUInt32(bytes: bytes, startIndex: 5)
        guard ackMsgID == nxtAckMsgID else {
            print("Wrong ack num: \(ackMsgID) but expects \(nxtAckMsgID)")
            self.errorMsg = "Wrong ack num: \(ackMsgID) but expects \(nxtAckMsgID)"
            return (ackMsgID, false)
        }
        
        return (ackMsgID, true)
    }
    
    func clientReceiverUp(tcpConn: URLSessionStreamTask) {
        // 0 has been done previously
        nxtAckMsgID = 1
        while Date().compare(endTime) == .orderedAscending && !stop {
            let group = DispatchGroup()
            group.enter()
            tcpConn.resume()
            tcpConn.readData(ofMinLength: 9, maxLength: 9, timeout: endTime.timeIntervalSinceNow, completionHandler: { (data, isEOF, error) in
                defer { group.leave() }
                let rcvTime = Date()
                //print("read sth up")
                if isEOF {
                    print("is EOF")
                    self.stop = true
                    return
                }
                if error != nil || data == nil {
                    if let err = error {
                        print(err)
                        self.errorMsg = err.localizedDescription
                    } else {
                        print("no data")
                        self.errorMsg = "no data"
                    }
                    self.stop = true
                    return
                }
                let bytes = [UInt8](data!)
                let (ackMsgID, ok) = self.checkFormatServerAck(bytes: bytes)
                if !ok {
                    print("wrong format server ack")
                    self.stop = true
                    self.errorMsg = "Invalid format of ack from server in up stream"
                    return
                }
                let ackedMsgID = ackMsgID - 1
                pthread_mutex_lock(&self.delaysMutex)
                let sentTimeAny = self.sentTimes[Int(ackedMsgID)]
                guard let sentTime = sentTimeAny else { pthread_mutex_unlock(&self.delaysMutex) ; return }
                let delayData = DelayData(time: Date().timeIntervalSince1970, delayUs: UInt64(rcvTime.timeIntervalSince(sentTime) * 1_000_000))
                self.upDelays.append(delayData)
                self.sentTimes.removeValue(forKey: Int(ackedMsgID))
                pthread_mutex_unlock(&self.delaysMutex)
                self.nxtAckMsgID += 1
            })
            group.wait()
        }
        print("Out of up receiver loop because \(self.errorMsg)")
        stop = true
        tcpConn.cancel()
    }
    
    func checkFormatServerData(bytes: [UInt8]) -> (UInt32, Bool) {
        // [Length(4)|'D'(1)|msgID(4)|NumDelays(4)|{list of previous delays (8)}|padding]
        let dataLen = Binary.getUInt32(bytes: bytes, startIndex: 0)
        guard dataLen == downloadChunkSize-4 else { return (0, false) }
        guard bytes[4] == 68 /* 'D' */ else { return (0, false) }
        let msgID = Binary.getUInt32(bytes: bytes, startIndex: 5)
        
        return (msgID, true)
    }
    
    func sendAck(tcpConn: URLSessionStreamTask, msgID: UInt32) -> Bool {
        // [Length(4)|'A'(1)|msgID(4)]
        let data = NSMutableData()
        Binary.putUInt32(5, to: data)
        Binary.putUInt8(65, to: data) // 'A'
        Binary.putUInt32(msgID+1, to: data)
        tcpConn.resume()
        tcpConn.write(data as Data, timeout: endTime.timeIntervalSinceNow, completionHandler: { (error) in
            if error != nil {
                self.errorMsg = error.debugDescription
            }
        })
        return true
    }
    
    override func run() -> [String:Any] {
        _ = super.run()
        var success = false

        let config = URLSessionConfiguration.ephemeral
        if multipath {
            if runCfg.multipathServiceVar == .handover {
                config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.interactive
            }
            if runCfg.multipathServiceVar == .aggregate {
                config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.aggregate
            }
        }
        
        let session = URLSession(configuration: config)
        let group = DispatchGroup()
        group.enter()
        
        DispatchQueue.global(qos: .userInteractive).async {
            defer { group.leave() }
            let (downConn, connID, okDown) = self.setupDownConnection(session: session)
            guard okDown else { return }
            let (upConn, okUp) = self.setupUpConnection(session: session, connID: connID)
            guard okUp else { return }
            self.endTime = Date().addingTimeInterval(TimeInterval(self.runCfg.runTimeVar))
            print(self.endTime.timeIntervalSinceNow)
            let queue = OperationQueue()
            queue.addOperation {
                self.clientSenderUp(tcpConn: upConn)
            }
            queue.addOperation {
                self.clientReceiverUp(tcpConn: upConn)
            }
            while Date().compare(self.endTime) == .orderedAscending && !self.stop {
                // Important to avoid overloading read calls
                let group2 = DispatchGroup()
                group2.enter()
                downConn.resume()
                downConn.readData(ofMinLength: Int(self.downloadChunkSize), maxLength: Int(self.downloadChunkSize), timeout: self.endTime.timeIntervalSinceNow, completionHandler: { (data, isEOF, error) in
                    defer { group2.leave() }
                    if isEOF {
                        self.errorMsg = "Got EOF"
                        self.stop = true
                        return
                    }
                    if error != nil || data == nil {
                        self.errorMsg = error.debugDescription
                        self.stop = true
                        return
                    }
                    let bytes = [UInt8](data!)
                    let (msgID, ok) = self.checkFormatServerData(bytes: bytes)
                    if !ok {
                        self.errorMsg = "Unexpected format of data packet from server"
                        self.stop = true
                        return
                    }
                    if !self.sendAck(tcpConn: downConn, msgID: msgID) {
                        self.errorMsg = "Error when sending ack"
                        self.stop = true
                        return
                    }
                    pthread_mutex_lock(&self.delaysMutex)
                    let numDelays = Binary.getUInt32(bytes: bytes, startIndex: 9)
                    for i in 0..<Int(numDelays) {
                        let startIndex = 13 + 8 * i
                        let delayNs = Binary.getUInt64(bytes: bytes, startIndex: startIndex)
                        let delayData = DelayData(time: Date().timeIntervalSince1970, delayUs: delayNs / 1_000) // from ns to us
                        self.downDelays.append(delayData)
                    }
                    pthread_mutex_unlock(&self.delaysMutex)
                })
                group2.wait()
            }
            self.stop = true
            downConn.cancel()
        }

        var res: DispatchTimeoutResult = .timedOut
        let ips = ipsOf(hostname: getTestServerHostname())
        var fd1 = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), startAt: 0)
        if (fd1 < 0) {
            while (res == .timedOut && fd1 < 0) {
                res = group.wait(timeout: DispatchTime.now() + 0.01)
                //print("We missed it once, try again...")
                // Retry, we might have missed the good one thinking it's and old one
                fd1 = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), startAt: 0)
            }
        }
        print("FD1 is \(fd1)")
        
        var fd2 = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), startAt: fd1 + 1)
        if (fd2 < 0) {
            while (res == .timedOut && fd2 < 0) {
                res = group.wait(timeout: DispatchTime.now() + 0.01)
                //print("We missed it once, try again...")
                // Retry, we might have missed the good one thinking it's and old one
                fd2 = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), startAt: fd1 + 1)
            }
        }
        print("FD2 is \(fd2)")
        
        // This will perform the wait on the group; once this call returns, the traffic is over
        var tcpInfos = [[String: Any]]()
        if fd1 > 0 && fd2 > 0 {
            tcpInfos = TCPLogger.logTCPInfosMain(group: group, fds: [fd1, fd2], multipath: multipath, logPeriodMs: runCfg.logPeriodMsVar)
        }
        let elapsed = Date().timeIntervalSince(startTime)
        wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        print(upDelays)
        print(downDelays)
        print(errorMsg)
        if errorMsg.contains("Operation timed out") {
            success = true
        }
        
        result = [
            "tcp_infos": tcpInfos,
            "duration": String(format: "%.9f", elapsed),
            "error_msg": errorMsg,
            "down_delays": downDelays,
            "up_delays": upDelays,
            "success": success,
            "wifi_bytes_sent": wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent,
            "wifi_bytes_received": wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived,
            "cell_bytes_sent": cellInfoEnd.bytesSent - cellInfoStart.bytesSent,
            "cell_bytes_received": cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived,
        ]
        return result
    }
}
