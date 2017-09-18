//
//  TCPClientReqRes.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 9/13/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class TCPClientReqRes {
    let intervalTimeMs = 400
    let maxID = 100
    let querySize = 750
    let resSize = 750
    let runTimeMs = 30000
    
    var delays: [UInt64]
    var messageID: Int
    var missed: Int
    var multipath: Bool
    var sentTime: [Int: DispatchTime]
    var startTime: DispatchTime
    var url: URL
    
    init(multipath: Bool, url: String) {
        self.delays = []
        self.messageID = 0
        self.missed = 0
        self.multipath = multipath
        self.sentTime = [:]
        self.startTime = DispatchTime.now()
        self.url = (URL(string: url))!
    }
    
    func Run() -> (Double, Int, [UInt64]) {
        let config = URLSessionConfiguration.default
        config.httpShouldUsePipelining = true
        if multipath {
            config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.aggregate
        }
        let session = URLSession(configuration: config)
        
        startTime = DispatchTime.now()
     
        repeat {
            sendRequest(session: session)
            usleep(UInt32(intervalTimeMs * 1000))
        } while ((DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000 < (runTimeMs))
        
        session.finishTasksAndInvalidate()
        return (Double(runTimeMs) / 1000, missed, delays)
    }
    
    // MARK: Private methods
    private func sendRequest(session: URLSession) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let requestStartString = "\(messageID)&\(querySize)&\(resSize)&0&"
        let sentMessageID = messageID
        messageID = (messageID + 1) % maxID
        let requestString = requestStartString + String(repeating: "0", count: querySize - requestStartString.count)
        request.httpBody = requestString.data(using: .utf8)
        let sentTimeData = DispatchTime.now()
        let task = session.dataTask(with: request) { data, response, error in
            let responseTime = DispatchTime.now()
            guard let data = data, error == nil else {
                print("error = \(String(describing: error))")
                self.missed += 1
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            let responseArray = responseString?.components(separatedBy: "&")
            let rcvMessageID = Int(responseArray![0])!
            let requestTime = self.sentTime[rcvMessageID]
            
            // Remove previous value in case of messageID reuse
            self.sentTime[rcvMessageID] = nil
            
            let elapsedTimeMs = (responseTime.uptimeNanoseconds - requestTime!.uptimeNanoseconds) / 1_000_000
            self.delays.append(elapsedTimeMs)
            print("rcvMessageID = \(rcvMessageID) elapsedTimeMs = \(elapsedTimeMs)")
        }
        task.resume()
        sentTime[sentMessageID] = sentTimeData
    }
}
