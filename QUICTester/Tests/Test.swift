//
//  Test.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 11/29/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

enum IPVersion {
    case v4
    case v6
    case any
}

enum NetProtocol: String, Codable {
    case TCP
    case MPTCP
    case QUIC
    case MPQUIC
    
    var main: String {
        switch self {
        case .TCP:
            return "TCP"
        case .MPTCP:
            return "TCP"
        case.QUIC:
            return "QUIC"
        case .MPQUIC:
            return "QUIC"
        }
    }
}

protocol Test {
    func getDescription() -> String
    func getBenchDict() -> [String: Any]
    func getConfig() -> NetProtocol
    func getNotifyID() -> String
    func getQUICInfo() -> [[String: Any]]
    func getStartTime() -> Double
    func getTestResult() -> TestResult
    func run() -> [String:Any]
}
