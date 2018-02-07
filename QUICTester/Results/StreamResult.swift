//
//  StreamResult.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/24/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import Foundation
import Charts

class StreamResult: BaseResult, TestResult {
    // MARK: Needed for Codable ability...
    static var type = TestResultType.stream
    
    // MARK: Collect URL
    static func getCollectURL() -> URL {
        return URL(string: "https://ns387496.ip-176-31-249.eu/stream/test/")!
    }
    
    // MARK: Properties
    var upDelays: [DelayData]
    var downDelays: [DelayData]
    var errorMsg: String
    
    enum CodingKeys: String, CodingKey {
        case upDelays
        case downDelays
        case errorMsg
    }
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("streamResults")
    
    // MARK: Initializers
    init(name: String, proto: NetProtocol, success: Bool, result: String, duration: Double, startTime: Date, waitTime: Double, wifiBytesReceived: UInt32, wifiBytesSent: UInt32, cellBytesReceived: UInt32, cellBytesSent: UInt32, upDelays: [DelayData], downDelays: [DelayData], errorMsg: String) {
        self.upDelays = upDelays
        self.downDelays = downDelays
        self.errorMsg = errorMsg
        
        super.init(name: name, proto: proto, success: success, result: result, duration: duration, startTime: startTime, waitTime: waitTime, wifiBytesReceived: wifiBytesReceived, wifiBytesSent: wifiBytesSent, cellBytesReceived: cellBytesReceived, cellBytesSent: cellBytesSent)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let superdecoder = try container.superDecoder()
        
        upDelays = try container.decode([DelayData].self, forKey: .upDelays)
        downDelays = try container.decode([DelayData].self, forKey: .downDelays)
        errorMsg = try container.decode(String.self, forKey: .errorMsg)
        
        try super.init(from: superdecoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(upDelays, forKey: .upDelays)
        try container.encode(downDelays, forKey: .downDelays)
        try container.encode(errorMsg, forKey: .errorMsg)
        
        let superencoder = container.superEncoder()
        try super.encode(to: superencoder)
    }
    
    // MARK: TestResult
    static func getTestName() -> String {
        return "Fixed-rate Streaming"
    }
    
    static func getTestDescription() -> String {
        return "This test generates continuous traffic in both directions and computes the observed delay between the transmission of a frame and its acknowledgment."
    }
    
    func getChartData() -> [ChartEntries] {
        let upValues = upDelays.map { (dd) -> ChartDataEntry in
            return ChartDataEntry(x: dd.time, y: Double(dd.delayUs) / 1000.0)
        }
        let downValues = downDelays.map { (dd) -> ChartDataEntry in
            return ChartDataEntry(x: dd.time, y: Double(dd.delayUs) / 1000.0)
        }
        return [
            LineChartEntries(xLabel: "Time", yLabel: "Delay", data: upValues, dataLabel: "Upload delays (ms)", xValueFormatter: DateValueFormatter()),
            LineChartEntries(xLabel: "Time", yLabel: "Delay", data: downValues, dataLabel: "Download delays (ms)", xValueFormatter: DateValueFormatter()),
        ]
    }
    
    override func resultsToJSONDict() -> [String : Any] {
        var res = super.resultsToJSONDict()
        let upValuesJSON = upDelays.map { (dd) -> [String: Any] in
            return [
                "time": Utils.getDateFormatter().string(for: Date(timeIntervalSince1970: dd.time))!,
                "delay": Double(dd.delayUs) / 1000000.0,
            ]
        }
        let downValuesJSON = downDelays.map { (dd) -> [String: Any] in
            return [
                "time": Utils.getDateFormatter().string(for: Date(timeIntervalSince1970: dd.time))!,
                "delay": Double(dd.delayUs) / 1000000.0,
                ]
        }
        
        res["upload_delays"] = upValuesJSON
        res["download_delays"] = downValuesJSON
        res["error_msg"] = errorMsg
        return res
    }
}
