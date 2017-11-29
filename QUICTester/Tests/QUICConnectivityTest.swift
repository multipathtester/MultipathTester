//
//  QUICConnectivityTest.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 11/29/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Quictraffic

class QUICConnectivityTest: Test {
    var port: Int16
    var notifyID: String
    var outFileURL: URL = URL(fileURLWithPath: "dummy")
    var runCfg: RunConfig
    
    init(port: Int16) {
        self.port = port
        
        // Notify ID
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let date = Date()
        notifyID = dateFormatter.string(from: date)
        
        // Out file
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            outFileURL = dir.appendingPathComponent("quictraffic_connectivity_" + String(self.port) + ".out")
        }
        do {
            try "".write(to: outFileURL, atomically: false, encoding: .utf8)
        }
        catch {}
        
        // Prepare the run configuration
        runCfg = RunConfig(traffic: "bulk", url: "https://ns387496.ip-176-31-249.eu:" + String(self.port) + "/connectivityTest")
        runCfg.outputVar = outFileURL.absoluteString
        runCfg.notifyIDVar = notifyID
    }
    
    func getDescription() -> String {
        return "QUIC Connectivity on port " + String(self.port)
    }
    
    func run() -> Bool {
        let durationString = QuictrafficRun(runCfg)
        print(durationString as Any)
        do {
            let text = try String(contentsOf: outFileURL, encoding: .utf8)
            let lines = text.components(separatedBy: .newlines)
            for line in lines {
                print(line)
                if line.contains("It works!") {
                    return true
                }
            }
        } catch { print("Nope...") }
        return false
    }
}
