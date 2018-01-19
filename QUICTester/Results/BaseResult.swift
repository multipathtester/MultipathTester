//
//  BaseResult.swift
//  QUICTester
//
//  This class aims to collect all common properties results share.
//  It is not intended to be instanciated "as it".
//
//  Created by Quentin De Coninck on 1/11/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import Foundation

class BaseResult: Codable {
    // MARK: Properties
    var name: String
    var proto: NetProtocol
    var success: Bool
    // This string will include either textual result representation or a string describing the error if the test failed
    var result: String
    var duration: Double
    var startTime: Date
    var waitTime: Double
    
    // MARK: Initializers
    init(name: String, proto: NetProtocol, success: Bool, result: String, duration: Double, startTime: Date, waitTime: Double) {
        self.name = name
        self.proto = proto
        self.success = success
        self.result = result
        self.duration = duration
        self.startTime = startTime
        self.waitTime = waitTime
    }
    
    // MARK: JSON serialization to collect server
    func resultsToJSONDict() -> [String: Any] {
        return [
            "success": success,
        ]
    }
    
    func toJSONDict(benchmarkUUID: String, order: Int, protoInfo: [[String: Any]], config: [String: Any]) -> [String: Any] {
        return [
            "benchmark_uuid": benchmarkUUID,
            "order": order,
            "protocol_info": protoInfo,
            "start_time": Utils.getDateFormatter().string(from: startTime),
            "wait_time": String(format: "%.6f", waitTime),
            "duration": String(format: "%.6f", duration),
            "protocol": proto.rawValue,
            "config": config,
            "result": resultsToJSONDict(),
        ]
    }
    
    // MARK: Getters
    func getDescription() -> String {
        return name
    }
    
    func getDuration() -> Double {
        return duration
    }
    
    func getResult() -> String {
        return result
    }
    
    func getProtocol() -> NetProtocol {
        return proto
    }
    
    func getStartTime() -> Date {
        return startTime
    }
    
    func getWaitTime() -> Double {
        return waitTime
    }
    
    func succeeded() -> Bool {
        return success
    }
}
