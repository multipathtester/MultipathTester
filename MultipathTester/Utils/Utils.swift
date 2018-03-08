//
//  Utils.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 11/29/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class Utils {
    static let TestsLaunchedNotification = NSNotification.Name("TestsLaunchedNotification")
    static var startNewTestsEnabled = true
    
    static func parse(durationString: String) -> Double {
        // Be cautious about the formatting of the durationString
        if durationString.range(of: "ms") != nil {
            return Double(durationString.components(separatedBy: "ms")[0])! / 1000
        } else if durationString.range(of: "m") != nil {
            let splitted = durationString.components(separatedBy: "m")
            return Double(splitted[0])! * 60 + Double(splitted[1].components(separatedBy: "s")[0])!
        } else {
            return Double(durationString.components(separatedBy: "s")[0])!
        }
    }
    
    static func parseSeveralInMs(durationsString: [String]) -> [Double] {
        return durationsString.map { (ds) -> Double in
            return parse(durationString: ds) * 1000.0
        }
    }
    
    static func collectQUICInfo(logFileURL: URL) -> [[String: Any]] {
        var array = [[String: Any]]()
        do {
            let text = try String(contentsOf: logFileURL, encoding: .utf8)
            let lines = text.components(separatedBy: .newlines)
            for line in lines {
                let data = line.data(using: .utf8)
                let json = try? JSONSerialization.jsonObject(with: data!, options: [])
                if (json != nil) {
                    array.append(json as! [String: Any])
                }
            }
        } catch { print("Nope...")}
        return array
    }
    
    static func secondsToMinutesSeconds(seconds: Int) -> (Int, Int) {
        return (seconds / 60, seconds % 60)
    }
    
    static func getDateFormatter() -> DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        return df
    }
    
    static func stringSecondsToMinutesSeconds(seconds: Int) -> String {
        let (m, s) = secondsToMinutesSeconds(seconds: seconds)
        return "\(m) m \(s) s"
    }
    
    static func formatBytes(bytes: UInt32) -> String {
        if Double(bytes) >= 100000.0 {
            return String(format: "%.1f MB", Double(bytes) / 1000000.0)
        }
        // else
        return String(format: "%.1f KB", Double(bytes) / 1000.0)
    }
    
    static func getDebug() {
        let url = URL(string: "http://127.0.0.1:6060/debug/pprof/goroutine?debug=2")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let group = DispatchGroup()
        group.enter()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let checkedData = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                group.leave()
                return
            }
            let responseString = String(data: checkedData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
            print(responseString!)
            group.leave()
        }
        
        task.resume()
        group.wait()
    }
    
    static func getMaxWifiDistance() -> Double {
        // Create GET request
        let url = URL(string: BaseResult.collectURLBase + "mptests/max_wifi_distance/")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        var result = 0.0
        
        let group = DispatchGroup()
        group.enter()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let checkedData = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                if let checkedData = data {
                    let responseJSON = try? JSONSerialization.jsonObject(with: checkedData, options: [])
                    if let responseJSON = responseJSON as? [String: Any] {
                        print(responseJSON)
                    }
                }
                group.leave()
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: checkedData, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                if let maxWifiDistance = responseJSON["max_wifi_distance"] as? Double {
                    result = maxWifiDistance
                }
            }
            group.leave()
        }
        
        task.resume()
        group.wait()
        
        return result
    }
    
    static func sendBenchmarkToServer(benchmark: Benchmark) -> String? {
        let json = benchmark.toJSONDict()
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // Create POST request
        let url = URL(string: BaseResult.collectURLBase + "mptests/create/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Insert JSON data to the request
        request.httpBody = jsonData
        
        var benchmarkUUID: String? = nil
        // FIXME timeout for group
        let group = DispatchGroup()
        group.enter()
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let checkedData = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                if let checkedData = data {
                    let responseJSON = try? JSONSerialization.jsonObject(with: checkedData, options: [])
                    if let responseJSON = responseJSON as? [String: Any] {
                        print(responseJSON)
                    }
                }
                group.leave()
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: checkedData, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                if let uuid = responseJSON["uuid"] as? String {
                    print("Hourra!")
                    benchmarkUUID = uuid
                }
            }
            group.leave()
        }
        
        task.resume()
        group.wait()
        
        return benchmarkUUID
    }
    
    static func sendConnectivitiesToServer(connectivities: [[String: Any]]) {
        let jsonData = try? JSONSerialization.data(withJSONObject: connectivities)
        
        // Create POST request
        let url = URL(string: BaseResult.collectURLBase + "netconnectivities/create/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Insert JSON data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let checkedData = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                if let checkedData = data {
                    let responseJSON = try? JSONSerialization.jsonObject(with: checkedData, options: [])
                    if let responseJSON = responseJSON as? [String: Any] {
                        print(responseJSON)
                    }
                }
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: checkedData, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
        }
        
        task.resume()
    }
    
    static func sendTestToServer(testResult: TestResult, benchmarkUUID: String, order: Int, protoInfo: [[String: Any]], config: [String: Any]) {
        let json = testResult.toJSONDict(benchmarkUUID: benchmarkUUID, order: order, protoInfo: protoInfo, config: config)
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // Create POST request
        var request = URLRequest(url: type(of: testResult).getCollectURL())
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Insert JSON data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let checkedData = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                if let checkedData = data {
                    let responseJSON = try? JSONSerialization.jsonObject(with: checkedData, options: [])
                    if let responseJSON = responseJSON as? [String: Any] {
                        print(responseJSON)
                    }
                }
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: checkedData, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
        }
        
        task.resume()
    }
    
    static func sendToServer(benchmark: Benchmark, tests: [Test]) {
        return sendToServer(benchmark: benchmark, tests: tests, tried: 0)
    }
    
    static func sendToServer(benchmark: Benchmark, tests: [Test], tried: Int) {
        let uuid = Utils.sendBenchmarkToServer(benchmark: benchmark)
        guard let benchmarkUUID = uuid else {
            if tried >= 10 {
                print("Got", tried, "error whem trying to save benchmark; abort")
                return
            }
            print("Got error whem trying to save benchmark; retry in 1 second")
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                group.leave()
            }
            group.wait()
            return sendToServer(benchmark:benchmark, tests:tests, tried: tried+1)
        }
        benchmark.uuid = UUID(uuidString: benchmarkUUID)!
        var connectivities = [[String: Any]]()
        for connectivity in benchmark.connectivities {
            connectivities.append(connectivity.toJSONDict(benchmarkUUID: benchmarkUUID))
        }
        Utils.sendConnectivitiesToServer(connectivities: connectivities)
        for i in 0..<benchmark.testResults.count {
            let testResult = benchmark.testResults[i]
            let test = tests[i]
            let protoInfo = test.getProtoInfo()
            let config = test.getConfigDict()
            Utils.sendTestToServer(testResult: testResult, benchmarkUUID: benchmarkUUID, order: i, protoInfo: protoInfo, config: config)
        }
    }
    
    static func traceroute(toIP: String) {
        let sock = socket(AF_INET6, SOCK_DGRAM, 0)
        var ttl = 1
        setsockopt(sock, IPPROTO_IP, IP_TTL, &ttl, socklen_t(MemoryLayout<Int>.size))
        var buf = "Hello"
        var saddr = sockaddr()
        inet_pton(AF_INET6, "2001:240:168:1001::33", &saddr)
        sendto(sock, &buf, buf.count, 0, &saddr, 16)
    }
}
