//
//  BaseBulkDownloadTest.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 2/25/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class BaseBulkDownloadTest: BaseTest, Test {
    var errorMsg: String = ""
    var rcvBytesDatas = [RcvBytesData]()
    
    func getDescription() -> String {
        let baseConfig = getProtocol().rawValue
        switch ipVer {
        case .v4:
            return baseConfig + " IPv4 Bulk Download of " + urlPath
        case .v6:
            return baseConfig + " IPv6 Bulk Download of " + urlPath
        default:
            return baseConfig + " Bulk Download of " + urlPath
        }
    }
    
    func getConfigDict() -> [String : Any] {
        return [
            "url": getURL(),
        ]
    }
    
    // Because QUIC cannot do GET without the https:// ...
    override func getURL() -> String {
        let url = super.getURL()
        return "https://" + url
    }
    
    override func getRunTime() -> Double {
        return 5.0
    }
    
    func getTestResult() -> TestResult {
        var resultMsg = result["error_msg"] as? String ?? "None"
        let duration = Double(result["duration"] as? String ?? "0.0")!
        let success = result["success"] as? Bool ?? false
        if success {
            resultMsg = String(format: "Completed in %.3f s", duration)
        }
        let wifiBytesSent = result["wifi_bytes_sent"] as? UInt32 ?? 0
        let wifiBytesReceived = result["wifi_bytes_received"] as? UInt32 ?? 0
        let cellBytesSent = result["cell_bytes_sent"] as? UInt32 ?? 0
        let cellBytesReceived = result["cell_bytes_received"] as? UInt32 ?? 0
        return BulkDownloadResult(name: getDescription(), proto: getProtocol(), success: success, result: resultMsg, duration: duration, startTime: startTime, waitTime: waitTime, wifiBytesReceived: wifiBytesReceived, wifiBytesSent: wifiBytesSent, cellBytesReceived: cellBytesReceived, cellBytesSent: cellBytesSent, multipathService: runCfg.multipathServiceVar, rcvBytesDatas: rcvBytesDatas)
    }
}
