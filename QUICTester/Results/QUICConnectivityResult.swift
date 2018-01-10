//
//  ConnectivityResult.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/1/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class QUICConnectivityResult: NSObject, TestResult {
    // MARK: Needed for Codable ability...
    static var type = TestResultType.quicConnectivity
    
    // MARK: Properties
    var name: String
    var runTime: Double
    var success: Bool
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("quicConnectivityResults")
    
    // MARK: Initializers
    init(name: String, runTime: Double, success: Bool) {
        self.name = name
        self.runTime = runTime
        self.success = success
    }
    
    // MARK: TestResult
    func getDescription() -> String {
        return name
    }
    
    func getResult() -> String {
        if success {
            return "Succeeded in " + String(runTime) + " s"
        }
        return "Failed"
    }
}
