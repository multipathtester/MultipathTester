//
//  QUICBulkDownload.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/4/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Quictraffic

class QUICBulkDownloadTest: BaseBulkDownloadTest {
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
    
    override func getProtocol() -> NetProtocol {
        if maxPathID > 0 {
            return .MPQUIC
        }
        return .QUIC
    }
    
    override func getTestResult() -> TestResult {
        let quicInfos = getProtoInfo()
        rcvBytesDatas = [RcvBytesData]()
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
        return super.getTestResult()
    }
    
    override func run() -> [String : Any] {
        _ = super.run()
        var success = true
        let group = DispatchGroup()
        let queue = OperationQueue()
        var durationString: String? = ""
        group.enter()
        queue.addOperation {
            durationString = QuictrafficRun(self.runCfg)
            group.leave()
        }
        var res = group.wait(timeout: .now() + TimeInterval(0.1))
        while res == .timedOut {
            if self.stopped {
                durationString = "ERROR: Test stopped"
                break
            }
            res = group.wait(timeout: .now() + TimeInterval(0.1))
        }
        
        wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        if self.stopped {
            result = [
                "duration": "0.0",
                "error_msg": durationString ?? "ERROR: Test stopped",
                "success": false,
                "wifi_bytes_sent": wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent,
                "wifi_bytes_received": wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived,
                "cell_bytes_sent": cellInfoEnd.bytesSent - cellInfoStart.bytesSent,
                "cell_bytes_received": cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived,
            ]
            return result
        }
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
