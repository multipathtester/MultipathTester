//
//  Test.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 11/29/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

enum IPVersion: String, Codable {
    case v4
    case v6
    case any
}

enum TestServer: String, Codable {
    case fr
    case ca
    case jp
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
    func getConfigDict() -> [String: Any]
    func getNotifyID() -> String
    func getProtocol() -> NetProtocol
    func getProtoInfo() -> [[String: Any]]
    func getRunTime() -> Double
    func getStartTime() -> Date
    func getTestResult() -> TestResult
    func getTestServer() -> TestServer
    func getURL() -> String
    func getWaitTime() -> Double
    func setTestServer(testServer: TestServer)
    func setMultipathService(service: RunConfig.MultipathServiceType)
    func updateURL()
    func run() -> [String:Any]
}
