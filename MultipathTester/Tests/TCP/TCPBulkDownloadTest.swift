//
//  TCPBulkDownloadTest.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 2/25/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Charts

class TCPBulkDownloadTest: BaseBulkDownloadTest {
    var multipath: Bool
    
    // MARK: Properties used to generate chart
    var startIndex: Int = 0
    var collectedValues: [ChartDataEntry] = []
    
    init(ipVer: IPVersion, urlPath: String, multipath: Bool) {
        self.multipath = multipath
        let filePrefix = "mptcp_bulk_" + urlPath.dropFirst() + "_" + ipVer.rawValue
        
        super.init(traffic: "bulk", ipVer: ipVer, port: 443, urlPath: urlPath, filePrefix: filePrefix, waitTime: 2.0)
        
        // Prepare the run configuration
        runCfg.logPeriodMsVar = 100
    }
    
    override func getProtocol() -> NetProtocol {
        if multipath {
            return .MPTCP
        }
        return .TCP
    }
    
    func getBytesData(all: Bool) -> [RcvBytesData] {
        var datas = [RcvBytesData]()
        var counter = 0
        var curStartIndex = startIndex
        if all {
            curStartIndex = 0
        }
        for ti in tcpInfos[curStartIndex..<tcpInfos.count] {
            counter += 1
            guard let connInfo = ti["0"] as? [String: Any] else {continue}
            let time = ti["time"] as! Double
            // The format is different in TCP and MPTCP
            if multipath {
                let rcvBytes = connInfo["rxbytes"] as! UInt64
                datas.append(RcvBytesData(time: time, rcvBytes: rcvBytes))
            } else {
                let rcvBytes = connInfo["tcpi_rxbytes"] as! UInt64
                datas.append(RcvBytesData(time: time, rcvBytes: rcvBytes))
            }
        }
        if !all {
            startIndex += counter
        }
        return datas
    }
    
    override func getTestResult() -> TestResult {
        rcvBytesDatas = getBytesData(all: true)
        return super.getTestResult()
    }
    
    override func getChartData() -> ChartEntries? {
        let data = getBytesData(all: false)
        let newValues = data.map { (d) -> ChartDataEntry in
            return ChartDataEntry(x: d.time, y: Double(d.rcvBytes))
        }
        collectedValues += newValues
        return LineChartEntries(xLabel: "Time", yLabel: "Bytes", data: collectedValues, dataLabel: "Bytes received", xValueFormatter: DateValueFormatter())
    }
    
    override func run() {
        super.run()
        
        let config = URLSessionConfiguration.ephemeral
        if multipath {
            switch runCfg.multipathServiceVar {
            case .aggregate:
                config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.aggregate
            case .handover:
                // Don't run handover here, but interactive instead
                runCfg.multipathServiceVar = .interactive
                config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.interactive
            case .interactive:
                config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.interactive
            }
        }
        
        let session = URLSession(configuration: config)
        
        let group = DispatchGroup()
        group.enter()
        
        let url = URL(string: getURL())!
        duration = Date().timeIntervalSince(startTime)
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
            self.duration = Date().timeIntervalSince(self.startTime)
            self.success = true
            group.leave()
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            task.resume()
        }
        
        var res: DispatchTimeoutResult = .timedOut
        let ips = ipsOf(hostname: getTestServerHostname())
        var fd = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), exclude: -1)
        print("We tried once, at least...")
        if (fd < 0) {
            while (res == .timedOut && fd < 0) {
                res = group.wait(timeout: DispatchTime.now() + 0.01)
                print("We missed it once, try again...")
                // Retry, we might have missed the good one thinking it's and old one
                fd = findTCPFileDescriptor(expectedIPs: ips, expectedPort: Int16(port), exclude: -1)
            }
        }
        print("FD is \(fd)")
        
        // This will perform the wait on the group; once this call returns, the traffic is over
        if fd > 0 {
            tcpInfos = TCPLogger.logTCPInfosMain(group: group, fds: [fd], multipath: multipath, logPeriodMs: runCfg.logPeriodMsVar, test: self)
        }
        
        // Close the connection!
        session.reset {
            session.invalidateAndCancel()
        }
        
        wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        
        wifiBytesSent = wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent
        wifiBytesReceived = wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived
        cellBytesSent = cellInfoEnd.bytesSent - cellInfoStart.bytesSent
        cellBytesReceived = cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived
    }
}
