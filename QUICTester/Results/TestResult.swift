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
    case quicConnectivity
    case quicBulkDownload
    case quicReqRes
    case quicPerf
    
    var metatype: TestResult.Type {
        switch self {
        case .quicConnectivity:
            return QUICConnectivityResult.self
        case .quicBulkDownload:
            return QUICBulkDownloadResult.self
        case .quicReqRes:
            return QUICReqResResult.self
        case .quicPerf:
            return QUICPerfResult.self
        }
    }
}

protocol TestResult: Codable {
    static var type: TestResultType { get }
    func getDescription() -> String
    func getResult() -> String
}
