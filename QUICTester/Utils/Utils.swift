//
//  Utils.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 11/29/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class Utils {
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
    
    static func sendTestToCollectServer(test: Test, config: String, result: [String:Any], serverIP: String, info: [String:Any]?) {
        var json: [String: Any] = [
            "bench": test.getBenchDict(),
            "config_name": config,
            "device_id": UIDevice.current.identifierForVendor!.uuidString,
            "result": result,
            "server_ip": serverIP,
            "smartphone": true,
            "start_time": test.getStartTime(),
        ]
        if info != nil {
            json["proto_info"] = info!
        }
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // Create POST request
        let url = URL(string: "https://ns387496.ip-176-31-249.eu/collect/save_test/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Insert JSON data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
        }
        
        task.resume()
    }
}
