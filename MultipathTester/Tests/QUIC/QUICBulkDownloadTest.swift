//
//  QUICBulkDownload.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/4/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Quictraffic

class QUICBulkDownloadTest: BaseTest, Test {
    // MARK: Properties
    var maxPathID: UInt8
    
    init(ipVer: IPVersion, urlPath: String, maxPathID: UInt8) {
        self.maxPathID = maxPathID
        let filePrefix = "quictraffic_bulk_" + urlPath.dropFirst() + "_" + ipVer.rawValue
        
        super.init(traffic: "bulk", ipVer: ipVer, port: 443, urlPath: urlPath, filePrefix: filePrefix, waitTime: 2.0)
        
        // Prepare the run configuration
        runCfg.maxPathIDVar = Int(maxPathID)
        runCfg.logPeriodMsVar = 100
    }
    
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
    
    func getProtocol() -> NetProtocol {
        if maxPathID > 0 {
            return .MPQUIC
        }
        return .QUIC
    }
    
    func getTestResult() -> TestResult {
        let quicInfos = getProtoInfo()
        var rcvBytesDatas = [RcvBytesData]()
        var cid: String = ""
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        for qi in quicInfos {
            guard let cidsDict = qi["Connections"] as? [String: Any] else {continue}
            if cidsDict.count == 0 {
                // Avoid crash...
                continue
            }
            if cid == "" {
                cid = Array(cidsDict.keys)[0]
            }
            guard let cidDict = cidsDict[cid] as? [String: Any] else {continue}
            guard let streamsDict = cidDict["Streams"] as? [String: Any] else {continue}
            if streamsDict["3"] != nil {
                let streamDict = streamsDict["3"] as! [String: Any]
                let rcvbytes = UInt64(streamDict["BytesRead"] as! Int)
                let timeDate = df.date(from: qi["Time"] as! String)!
                let time = timeDate.timeIntervalSince1970
                rcvBytesDatas.append(RcvBytesData(time: time, rcvBytes: rcvbytes))
            }
        }
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
    
    // Because QUIC cannot do GET without the https:// ...
    override func getURL() -> String {
        let url = super.getURL()
        return "https://" + url
    }
    
    override func getRunTime() -> Double {
        return 5.0
    }
    
    override func run() -> [String : Any] {
        _ = super.run()
        var success = true
        var errorMsg = ""
        let durationString = QuictrafficRun(runCfg)
        wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        do {
            print("Opening", outFileURL)
            let text = try String(contentsOf: outFileURL, encoding: .utf8)
            let lines = text.components(separatedBy: .newlines)
            for line in lines {
                if line.contains("ERROR") {
                    success = false
                    errorMsg = line.components(separatedBy: "ERROR: ")[1]
                }
            }
        } catch { print("Nope...") }
        result = [
            "duration": String(format: "%.9f", Utils.parse(durationString: durationString!)),
            "error_msg": errorMsg,
            "success": success,
            "wifi_bytes_sent": wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent,
            "wifi_bytes_received": wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived,
            "cell_bytes_sent": cellInfoEnd.bytesSent - cellInfoStart.bytesSent,
            "cell_bytes_received": cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived,
        ]
        return result
    }
    
    
}
