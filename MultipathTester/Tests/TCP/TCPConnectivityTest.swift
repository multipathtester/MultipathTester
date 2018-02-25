//
//  TCPConnectivityTest.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 2/24/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import NetworkExtension

class TCPConnectivityTest: BaseConnectivityTest {
    convenience init(ipVer: IPVersion, port: UInt16, testServer: TestServer, pingCount: Int, pingWaitMs: Int) {
        let filePrefix = "quictraffic_connectivity_" + String(port) + "_" + ipVer.rawValue
        self.init(ipVer: ipVer, port: port, testServer: testServer, pingCount: pingCount, pingWaitMs: pingWaitMs, filePrefix: filePrefix)
    }
    
    override func getProtocol() -> NetProtocol {
        return .TCP
    }
    
    func performRequest(session: URLSession, count: Int) -> Bool {
        let group = DispatchGroup()
        // FIXME
        let url = URL(string: "https://mptcp4.qdeconinck.be:443/" + self.urlPath)!
        group.enter()
        let start = DispatchTime.now()
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
            let responseString = String(data: data!, encoding: .utf8)
            print(responseString)
            let length = CGFloat((resp?.expectedContentLength)!) / 1000000.0
            let elapsed = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
            let timeInterval = Double(elapsed) / 1_000_000
            if count > 0 {
                self.durations.append(timeInterval)
            }
            
            print("\(timeInterval)ms for \(length) MB")
            group.leave()
        }
        task.resume()
        group.wait()
        
        // Did we got an error?
        if self.errorMsg != nil {
            return false
        }
        
        // Did we obtained the right number of pings?
        if count >= self.pingCount {
            return true
        }
        // Otherwise, wait a little before repinging
        usleep(UInt32(self.pingWaitMs) * 1000)
        return performRequest(session: session, count: count+1)
    }
    
    override func run() -> [String:Any] {
        _ = super.run()
        var success = false

        let config = URLSessionConfiguration.ephemeral
        if true {
            config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.handover
        }
        
        let session = URLSession(configuration: config)
        
        let group = DispatchGroup()
        let subgroup = DispatchGroup()
        group.enter()
        subgroup.enter()
        
        DispatchQueue.global(qos: .userInteractive).async {
            success = self.performRequest(session: session, count: 0)
            group.leave()
        }
        
        group.wait()
        print(durations)
        
        let elapsed = Date().timeIntervalSince(startTime)
        wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        
        result = [
            "duration": elapsed,
            "durations":durations,
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
