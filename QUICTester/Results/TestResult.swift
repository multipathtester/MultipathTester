//
//  TestResults.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/1/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

enum TestResultType: String, Codable {
    // /!\ Name of the tests is definitive!
    case connectivity
    case bulkDownload
    case reqRes
    case perf
    
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
        }
    }
}

protocol TestResult: Codable {
    static var type: TestResultType { get }
    static func getTestName() -> String
    static func getTestDescription() -> String
    func getDescription() -> String
    func getProtocol() -> NetProtocol
    func getResult() -> String
    func succeeded() -> Bool
}
