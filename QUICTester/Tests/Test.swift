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

protocol Test {
    func getDescription() -> String
    func getBenchDict() -> [String: Any]
    func getConfig() -> String
    func getNotifyID() -> String
    func getQUICInfo() -> [[String: Any]]
    func getStartTime() -> Double
    func getTestResult() -> TestResult
    func run() -> [String:Any]
}
