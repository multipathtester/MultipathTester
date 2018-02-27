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
    var nxtAckMsgID = 0
    var nxtMessageID = 0
    var sentTimes: [Int: Date] = [:]
    
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
    
    // REMOVE ME
    override func getTestServerHostname() -> String {
        return "mptcp4.qdeconinck.be"
    }
    
    func setupDownConnection(session: URLSession) -> (URLSessionStreamTask, UInt64, Bool) {
        let group = DispatchGroup()
        group.enter()
        var ok = false
        let downConn = session.streamTask(withHostName: self.getTestServerHostname(), port: Int(self.port))
        downConn.resume()
        let connID: UInt64 = UInt64(arc4random_uniform(UInt32.max)) * (UInt64(UInt32.max) + 1) + UInt64(arc4random_uniform(UInt32.max))
        let runTimeNs = self.runCfg.runTimeVar * 1_000_000_000
        let msg = "S&" + String(connID) + "&" + String(self.maxIDCst) + "&" + String(self.ackSize) + "&" + String(runTimeNs) + "&" + String(self.uploadChunkSize) + "&" + String(self.downloadChunkSize) + "&" + String(self.downloadIntervalTimeCst)
        downConn.write(msg.data(using: .utf8)!, timeout: 10.0, completionHandler: { (error) in
            if error != nil {
                print("An write error occurred", error)
            }
        })
        downConn.readData(ofMinLength: 3, maxLength: 3, timeout: 10.0) { (data, atEOF, error) in
            guard error == nil && data != nil else {
                //self.errorMsg = "\(String(describing: error))"
                print("\(String(describing: error))")
                group.leave()
                return
            }
            let responseStringRaw = String(data: data!, encoding: .utf8)
            guard let responseString = responseStringRaw else {
                print("Cannot decode string response")
                group.leave()
                return
            }
            if responseString != "A&0" {
                print("Unexpected response", responseString)
                group.leave()
                return
            }
            print(responseString)
            ok = true
            group.leave()
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
        let msg = "U&" + String(connID)
        upConn.write(msg.data(using: .utf8)!, timeout: 10.0, completionHandler: { (error) in
            if error != nil {
                print("An write error occurred", error)
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
        let startString = "D&\(nxtMessageID)&\(uploadChunkSize)&"
        let msg = startString + String(repeating: "0", count: uploadChunkSize-startString.count)
        let sentTime = Date()
        tcpConn.resume()
        tcpConn.write(msg.data(using: .utf8)!, timeout: endTime.timeIntervalSinceNow) { (error) in
            print("sent up")
            if error != nil {
                self.errorMsg = error.debugDescription
            }
        }
        pthread_mutex_lock(&delaysMutex)
        sentTimes[nxtMessageID] = sentTime
        pthread_mutex_unlock(&delaysMutex)
        nxtMessageID = (nxtMessageID + 1) % maxIDCst
        return true
    }
    
    func clientSenderUp(tcpConn: URLSessionStreamTask) {
        var stop = false
        while Date().compare(endTime) == .orderedAscending && !stop {
            if !sendData(tcpConn: tcpConn) {
                //break
            }
            usleep(useconds_t(uploadIntervalTimeCst / 1_000)) // ns to us
        }
        tcpConn.cancel()
    }
    
    func checkFormatServerAck(splitMsg: [String]) -> Bool {
        if splitMsg.count != 2 {
            print("Wrong size: \(splitMsg.count)")
            self.errorMsg = "Wrong size: \(splitMsg.count)"
            return false
        }
        if splitMsg[0] != "A" {
            print("Wrong prefix: \(splitMsg[0])")
            self.errorMsg = "Wrong prefix: \(splitMsg[0])"
            return false
        }
        let ackMsgIDAny = Int(splitMsg[1])
        guard let ackMsgID = ackMsgIDAny else { return false }
        if ackMsgID != nxtAckMsgID {
            print("Wrong ack num: \(ackMsgID) but expects \(nxtAckMsgID)")
            self.errorMsg = "Wrong ack num: \(ackMsgID) but expects \(nxtAckMsgID)"
            return false
        }
        
        return true
    }
    
    func clientReceiverUp(tcpConn: URLSessionStreamTask) {
        // 0 has been done previously
        nxtAckMsgID = 1
        var stop = false
        while Date().compare(endTime) == .orderedAscending && !stop {
            let group = DispatchGroup()
            group.enter()
            tcpConn.resume()
            tcpConn.readData(ofMinLength: ackSize, maxLength: ackSize, timeout: endTime.timeIntervalSinceNow, completionHandler: { (data, isEOF, error) in
                defer { group.leave() }
                let rcvTime = Date()
                print("read sth up")
                if isEOF {
                    print("is EOF")
                    stop = true
                    return
                }
                if error != nil || data == nil {
                    print(error)
                    stop = true
                    self.errorMsg = error.debugDescription
                    return
                }
                let responseStringRaw = String(data: data!, encoding: .utf8)
                guard let responseString = responseStringRaw else { return }
                print(responseString)
                let splitResponse = responseString.components(separatedBy: "&")
                if !self.checkFormatServerAck(splitMsg: splitResponse) {
                    print("wrong format server ack")
                    stop = true
                    self.errorMsg = "Invalid format of ack from server in up stream"
                    return
                }
                let ackMsgID = Int(splitResponse[1])!
                let ackedMsgID = ackMsgID - 1
                pthread_mutex_lock(&self.delaysMutex)
                let sentTimeAny = self.sentTimes[ackedMsgID]
                guard let sentTime = sentTimeAny else { pthread_mutex_unlock(&self.delaysMutex) ; return }
                let delayData = DelayData(time: Date().timeIntervalSince1970, delayUs: UInt64(rcvTime.timeIntervalSince(sentTime) * 1_000_000))
                self.upDelays.append(delayData)
                self.sentTimes.removeValue(forKey: ackedMsgID)
                pthread_mutex_unlock(&self.delaysMutex)
                self.nxtAckMsgID = (self.nxtAckMsgID + 1) % self.maxIDCst
            })
            group.wait()
        }
        print("Out of up receiver loop because \(self.errorMsg)")
        tcpConn.cancel()
    }
    
    func checkFormatServerData(msg: String, splitMsg: [String]) -> Bool {
        //D&{ID}&{SIZE}&{list of previous delays ended by &}{padding}
        if splitMsg.count < 4 {
            return false
        }
        if splitMsg[0] != "D" {
            return false
        }
        let msgIDAny = Int(splitMsg[1])
        guard let msgID = msgIDAny else { return false }
        if msgID < 0 || msgID >= maxIDCst {
            return false
        }
        let sizeAny = Int(splitMsg[2])
        guard let size = sizeAny else { return false }
        if size != self.downloadChunkSize {
            return false
        }
        
        return true
    }
    
    func sendAck(tcpConn: URLSessionStreamTask, msgID: Int) -> Bool {
        let msgIDStr = String(format: "%d", msgID + 1)
        let msg = "A&" + String(repeating: "0", count: self.ackSize - 2 - msgIDStr.count) + msgIDStr
        tcpConn.resume()
        tcpConn.write(msg.data(using: .utf8)!, timeout: endTime.timeIntervalSinceNow, completionHandler: { (error) in
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
        // TODO Multipath service
        config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.interactive
        
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
            while Date().compare(self.endTime) == .orderedAscending {
                // Important to avoid overloading read calls
                let group2 = DispatchGroup()
                group2.enter()
                downConn.resume()
                downConn.readData(ofMinLength: self.downloadChunkSize, maxLength: self.downloadChunkSize, timeout: self.endTime.timeIntervalSinceNow, completionHandler: { (data, isEOF, error) in
                    defer { group2.leave() }
                    if isEOF {
                        success = true
                        return
                    }
                    if error != nil || data == nil {
                        self.errorMsg = error.debugDescription
                        return
                    }
                    let responseStringRaw = String(data: data!, encoding: .utf8)
                    guard let responseString = responseStringRaw else {
                        print("Cannot decode string response")
                        return
                    }
                    let splitResponse = responseString.components(separatedBy: "&")
                    if !self.checkFormatServerData(msg: responseString, splitMsg: splitResponse) {
                        self.errorMsg = "Unexpected format of data packet from server"
                        return
                    }
                    let msgID = Int(splitResponse[1])!
                    if !self.sendAck(tcpConn: downConn, msgID: msgID) {
                        self.errorMsg = "Error when sending ack"
                        return
                    }
                    pthread_mutex_lock(&self.delaysMutex)
                    for i in 3..<splitResponse.count-1 {
                        let durUIntAny = UInt64(splitResponse[i])
                        guard let durUInt = durUIntAny else {
                            pthread_mutex_unlock(&self.delaysMutex)
                            self.errorMsg = "Unparseable delay from server"
                            return
                        }
                        let delayData = DelayData(time: Date().timeIntervalSince1970, delayUs: durUInt / 1_000) // from ns to us
                        self.downDelays.append(delayData)
                    }
                    pthread_mutex_unlock(&self.delaysMutex)
                })
                group2.wait()
            }
            downConn.cancel()
        }
        group.wait()
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
