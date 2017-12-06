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
    var ipVer: IPVersion
    var maxPathID: UInt8
    var url: String
    
    init(maxPathID: UInt8, ipVer: IPVersion) {
        self.ipVer = ipVer
        self.maxPathID = maxPathID
        var baseURL: String = "traffic.multipath-quic.org"
        var suffix: String
        switch ipVer {
        case .v4:
            baseURL = "v4.traffic.multipath-quic.org"
            suffix = "4"
        case .v6:
            baseURL = "v6.traffic.multipath-quic.org"
            suffix = "6"
        default:
            baseURL = "traffic.multipath-quic.org"
            suffix = "any"
        }
        
        url = baseURL + ":5201"
        let filePrefix = "quictraffic_bulk_qperf_" + suffix
        
        super.init(traffic: "qperf", url: url, filePrefix: filePrefix)
        
        // Prepare the run configuration
        runCfg.maxPathIDVar = Int(maxPathID)
    }
    
    func getDescription() -> String {
        switch ipVer {
        case .v4:
            return getConfig() + " IPv4 IPerf"
        case .v6:
            return getConfig() + " IPv6 IPerf"
        default:
            return getConfig() + " IPerf"
        }
    }
    
    func getBenchDict() -> [String : Any] {
        return [
            "name": "iperf",
            "config": [
                "duration": 10,
                "url": url,
            ]
        ]
    }
    
    func getConfig() -> String {
        if maxPathID > 0 {
            return "MPQUIC"
        } else {
            return "QUIC"
        }
    }
    
    func getTestResult() -> TestResult {
        let quicInfos = getQUICInfo()
        var cwinData = [String: [CWinData]]()
        var cid: String = ""
        var paths: [String] = [String]()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        for qi in quicInfos {
            let cidsDict = qi["Connections"] as! [String: Any]
            if cid == "" {
                cid = Array(cidsDict.keys)[0]
            }
            let cidDict = cidsDict[cid] as! [String: Any]
            let pathsDict = cidDict["Paths"] as! [String: Any]
            paths = Array(pathsDict.keys)
            for pth in paths {
                let pthDict = pathsDict[pth] as! [String: Any]
                let cwin = UInt64(pthDict["CongestionWindow"] as! Int)
                let timeDate = df.date(from: qi["Time"] as! String)!
                let time = timeDate.timeIntervalSince1970
                if cwinData[pth] == nil {
                    cwinData[pth] = [CWinData]()
                }
                cwinData[pth]!.append(CWinData(time: time, cwin: cwin)!)
            }
        }
        let intervalsRaw = result["intervals"] as! [[String: Any]]
        var intervals = [IntervalData]()
        if intervalsRaw.count > 0 {
            for i in 0..<intervalsRaw.count {
                let intervalRaw = intervalsRaw[i]
                let interval = IntervalData(interval: intervalRaw["intervalInSec"] as! String, transferredLastSecond: UInt64(intervalRaw["transferredLastSecond"] as! Int), globalBandwidth: UInt64(intervalRaw["globalBandwidth"] as! Int), retransmittedLastSecond: UInt64(intervalRaw["retransmittedLastSecond"] as! Int))!
                intervals.append(interval)
            }
        }
        // TODO intervals
        return QUICPerfResult(name: getDescription(), runTime: Double(result["run_time"] as! String)!, totalRetrans: UInt64(result["total_retrans"] as! String)!, totalSent: UInt64(result["total_sent"] as! String)!, intervals: intervals, cwins: cwinData)!
    }
    
    func run() -> [String : Any] {
        startTime = Date().timeIntervalSince1970
        let qperfString = QuictrafficRun(runCfg)
        let lines = qperfString!.components(separatedBy: .newlines)
        if lines.count < 2 || lines[lines.count - 1] != "" {
            // An error occurred: the string does not end with a '\n'
            result = [
                "intervals": [],
                "run_time": "-1.0",
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
            "run_time": String(format: "%.9f", Utils.parse(durationString: splitted_line[3])),
            "total_retrans": splitted_line[5],
            "total_sent": splitted_line[1],
        ]
        return result
    }
    

}
