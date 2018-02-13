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
    
    func getProtocol() -> NetProtocol {
        if maxPathID > 0 {
            return .MPQUIC
        }
        return .QUIC
    }
    
    func getTestResult() -> TestResult {
        let delays = result["delays"] as! [Int64]
        var maxDelay = Int64(-1)
        if delays.count > 0 {
            maxDelay = delays.max()!
        }
        let duration = Double(result["duration"] as! String)!
        let missed = result["missed"] as! Int64
        let success = result["success"] as! Bool
        var resultText = ""
        if success {
            resultText = "Maximum delay of " + String(maxDelay) + " ms."
        } else {
            resultText = result["error_msg"] as! String
        }
        let wifiBytesSent = result["wifi_bytes_sent"] as! UInt32
        let wifiBytesReceived = result["wifi_bytes_received"] as! UInt32
        let cellBytesSent = result["cell_bytes_sent"] as! UInt32
        let cellBytesReceived = result["cell_bytes_received"] as! UInt32
        return ReqResResult(name: getDescription(), proto: getProtocol(), success: success, result: resultText, duration: duration, startTime: startTime, waitTime: waitTime, wifiBytesReceived: wifiBytesReceived, wifiBytesSent: wifiBytesSent, cellBytesReceived: cellBytesReceived, cellBytesSent: cellBytesSent, multipathService: runCfg.multipathServiceVar, missed: missed, maxDelay: maxDelay, delays: delays)
    }
    
    override func run() -> [String : Any] {
        _ = super.run()
        let reqresString = QuictrafficRun(runCfg)
        let elapsed = startTime.timeIntervalSinceNow
        wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        var delays = [Int64]()
        let lines = reqresString!.components(separatedBy: .newlines)
        if lines[0] != "Exiting client main with error deadline exceeded" && lines[0] != "Exiting client main with error nil" {
            // An error occured...
            result = [
                "delays": [],
                "missed": Int64(35),
                "duration": "-1.0",
                "error_msg": lines[0],
                "success": false,
                "wifi_bytes_sent": wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent,
                "wifi_bytes_received": wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived,
                "cell_bytes_sent": cellInfoEnd.bytesSent - cellInfoStart.bytesSent,
                "cell_bytes_received": cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived,
            ]
            return result
        }
        for i in 2..<lines.count-1 {
            delays.append(Int64(lines[i])!)
        }
        let missed = 35 - delays.count
        result = [
            "delays": delays,
            "missed": Int64(missed),
            "duration": String(format: "%.9f", elapsed),
            "success": true,
            "wifi_bytes_sent": wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent,
            "wifi_bytes_received": wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived,
            "cell_bytes_sent": cellInfoEnd.bytesSent - cellInfoStart.bytesSent,
            "cell_bytes_received": cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived,
        ]
        return result
    }
}
