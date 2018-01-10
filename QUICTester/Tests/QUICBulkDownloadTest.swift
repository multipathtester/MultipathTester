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
    var ipVer: IPVersion
    var maxPathID: UInt8
    var url: String
    var urlPath: String
    
    init(urlPath: String, maxPathID: UInt8, ipVer: IPVersion) {
        self.ipVer = ipVer
        self.maxPathID = maxPathID
        self.urlPath = urlPath
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
        
        url = "https://" + baseURL + ":443/" + urlPath
        let filePrefix = "quictraffic_bulk_" + urlPath + "_" + suffix
        
        super.init(traffic: "bulk", url: url, filePrefix: filePrefix)
        
        // Prepare the run configuration
        runCfg.maxPathIDVar = Int(maxPathID)
        runCfg.logPeriodMsVar = 100
    }
    
    func getDescription() -> String {
        switch ipVer {
        case .v4:
            return getConfig() + " IPv4 Bulk Download of " + urlPath
        case .v6:
            return getConfig() + " IPv6 Bulk Download of " + urlPath
        default:
            return getConfig() + " Bulk Download of " + urlPath
        }
    }
    
    func getBenchDict() -> [String : Any] {
        return [
            "name": "simple_http_get",
            "config": [
                "file_name": urlPath,
                "server_url": url,
            ],
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
        var rcvBytesDatas = [RcvBytesData]()
        var cid: String = ""
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        for qi in quicInfos {
            guard let cidsDict = qi["Connections"] as? [String: Any] else {continue}
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
        return QUICBulkDownloadResult(name: getDescription(), rcvBytesDatas: rcvBytesDatas, runTime: Double(result["run_time"] as! String)!)
    }
    
    func run() -> [String : Any] {
        startTime = Date().timeIntervalSince1970
        let durationString = QuictrafficRun(runCfg)
        do {
            let text = try String(contentsOf: outFileURL, encoding: .utf8)
            let lines = text.components(separatedBy: .newlines)
            for line in lines {
                print(line)
            }
        } catch { print("Nope...") }
        result = [
            "run_time": String(format: "%.9f", Utils.parse(durationString: durationString!)),
        ]
        return result
    }
    
    
}
