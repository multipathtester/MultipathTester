//
//  QUICBulkDownload.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/4/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class QUICBulkDownloadResult: NSObject, TestResult {
    // MARK: Needed for Codable ability...
    static var type = TestResultType.quicBulkDownload
    
    // MARK: Properties
    var name: String
    var rcvBytesDatas: [RcvBytesData]
    var runTime: Double
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("quicBulkDownloadResults")
    
    // MARK: Initializers
    init(name: String, rcvBytesDatas: [RcvBytesData], runTime: Double) {
        self.name = name
        self.rcvBytesDatas = rcvBytesDatas
        self.runTime = runTime
    }
    
    // MARK: TestResult
    func getDescription() -> String {
        return name
    }
    
    func getResult() -> String {
        if runTime < 0.0 {
            return "Failed"
        }
        return "Completed in " + String(describing: runTime) + " s"
    }
}
