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
    var runTime: Double
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("quicBulkDownloadResults")
    
    // MARK: Types
    struct PropertyKey {
        static let name = "name"
        static let runTime = "runTime"
    }
    
    // MARK: Initializers
    init?(name: String, runTime: Double) {
        self.name = name
        self.runTime = runTime
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.name)
        aCoder.encode(runTime, forKey: PropertyKey.runTime)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: PropertyKey.name) as! String
        let runTime = aDecoder.decodeDouble(forKey: PropertyKey.runTime)
        
        self.init(name: name, runTime: runTime)
    }
    
    // MARK: TestResult
    func getDescription() -> String {
        return name
    }
    
    func getResult() -> String {
        return String(describing: runTime)
    }
}
