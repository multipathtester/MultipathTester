//
//  QUICBulkDownload.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/4/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation
import Charts

class BulkDownloadResult: BaseResult, TestResult {
    // MARK: Needed for Codable ability...
    static var type = TestResultType.bulkDownload
    
    // MARK: Collect URL
    static func getCollectURL() -> URL {
        return URL(string: "https://ns387496.ip-176-31-249.eu/simplehttpget/test/")!
    }
    
    // MARK: Properties
    var rcvBytesDatas: [RcvBytesData]
    
    enum CodingKeys: String, CodingKey {
        case rcvBytesDatas
    }
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("bulkDownloadResults")
    
    // MARK: Initializers
    init(name: String, proto: NetProtocol, success: Bool, result: String, duration: Double, startTime: Date, waitTime: Double, rcvBytesDatas: [RcvBytesData]) {
        self.rcvBytesDatas = rcvBytesDatas
        super.init(name: name, proto: proto, success: success, result: result, duration: duration, startTime: startTime, waitTime: waitTime)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let superdecoder = try container.superDecoder()
        
        rcvBytesDatas = try container.decode([RcvBytesData].self, forKey: .rcvBytesDatas)
        
        try super.init(from: superdecoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rcvBytesDatas, forKey: .rcvBytesDatas)
        
        let superencoder = container.superEncoder()
        try super.encode(to: superencoder)
    }
    
    // MARK: TestResult
    static func getTestName() -> String {
        return "Bulk Download"
    }
    
    static func getTestDescription() -> String {
        return "This test perform a HTTP GET for a large file"
    }
    
    func getChartData() -> [ChartEntries] {
        let values = rcvBytesDatas.map { (d) -> ChartDataEntry in
            return ChartDataEntry(x: d.time, y: Double(d.rcvBytes))
        }
        return [LineChartEntries(xLabel: "Time", yLabel: "Bytes", data: values, dataLabel: "Bytes received", xValueFormatter: DateValueFormatter())]
    }
    
    override func resultsToJSONDict() -> [String : Any] {
        var res = super.resultsToJSONDict()
        if !success {
            res["error_msg"] = result
        }
        return res
    }
}
