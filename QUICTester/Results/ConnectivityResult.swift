//
//  ConnectivityResult.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/1/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation
import Charts

class ConnectivityResult: BaseResult, TestResult {
    // MARK: Needed for Codable ability...
    static var type = TestResultType.connectivity

    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("connectivityResults")
    
    // MARK: Initializers    
    convenience init(name: String, proto: NetProtocol, success: Bool, runTime: Double) {
        let result = "Succeeded in " + String(runTime) + " s"
        self.init(name: name, proto: proto, success: success, result: result, runTime: runTime)
    }
    
    // MARK: TestResult
    static func getTestName() -> String {
        return "Connectivity"
    }
    
    static func getTestDescription() -> String {
        return "This test checks if a connection can be established"
    }
    
    func getChartData() -> [ChartEntries] {
        return []
    }
}
