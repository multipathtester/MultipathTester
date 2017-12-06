//
//  QUICBulkDownload.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/4/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class QUICBulkDownloadResult: NSObject, NSCoding, TestResult {
    // MARK: Properties
    var name: String
    var rcvBytesDatas: [RcvBytesData]
    var runTime: Double
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("quicBulkDownloadResults")
    
    // MARK: Types
    struct PropertyKey {
        static let name = "name"
        static let rcvBytesDatas = "rcvBytesDatas"
        static let runTime = "runTime"
    }
    
    // MARK: Initializers
    init?(name: String, rcvBytesDatas: [RcvBytesData], runTime: Double) {
        self.name = name
        self.rcvBytesDatas = rcvBytesDatas
        self.runTime = runTime
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.name)
        aCoder.encode(rcvBytesDatas, forKey: PropertyKey.rcvBytesDatas)
        aCoder.encode(runTime, forKey: PropertyKey.runTime)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: PropertyKey.name) as! String
        let rcvBytesDatas = aDecoder.decodeObject(forKey: PropertyKey.rcvBytesDatas) as! [RcvBytesData]
        let runTime = aDecoder.decodeDouble(forKey: PropertyKey.runTime)
        
        self.init(name: name, rcvBytesDatas: rcvBytesDatas, runTime: runTime)
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
