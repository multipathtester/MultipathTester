//
//  QUICPerfTest.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/5/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Quictraffic

class QUICPerfTest: BaseTest, Test {
    // MARK: Properties
    var maxPathID: UInt8
    
    init(ipVer: IPVersion, maxPathID: UInt8) {
        self.maxPathID = maxPathID

        let filePrefix = "quictraffic_qperf_" + ipVer.rawValue
        super.init(traffic: "qperf", ipVer: ipVer, port: 5201, urlPath: nil, filePrefix: filePrefix)
        
        // Prepare the run configuration
        runCfg.maxPathIDVar = Int(maxPathID)
        runCfg.logPeriodMsVar = 25
    }
    
    func getDescription() -> String {
        let baseConfig = getProtocol().rawValue
        switch ipVer {
        case .v4:
            return baseConfig + " IPv4 IPerf"
        case .v6:
            return baseConfig + " IPv6 IPerf"
        default:
            return baseConfig + " IPerf"
        }
    }
    
    func getConfigDict() -> [String : Any] {
        return [
            "duration": 10,
            "port": self.port,
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
        var cwinData = [String: [CWinData]]()
        var cid: String = ""
        var paths: [String] = [String]()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        for qi in quicInfos {
            guard let cidsDict = qi["Connections"] as? [String: Any] else {continue}
            if cid == "" {
                cid = Array(cidsDict.keys)[0]
            }
            guard let cidDict = cidsDict[cid] as? [String: Any] else {continue}
            guard let pathsDict = cidDict["Paths"] as? [String: Any] else {continue}
            paths = Array(pathsDict.keys)
            for pth in paths {
                let pthDict = pathsDict[pth] as! [String: Any]
                let cwin = UInt64(pthDict["CongestionWindow"] as! Int)
                let timeDate = df.date(from: qi["Time"] as! String)!
                let time = timeDate.timeIntervalSince1970
                if cwinData[pth] == nil {
                    cwinData[pth] = [CWinData]()
                }
                cwinData[pth]!.append(CWinData(time: time, cwin: cwin))
            }
        }
        let intervalsRaw = result["intervals"] as! [[String: Any]]
        var intervals = [IntervalData]()
        if intervalsRaw.count > 0 {
            for i in 0..<intervalsRaw.count {
                let intervalRaw = intervalsRaw[i]
                let interval = IntervalData(interval: intervalRaw["intervalInSec"] as! String, transferredLastSecond: UInt64(intervalRaw["transferredLastSecond"] as! Int), globalBandwidth: UInt64(intervalRaw["globalBandwidth"] as! Int), retransmittedLastSecond: UInt64(intervalRaw["retransmittedLastSecond"] as! Int))
                intervals.append(interval)
            }
        }
        let duration = Double(result["duration"] as! String)!
        let totalRetrans = UInt64(result["total_retrans"] as! String)!
        let totalSent = UInt64(result["total_sent"] as! String)!
        let success = result["success"] as! Bool
        var resultText = ""
        if success {
            resultText = "Achieved a mean goodput of " + String(format: "%.3f", Double(intervals[intervals.count-1].globalBandwidth * 8) / 1000000.0) + " Mbps."
        } else {
            resultText = result["error_msg"] as! String
        }
        return PerfResult(name: getDescription(), proto: getProtocol(), success: success, result: resultText, duration: duration, startTime: startTime, waitTime: 0.0, totalRetrans: totalRetrans, totalSent: totalSent, intervals: intervals, cwins: cwinData)
    }
    
    func run() -> [String : Any] {
        startTime = Date()
        let qperfString = QuictrafficRun(runCfg)
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
            ]
            return result
        }
        var intervals = [[String: Any]]()
        for i in 1...10 {
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
        ]
        return result
    }
    

}
