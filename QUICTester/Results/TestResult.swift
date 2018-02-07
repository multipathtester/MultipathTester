//
//  TestResults.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/1/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation
import Charts

enum TestResultType: String, Codable {
    // /!\ Name of the tests is definitive!
    case connectivity
    case bulkDownload
    case reqRes
    case perf
    case stream
    
    var metatype: TestResult.Type {
        switch self {
        case .connectivity:
            return ConnectivityResult.self
        case .bulkDownload:
            return BulkDownloadResult.self
        case .reqRes:
            return ReqResResult.self
        case .perf:
            return PerfResult.self
        case .stream:
            return StreamResult.self
        }
    }
}

protocol TestResult: Codable {
    static var type: TestResultType { get }
    static func getCollectURL() -> URL
    static func getTestName() -> String
    static func getTestDescription() -> String
    func getChartData() -> [ChartEntries]
    func getDescription() -> String
    func getDuration() -> Double
    func getProtocol() -> NetProtocol
    func getResult() -> String
    func getWaitTime() -> Double
    func getWifiBytesReceived() -> UInt32
    func getWifiBytesSent() -> UInt32
    func getCellBytesReceived() -> UInt32
    func getCellBytesSent() -> UInt32
    func resultsToJSONDict() -> [String: Any]
    func toJSONDict(benchmarkUUID: String, order: Int, protoInfo: [[String: Any]], config: [String: Any]) -> [String: Any]
    func succeeded() -> Bool
    func setFailedByNetworkChange()
}
