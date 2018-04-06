//
//  QUICPerfTest.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/5/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Quictraffic
import Charts

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
        return super.getTestResult()
    }
    
    override func run() {
        super.run()
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
        
        wifiBytesSent = wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent
        wifiBytesReceived = wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived
        cellBytesSent = cellInfoEnd.bytesSent - cellInfoStart.bytesSent
        cellBytesReceived = cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived
        
        let lines = qperfString!.components(separatedBy: .newlines)
        if lines.count < 2 || lines[lines.count - 1] != "" {
            // An error occurred: the string does not end with a '\n'
            errorMsg = lines[0]

            return
        }
        if stopped {
            errorMsg = "ERROR: Test stopped"
            
            return
        }
        for i in 1...runCfg.runTimeVar {
            let splitted_line = lines[i].components(separatedBy: " ")
            let interval = IntervalData(interval: splitted_line[0], transferredLastSecond: UInt64(splitted_line[1])!, globalBandwidth: UInt64(splitted_line[2])!, retransmittedLastSecond: UInt64(splitted_line[3])!)
            intervals.append(interval)
        }
        let splitted_line = lines[lines.count - 2].components(separatedBy: " ")
        success = true
        duration = Utils.parse(durationString: splitted_line[3])
        totalRetrans = UInt64(splitted_line[5])!
        totalSent = UInt64(splitted_line[1])!
    }
    
    override func getChartData() -> ChartEntries? {
        var curIntervals = [IntervalData]()
        let qperfString = QuictrafficGetQPerfResults(runCfg.notifyID())
        let lines = qperfString!.components(separatedBy: .newlines)
        if lines.count < 2 || lines[lines.count - 1] != "" {
            return nil
        }
        for i in 1..<lines.count {
            let splitted_line = lines[i].components(separatedBy: " ")
            if splitted_line.count != 4 {
                continue
            }
            let interval = IntervalData(interval: splitted_line[0], transferredLastSecond: UInt64(splitted_line[1])!, globalBandwidth: UInt64(splitted_line[2])!, retransmittedLastSecond: UInt64(splitted_line[3])!)
            curIntervals.append(interval)
        }
        let values = curIntervals.enumerated().map { (arg) -> ChartDataEntry in
            let (index, i) = arg
            return ChartDataEntry(x: Double(index), y: Double(i.transferredLastSecond))
        }
        return LineChartEntries(xLabel: "Time", yLabel: "Bytes", data: values, dataLabel: "Bytes transferred last second", xValueFormatter: DateValueFormatter())
    }
}
