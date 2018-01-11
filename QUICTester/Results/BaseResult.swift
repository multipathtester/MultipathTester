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
    var runTime: Double
    
    // MARK: Initializers
    init(name: String, proto: NetProtocol, success: Bool, result: String, runTime: Double) {
        self.name = name
        self.proto = proto
        self.success = success
        self.result = result
        self.runTime = runTime
    }
    
    func getDescription() -> String {
        return name
    }
    
    func getResult() -> String {
        return result
    }
    
    func getProtocol() -> NetProtocol {
        return proto
    }
    
    func succeeded() -> Bool {
        return success
    }
}
