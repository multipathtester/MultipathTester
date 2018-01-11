//
//  QUICBulkDownload.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/4/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class BulkDownloadResult: BaseResult, TestResult {
    // MARK: Needed for Codable ability...
    static var type = TestResultType.bulkDownload
    
    // MARK: Properties
    var rcvBytesDatas: [RcvBytesData]
    
    enum CodingKeys: String, CodingKey {
        case rcvBytesDatas
    }
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("bulkDownloadResults")
    
    // MARK: Initializers
    init(name: String, proto: NetProtocol, success: Bool, result: String, runTime: Double, rcvBytesDatas: [RcvBytesData]) {
        self.rcvBytesDatas = rcvBytesDatas
        super.init(name: name, proto: proto, success: success, result: result, runTime: runTime)
    }
    
    convenience init(name: String, proto: NetProtocol, runTime: Double, rcvBytesDatas: [RcvBytesData]) {
        let result = "Completed in " + String(describing: runTime) + " s"
        self.init(name: name, proto: proto, success: true, result: result, runTime: runTime, rcvBytesDatas: rcvBytesDatas)
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
}
