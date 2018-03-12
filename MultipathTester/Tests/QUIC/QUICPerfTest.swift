//
//  QUICPerfTest.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/5/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Quictraffic

class QUICPerfTest: BasePerfTest {
    // MARK: Properties
    var maxPathID: UInt8
    
    init(ipVer: IPVersion, maxPathID: UInt8) {
        self.maxPathID = maxPathID

        let filePrefix = "quictraffic_qperf_" + ipVer.rawValue
        super.init(ipVer: ipVer, filePrefix: filePrefix, waitTime: 3.0)
        
        // Prepare the run configuration
        runCfg.maxPathIDVar = Int(maxPathID)
    }
    
    override func getProtocol() -> NetProtocol {
        if maxPathID > 0 {
            return .MPQUIC
        }
        return .QUIC
    }
    
    override func getTestResult() -> TestResult {
        let quicInfos = getProtoInfo()
        cwinData = [String: [CWinData]]()
        var sawPaths = [String: String]()
        var cid: String = ""
        var paths: [String] = [String]()
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
            guard let pathsDict = cidDict["Paths"] as? [String: Any] else {continue}
            paths = Array(pathsDict.keys)
            for pth in paths {
                let pthDict = pathsDict[pth] as! [String: Any]
                if sawPaths[pth] == nil {
                    var newLabel = "Path " + pth
                    if let ifName = pthDict["InterfaceName"] as? String {
                        if ifName.starts(with: "en") {
                            newLabel += " (WiFi)"
                        } else if ifName.starts(with: "pdp_ip") {
                            newLabel += " (Cellular)"
                        } else if ifName.count > 0 {
                            newLabel += " (" + ifName + ")"
                        }
                    }
                    sawPaths[pth] = newLabel + " Congestion Window"
                }
                let label = sawPaths[pth]!
                
                let cwin = UInt64(pthDict["CongestionWindow"] as! Int)
                let timeDate = df.date(from: qi["Time"] as! String)!
                let time = timeDate.timeIntervalSince1970
                if cwinData[label] == nil {
                    cwinData[label] = [CWinData]()
                }
                cwinData[label]!.append(CWinData(time: time, cwin: cwin))
            }
        }
        // Remove Path 0 if there are other paths
        if cwinData.keys.count > 1 {
            let label0 = sawPaths["0"]!
            cwinData[label0] = nil
        }
        let intervalsRaw = result["intervals"] as? [[String: Any]] ?? []
        intervals = [IntervalData]()
        if intervalsRaw.count > 0 {
            for i in 0..<intervalsRaw.count {
                let intervalRaw = intervalsRaw[i]
                let interval = IntervalData(interval: intervalRaw["intervalInSec"] as! String, transferredLastSecond: UInt64(intervalRaw["transferredLastSecond"] as! Int), globalBandwidth: UInt64(intervalRaw["globalBandwidth"] as! Int), retransmittedLastSecond: UInt64(intervalRaw["retransmittedLastSecond"] as! Int))
                intervals.append(interval)
            }
        }
        return super.getTestResult()
    }
    
    override func run() -> [String : Any] {
        _ = super.run()
        let group = DispatchGroup()
        let queue = OperationQueue()
        var qperfString: String? = ""
        group.enter()
        queue.addOperation {
            qperfString = QuictrafficRun(self.runCfg)
            group.leave()
        }
        var res = group.wait(timeout: .now() + TimeInterval(0.1))
        while res == .timedOut {
            if self.stopped {
                qperfString = "ERROR: Test stopped"
                break
            }
            res = group.wait(timeout: .now() + TimeInterval(0.1))
        }
        wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        let lines = qperfString!.components(separatedBy: .newlines)
        if lines.count < 2 || lines[lines.count - 1] != "" {
            // An error occurred: the string does not end with a '\n'
            result = [
                "intervals": [],
                "duration": "-1.0",
                "error_msg": lines[0],
                "success": false,
                "total_retrans": "0",
                "total_sent": "0",
                "wifi_bytes_sent": wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent,
                "wifi_bytes_received": wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived,
                "cell_bytes_sent": cellInfoEnd.bytesSent - cellInfoStart.bytesSent,
                "cell_bytes_received": cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived,
            ]
            return result
        }
        var intervals = [[String: Any]]()
        for i in 1...runCfg.runTimeVar {
            let splitted_line = lines[i].components(separatedBy: " ")
            intervals.append([
                "intervalInSec": splitted_line[0],
                "transferredLastSecond": Int(splitted_line[1])!,
                "globalBandwidth": Int(splitted_line[2])!,
                "retransmittedLastSecond": Int(splitted_line[3])!,
            ])
        }
        let splitted_line = lines[lines.count - 2].components(separatedBy: " ")
        result = [
            "intervals": intervals,
            "duration": String(format: "%.9f", Utils.parse(durationString: splitted_line[3])),
            "success": true,
            "total_retrans": splitted_line[5],
            "total_sent": splitted_line[1],
            "wifi_bytes_sent": wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent,
            "wifi_bytes_received": wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived,
            "cell_bytes_sent": cellInfoEnd.bytesSent - cellInfoStart.bytesSent,
            "cell_bytes_received": cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived,
        ]
        return result
    }
    

}
