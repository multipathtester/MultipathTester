//
//  BenchmarkResult.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/1/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation
class BenchmarkResult: NSObject, NSCoding {
    // MARK: Properties
    var startTime: Double
    var testResults: [TestResult]
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("benchmarkTests")
    
    // MARK: Types
    struct PropertyKey {
        static let startTime = "startTime"
        static let testResults = "testResults"
    }
    
    // MARK: Initializers
    init?(startTime: Double, testResults: [TestResult]) {
        // Initilialize stored properties
        self.startTime = startTime
        self.testResults = testResults
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(startTime, forKey: PropertyKey.startTime)
        aCoder.encode(testResults, forKey: PropertyKey.testResults)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let startTime = aDecoder.decodeDouble(forKey: PropertyKey.startTime)
        let testResults = aDecoder.decodeObject(forKey: PropertyKey.testResults) as! [TestResult]
        
        self.init(startTime: startTime, testResults: testResults)
    }
    
    
}
