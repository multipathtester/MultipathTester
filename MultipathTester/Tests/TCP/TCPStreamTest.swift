//
//  TCPStreamTest.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 2/25/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Charts

class TCPStreamTest: BaseStreamTest {
    var delaysMutex = pthread_mutex_t()
    var connsMutex = pthread_mutex_t()
    var multipath: Bool
    var upNewDelays = [DelayData]()
    var downNewDelays = [DelayData]()
    var endTime = Date()
    var nxtAckMsgID: UInt32 = 0
    var nxtMessageID: UInt32 = 0
    var sentTimes: [Int: Date] = [:]
    var stop = AtomicBoolean() // This is initially set to false
    
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
        let timeout = self.endTime == self.startTime ? 0 : self.endTime.timeIntervalSinceNow
        let sentTime = Date()
        pthread_mutex_lock(&connsMutex)
        if tcpConn.state == .running || tcpConn.state == .suspended {
            tcpConn.resume()
            tcpConn.write(data as Data, timeout: timeout) { (error) in
                //print("sent up")
                if error != nil {
                    self.errorMsg = error.debugDescription
                }
            }
        }
        pthread_mutex_unlock(&connsMutex)
        pthread_mutex_lock(&delaysMutex)
        sentTimes[Int(nxtMessageID)] = sentTime
        pthread_mutex_unlock(&delaysMutex)
        nxtMessageID += 1
        return true
    }
    
    func clientSenderUp(tcpConn: URLSessionStreamTask) {
        while (self.startTime == self.endTime || Date().compare(endTime) == .orderedAscending) && !stop.val {
            if !sendData(tcpConn: tcpConn) {
                //break
            }
            usleep(useconds_t(uploadIntervalTimeCst / 1_000)) // ns to us
        }
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
        while (self.startTime == self.endTime || Date().compare(endTime) == .orderedAscending) && !stop.val {
            let group = DispatchGroup()
            group.enter()
            let timeout = self.endTime == self.startTime ? 0 : self.endTime.timeIntervalSinceNow
            pthread_mutex_lock(&self.connsMutex)
            if tcpConn.state == .running || tcpConn.state == .suspended {
                tcpConn.resume()
                tcpConn.readData(ofMinLength: 9, maxLength: 9, timeout: timeout, completionHandler: { (data, isEOF, error) in
                    defer { group.leave() }
                    let rcvTime = Date()
                    //print("read sth up")
                    if isEOF {
                        print("is EOF")
                        self.stop.val = true
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
                        self.stop.val = true
                        return
                    }
                    let bytes = [UInt8](data!)
                    let (ackMsgID, ok) = self.checkFormatServerAck(bytes: bytes)
                    if !ok {
                        print("wrong format server ack")
                        self.stop.val = true
                        self.errorMsg = "Invalid format of ack from server in up stream"
                        return
                    }
                    let ackedMsgID = ackMsgID - 1
                    pthread_mutex_lock(&self.delaysMutex)
                    let sentTimeAny = self.sentTimes[Int(ackedMsgID)]
                    guard let sentTime = sentTimeAny else { pthread_mutex_unlock(&self.delaysMutex) ; return }
                    let delayData = DelayData(time: Date().timeIntervalSince1970, delayUs: UInt64(rcvTime.timeIntervalSince(sentTime) * 1_000_000))
                    self.upDelays.append(delayData)
                    self.upNewDelays.append(delayData)
                    self.sentTimes.removeValue(forKey: Int(ackedMsgID))
                    pthread_mutex_unlock(&self.delaysMutex)
                    self.nxtAckMsgID += 1
                })
            }
            pthread_mutex_unlock(&self.connsMutex)
            group.wait()
        }
        print("Out of up receiver loop because \(self.errorMsg)")
        stop.val = true
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
        let timeout = self.endTime == self.startTime ? 0 : self.endTime.timeIntervalSinceNow
        pthread_mutex_lock(&self.connsMutex)
        if tcpConn.state == .running || tcpConn.state == .suspended {
            tcpConn.resume()
            tcpConn.write(data as Data, timeout: timeout, completionHandler: { (error) in
                if error != nil {
                    self.errorMsg = error.debugDescription
                }
            })
        }
        pthread_mutex_unlock(&self.connsMutex)
        return true
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
        
        DispatchQueue.global(qos: .userInteractive).async {
            defer { group.leave() }
            let (downConn, connID, okDown) = self.setupDownConnection(session: session)
            guard okDown else { self.errorMsg = "Failed to create connection"; return }
            let (upConn, okUp) = self.setupUpConnection(session: session, connID: connID)
            guard okUp else { self.errorMsg = "Failed to create connection"; return }
            if self.runCfg.runTimeVar > 0 {
                self.endTime = Date().addingTimeInterval(TimeInterval(self.runCfg.runTimeVar))
            } else {
                self.endTime = self.startTime
            }
            
            print(self.endTime.timeIntervalSinceNow)
            let queue = OperationQueue()
            queue.addOperation {
                self.clientSenderUp(tcpConn: upConn)
            }
            queue.addOperation {
                self.clientReceiverUp(tcpConn: upConn)
            }
            while (self.startTime == self.endTime || Date().compare(self.endTime) == .orderedAscending) && !self.stop.val {
                // Important to avoid overloading read calls
                let group2 = DispatchGroup()
                group2.enter()
                let timeout = self.endTime == self.startTime ? 0 : self.endTime.timeIntervalSinceNow
                pthread_mutex_lock(&self.connsMutex)
                if downConn.state == .running || downConn.state == .suspended {
                    downConn.resume()
                    downConn.readData(ofMinLength: Int(self.downloadChunkSize), maxLength: Int(self.downloadChunkSize), timeout: timeout, completionHandler: { (data, isEOF, error) in
                        defer { group2.leave() }
                        if isEOF {
                            self.errorMsg = "Got EOF"
                            self.stop.val = true
                            return
                        }
                        if error != nil || data == nil {
                            self.errorMsg = error.debugDescription
                            self.stop.val = true
                            return
                        }
                        let bytes = [UInt8](data!)
                        let (msgID, ok) = self.checkFormatServerData(bytes: bytes)
                        if !ok {
                            self.errorMsg = "Unexpected format of data packet from server"
                            self.stop.val = true
                            return
                        }
                        if !self.sendAck(tcpConn: downConn, msgID: msgID) {
                            self.errorMsg = "Error when sending ack"
                            self.stop.val = true
                            return
                        }
                        pthread_mutex_lock(&self.delaysMutex)
                        let numDelays = Binary.getUInt32(bytes: bytes, startIndex: 9)
                        for i in 0..<Int(numDelays) {
                            let startIndex = 13 + 8 * i
                            let delayNs = Binary.getUInt64(bytes: bytes, startIndex: startIndex)
                            let delayData = DelayData(time: Date().timeIntervalSince1970, delayUs: delayNs / 1_000) // from ns to us
                            self.downDelays.append(delayData)
                            self.downNewDelays.append(delayData)
                        }
                        pthread_mutex_unlock(&self.delaysMutex)
                    })
                }
                pthread_mutex_unlock(&self.connsMutex)
                group2.wait()
            }
            print("I'm out of down receiver")
            self.stop.val = true
        }

        var res: DispatchTimeoutResult = .timedOut
        let ips = ipsOf(hostname: getTestServerHostname())
        var fd1 = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), exclude: -1)
        if (fd1 < 0) {
            while (res == .timedOut && fd1 < 0) {
                res = group.wait(timeout: DispatchTime.now() + 0.01)
                //print("We missed it once, try again...")
                // Retry, we might have missed the good one thinking it's and old one
                fd1 = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), exclude: -1)
            }
        }
        print("FD1 is \(fd1)")
        
        var fd2 = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), exclude: fd1)
        if (fd2 < 0) {
            while (res == .timedOut && fd2 < 0) {
                res = group.wait(timeout: DispatchTime.now() + 0.01)
                //print("We missed it once, try again...")
                // Retry, we might have missed the good one thinking it's and old one
                fd2 = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), exclude: fd1)
            }
        }
        print("FD2 is \(fd2)")
        
        // This will perform the wait on the group; once this call returns, the traffic is over
        if fd1 > 0 && fd2 > 0 {
            tcpInfos = TCPLogger.logTCPInfosMain(group: group, fds: [fd1, fd2], multipath: multipath, logPeriodMs: runCfg.logPeriodMsVar, test: self)
        }
        duration = Date().timeIntervalSince(startTime)
        wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        
        wifiBytesSent = wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent
        wifiBytesReceived = wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived
        cellBytesSent = cellInfoEnd.bytesSent - cellInfoStart.bytesSent
        cellBytesReceived = cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived
        
        print(errorMsg)
        if errorMsg == "" || errorMsg == "Got EOF" || errorMsg.contains("Operation timed out") {
            success = true
        }
    }
    
    // MARK: Specific to that test
    override func getProgressDelays() -> ([DelayData], [DelayData]) {
        pthread_mutex_lock(&self.delaysMutex)
        let returnUp = upNewDelays
        let returnDown = downNewDelays
        upNewDelays = [DelayData]()
        downNewDelays = [DelayData]()
        pthread_mutex_unlock(&self.delaysMutex)
        return (returnUp, returnDown)
    }
    
    override func getChartData() -> ChartEntries? {
        let upValues = upDelays.map { (d) -> ChartDataEntry in
            return ChartDataEntry(x: d.time, y: Double(d.delayUs) / 1000.0)
        }
        let downValues = downDelays.map { (d) -> ChartDataEntry in
            return ChartDataEntry(x: d.time, y: Double(d.delayUs) / 1000.0)
        }
        return MultiLineChartEntries(xLabel: "Time", yLabel: "Delay", dataLines: [
            "Upload delays (ms)": upValues,
            "Download delays (ms)": downValues,
        ])
    }
    
    override func stopTraffic() {
        print("I call stop")
        stop.val = true
    }
}
