//
//  BaseTest.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/1/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation
class BaseTest {
    var logFileURL: URL = URL(fileURLWithPath: "")
    var notifyID: String
    var outFileURL: URL = URL(fileURLWithPath: "")
    var runCfg: RunConfig
    var startTime: Double = 0.0
    var result: [String:Any] = [String:Any]()
    
    init(traffic: String, url: String) {
        runCfg = RunConfig(traffic: traffic, url: url)
        // Notify ID
        let now = Date().timeIntervalSince1970
        notifyID = String(now)
        
        runCfg.notifyIDVar = notifyID
    }
    
    func getNotifyID() -> String {
        return notifyID
    }
    
    func getStartTime() -> Double {
        return startTime
    }
}
