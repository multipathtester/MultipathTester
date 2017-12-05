//
//  QUICPerfTest.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/5/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class QUICPerfTest {
//    func getTestResult() -> TestResult {
//        let quicInfos = getQUICInfo()
//        var cwinData = [String: [(time: Double, cwin: UInt64)]]()
//        var cid: String = ""
//        var paths: [String] = [String]()
//        let df = DateFormatter()
//        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
//        for qi in quicInfos {
//            let cidsDict = qi["Connections"] as! [String: Any]
//            if cid == "" {
//                cid = Array(cidsDict.keys)[0]
//            }
//            let cidDict = cidsDict[cid] as! [String: Any]
//            let pathsDict = cidDict["Paths"] as! [String: Any]
//            paths = Array(pathsDict.keys)
//            for pth in paths {
//                let pthDict = pathsDict[pth] as! [String: Any]
//                let cwin = UInt64(pthDict["CongestionWindow"] as! Int)
//                let timeDate = df.date(from: qi["Time"] as! String)!
//                let time = timeDate.timeIntervalSince1970
//                if cwinData[pth] == nil {
//                    cwinData[pth] = [(time: Double, cwin: UInt64)]()
//                }
//                cwinData[pth]!.append((time: time, cwin: cwin))
//            }
//        }
//        print(cwinData)
//        //return QUICBulkDownloadResult(name: getDescription(), runTime: Double(result["run_time"] as! String)!)!
//    }
}
