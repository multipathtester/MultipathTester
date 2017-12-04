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
    
    init(traffic: String, url: String, filePrefix: String) {
        runCfg = RunConfig(traffic: traffic, url: url)
        // Notify ID
        let now = Date().timeIntervalSince1970
        notifyID = String(now)
        
        runCfg.notifyIDVar = notifyID
        
        // Log file
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            logFileURL = dir.appendingPathComponent(filePrefix + ".log")
        }
        do {
            try FileManager.default.removeItem(at: logFileURL)
        } catch {print(logFileURL, "does not exist")}
        do {
            try "".write(to: logFileURL, atomically: false, encoding: .utf8)
        }
        catch {print(logFileURL, "oups log")}
        
        // Out file
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            outFileURL = dir.appendingPathComponent(filePrefix + ".out")
        }
        do {
            try FileManager.default.removeItem(at: outFileURL)
        } catch {print(outFileURL, "does not exist")}
        do {
            try "".write(to: outFileURL, atomically: false, encoding: .utf8)
        }
        catch {print(outFileURL, "oups out")}
        
        // Prepare the run configuration
        runCfg.logFileVar = logFileURL.absoluteString
        runCfg.outputVar = outFileURL.absoluteString
    }
    
    func getNotifyID() -> String {
        return notifyID
    }
    
    func getStartTime() -> Double {
        return startTime
    }
    
    func getQUICInfo() -> [[String: Any]] {
        return Utils.collectQUICInfo(logFileURL: logFileURL)
    }
}
