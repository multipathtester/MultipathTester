//
//  RunStruct.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 11/29/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import Foundation
import Quictraffic

class RunConfig: NSObject, QuictrafficRunConfigProtocol {

    // MARK: Properties
    var trafficVar: String
    var cacheVar: Bool = false
    var logFileVar: String = ""
    var logPeriodMsVar: Int = 1000
    var maxPathIDVar: Int = 0
    var notifyIDVar: String = ""
    var outputVar: String = ""
    var printBodyVar: Bool = false
    var runTimeVar: Int = 30
    var urlVar: String
    
    init(traffic: String, url: String) {
        self.trafficVar = traffic
        self.urlVar = url
    }
    
    func traffic() -> String! {
        return trafficVar
    }
    
    func cache() -> Bool {
        return cacheVar
    }
    
    func logFile() -> String! {
        return logFileVar
    }
    
    func logPeriodMs() -> Int {
        return logPeriodMsVar
    }
    
    func maxPathID() -> Int {
        return maxPathIDVar
    }
    
    func notifyID() -> String! {
        return notifyIDVar
    }
    
    func output() -> String! {
        return outputVar
    }
    
    func printBody() -> Bool {
        return printBodyVar
    }
    
    func runTime() -> Int {
        return runTimeVar
    }
    
    func url() -> String! {
        return urlVar
    }
}
