//
//  QUICReqResTest.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/6/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Quictraffic

class QUICReqResTest: BaseTest, Test {
    // MARK: Properties
    var maxPathID: UInt8
    
    var delays: [Int64] = []
    var missed: Int64 = 0
    
    init(ipVer: IPVersion, maxPathID: UInt8) {
        self.maxPathID = maxPathID
        
        let filePrefix = "quictraffic_reqres_" + ipVer.rawValue
        super.init(traffic: "reqres", ipVer: ipVer, port: 8080, urlPath: nil, filePrefix: filePrefix, waitTime: 3.0)
        
        // Prepare the run configuration
        runCfg.maxPathIDVar = Int(maxPathID)
        runCfg.logPeriodMsVar = 100
    }

    
    func getDescription() -> String {
        let baseConfig = getProtocol().rawValue
        switch ipVer {
        case .v4:
            return baseConfig + " IPv4 Request Response"
        case .v6:
            return baseConfig + " IPv6 Request Response"
        default:
            return baseConfig + " Request Response"
        }
    }
    
    func getConfigDict() -> [String : Any] {
        return [
            "url": getURL(),
            "port": self.port,
            "query_size": "750",
            "response_size": "750",
            "start_delay_query_response": "0",
            "nb_msgs": "35",
            "interval_time_ms": "400",
            "timeout_sec": "14",
        ]
    }
    
    override func getProtocol() -> NetProtocol {
        if maxPathID > 0 {
            return .MPQUIC
        }
        return .QUIC
    }
    
    func getTestResult() -> TestResult {
        var maxDelay = Int64(-1)
        if delays.count > 0 {
            maxDelay = delays.max()!
        }
        var resultText = errorMsg
        if success {
            resultText = "Maximum delay of " + String(maxDelay) + " ms."
        }
        return ReqResResult(name: getDescription(), proto: getProtocol(), success: success, result: resultText, duration: duration, startTime: startTime, waitTime: waitTime, wifiBytesReceived: wifiBytesReceived, wifiBytesSent: wifiBytesSent, cellBytesReceived: cellBytesReceived, cellBytesSent: cellBytesSent, multipathService: runCfg.multipathServiceVar, missed: missed, maxDelay: maxDelay, delays: delays)
    }
    
    override func run() {
        super.run()
        let reqresString = QuictrafficRun(runCfg)
        duration = startTime.timeIntervalSinceNow
        wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        
        wifiBytesSent = wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent
        wifiBytesReceived = wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived
        cellBytesSent = cellInfoEnd.bytesSent - cellInfoStart.bytesSent
        cellBytesReceived = cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived
        
        let lines = reqresString!.components(separatedBy: .newlines)
        if lines[0] != "Exiting client main with error deadline exceeded" && lines[0] != "Exiting client main with error nil" {
            // An error occured...
            errorMsg = lines[0]
            missed = 35
            
            return
        }
        for i in 2..<lines.count-1 {
            delays.append(Int64(lines[i])!)
        }
        missed = Int64(35 - delays.count)
        success = true
    }
}
