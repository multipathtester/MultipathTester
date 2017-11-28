//
//  ViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 9/6/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Quictraffic

import os.log


class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    // MARK: Properties
    @IBOutlet weak var sendingLabel: UILabel!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var protocolPicker: UIPickerView!
    
    var bulkResults = [BulkResult]()
    var reqresResults = [ReqResResult]()
    
    var pickerDataSource = [["Bulk", "Req/Res", "Siri"], ["SinglePath", "MultiPath"], ["TCP", "QUIC"]];
    var selectedProtocol: String = "TCP"
    var multipath: Bool = false
    var traffic: String = "bulk"
    
    var logFileURL: URL = URL(fileURLWithPath: "dummy")
    
    var internetReachability: Reachability = Reachability.forInternetConnection()
    var notifyID: String = ""
    
    @objc
    func reachabilityChanged(note: Notification) {
        print("Coucou")
        QuictrafficNotifyReachability(notifyID)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.protocolPicker.dataSource = self;
        self.protocolPicker.delegate = self;
        
        if let savedBulkResults = loadBulkResults() {
            dump(savedBulkResults)
            bulkResults = savedBulkResults
        }
        
        if let savedReqResResults = loadReqResResults() {
            dump(savedReqResResults)
            reqresResults = savedReqResResults
        }
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            logFileURL = dir.appendingPathComponent("quictraffic.log")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.reachabilityChanged(note:)), name: .reachabilityChanged, object: nil)
        internetReachability.startNotifier()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UIPickerViewDataSource method
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
    
    // MARK: UIPickerViewDelegate methods
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource[component].count;
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            // Modified traffic attribute
            traffic = {
                switch pickerDataSource[component][row] {
                case "Bulk": return "bulk"
                case "Req/Res": return "reqres"
                case "Siri": return "siri"
                default: fatalError("WTF is traffic \(pickerDataSource[component][row])")
                }
            }()
        } else if component == 1 {
            // Modified multipath attribute
            multipath = {
                switch pickerDataSource[component][row] {
                case "SinglePath": return false
                case "MultiPath": return true
                default: fatalError("WTF is \(pickerDataSource[component][row])")
                }
            }()
        } else if component == 2 {
            // Modified protocol attribute
            selectedProtocol = pickerDataSource[component][row]
        }
        return pickerDataSource[component][row]
    }

    // MARK: Actions
    @IBAction func startTestButtonPressed(_ sender: UIButton) {
        // Avoid launching multiples tests in parallel
        sender.isEnabled = false
        
        let selectedProtocol = self.selectedProtocol
        let traffic = self.traffic
        let multipath = self.multipath
        let startTime = Date().timeIntervalSince1970
        
        print("Starting with \(selectedProtocol) with traffic \(traffic) and multipath \(multipath)")
        
        switch selectedProtocol {
        case "TCP":
            DispatchQueue.global(qos: .background).async {
                let (bench, result) = self.TCPTest(traffic: traffic, multipath: multipath, startTime: startTime)
                // FIXME: Hardcoded serverIP
                self.sendTestToCollectServer(config: multipath ? "MPTCP": "SPTCP", startTime: startTime, serverIP: "5.196.169.232", info: [], bench: bench, result: result)
                
                DispatchQueue.main.async {
                    // Show the result to the user
                    self.resultLabel.text = "TCP: Done"
                    // Then reactivate the button
                    sender.isEnabled = true
                }
            }
        case "QUIC":
            // Run the network test in background, then do the UI changes on main thread
            DispatchQueue.global(qos: .background).async {
                let (bench, result) = self.QUICTest(traffic: traffic, multipath: multipath, startTime: startTime)
                let quicInfo = self.collectQUICInfoAndDeleteLogFile()
                // FIXME: Hardcoded serverIP
                self.sendTestToCollectServer(config: multipath ? "MPQUIC": "SPQUIC", startTime: startTime, serverIP: "176.31.249.161", info: quicInfo, bench: bench, result: result)
                
                DispatchQueue.main.async {
                    // Show the result to the user
                    self.resultLabel.text = "QUIC: Done"
                    // Then reactivate the button
                    sender.isEnabled = true
                }
            }
        default: fatalError("WTF is \(self.selectedProtocol)")
        }
    }
    
    // MARK: Others
    func resolveURL(url: String) {
        let host = CFHostCreateWithName(nil, url as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        var success: DarwinBoolean = false
        if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray?,
            let theAddress = addresses.firstObject as? NSData {
            var hostname = [CChar](repeating:0, count: Int(NI_MAXHOST))
            if getnameinfo(theAddress.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(theAddress.length), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                let numAddress = String(cString: hostname)
                print(numAddress)
            }
        }
    }
    
    func TCPTest(traffic: String, multipath: Bool, startTime: Double) -> ([String: Any], [String: Any]) {
        switch traffic {
        case "bulk":
            let res = TCPClientBulk(multipath: multipath, url: "http://5.196.169.232/testing_handover_20MB").Run()
            return saveBulkAndGetJsons(startTime: startTime, networkProtocol: "TCP", multipath: multipath, fileName: "testing_handover_20MB",
                                  serverURL: "http://5.196.169.232/testing_handover_20MB", durationSecond: res["time"] as! Double)
        case "reqres":
            let (runTime, missed, delays) = TCPClientReqRes(multipath: multipath, url: "http://5.196.169.232:8008/").Run()
            return saveReqResAndGetJsons(startTime: startTime, networkProtocol: "TCP", multipath: multipath, runTime: runTime, missed: missed, delays: delays)
        case "siri":
            print(TCPClientSiri(multipath: multipath, addr: "5.196.169.232:8080").Run())
            return ([:], [:])
        default: fatalError("WTF is \(traffic)")
        }
    }
    
    func QUICTest(traffic: String, multipath: Bool, startTime: Double) -> ([String: Any], [String: Any]) {
        createLogFile()
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let date = Date()
        notifyID = dateFormatter.string(from: date)
        print(notifyID)
        switch traffic {
        case "bulk":
            let durationString = QuictrafficRun(traffic, true, multipath ? 2 : 0, logFileURL.absoluteString, "", "https://ns387496.ip-176-31-249.eu:6121/random3", notifyID)
            var duration: Double
            // Be cautious about the formatting of the durationString
            if durationString?.range(of: "ms") != nil {
                duration = Double(durationString!.components(separatedBy: "ms")[0])! / 1000
            } else if durationString?.range(of: "m") != nil {
                let splitted = durationString!.components(separatedBy: "m")
                duration = Double(splitted[0])! * 60 + Double(splitted[1].components(separatedBy: "s")[0])!
            } else {
                duration = Double(durationString!.components(separatedBy: "s")[0])!
            }
            return saveBulkAndGetJsons(startTime: startTime, networkProtocol: "QUIC", multipath: multipath, fileName: "random",
                                       serverURL: "https://ns387496.ip-176-31-249.eu:6121/random", durationSecond: duration)
        case "reqres":
            let resultString = QuictrafficRun(traffic, true, multipath ? 2 : 0, logFileURL.absoluteString, "", "ns387496.ip-176-31-249.eu:8775", notifyID)
            var sawFirstLine = false
            let runTime: Double = 30.0
            var missed: Int = -1
            var delays = [Int]()
            resultString?.enumerateLines { line, _ in
                if sawFirstLine {
                    if line.range(of: "Missed:") != nil {
                        missed = Int(line.components(separatedBy: " ")[1])!
                    } else {
                        delays.append(Int(line)!)
                    }
                }
                sawFirstLine = true
            }
            return saveReqResAndGetJsons(startTime: startTime, networkProtocol: "QUIC", multipath: multipath, runTime: runTime, missed: missed, delays: delays)
        case "siri":
            // TODO
            print(QuictrafficRun(traffic, true, multipath ? 2 : 0, logFileURL.absoluteString, "", "ns387496.ip-176-31-249.eu:8776", notifyID))
            return ([:], [:])
        default: fatalError("")
        }
    }
    
    // MARK: Private
    private func createLogFile() {
        do {
            try "".write(to: logFileURL, atomically: false, encoding: .utf8)
        }
        catch {}
    }
    
    private func loadBulkResults() -> [BulkResult]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: BulkResult.ArchiveURL.path) as? [BulkResult]
    }
    
    private func saveBulkResults() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(bulkResults, toFile: BulkResult.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("BulkResults successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save bulk results...", log: OSLog.default, type: .error)
        }
    }
    
    private func saveBulkAndGetJsons(startTime: Double, networkProtocol: String, multipath: Bool, fileName: String, serverURL: String, durationSecond: Double) -> ([String: Any], [String: Any]) {
        let bulkResult = BulkResult(startTime: startTime, networkProtocol: networkProtocol, multipath: multipath, durationNs: Int64(durationSecond * 1_000_000_000))
        bulkResults.append(bulkResult)
        saveBulkResults()
        let bench: [String: Any] = [
            "name": "simple_http_get",
            "config": [
                "file_name": fileName,
                "server_url": serverURL,
            ],
        ]
        let result: [String: Any] = [
            "netcfgs": [],
            "run_time": String(format: "%.9f", durationSecond),
        ]
        return (bench, result)
    }
    
    private func loadReqResResults() -> [ReqResResult]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: ReqResResult.ArchiveURL.path) as? [ReqResResult]
    }
    
    private func saveReqResResults() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(reqresResults, toFile: ReqResResult.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("ReqResResults successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save reqres results...", log: OSLog.default, type: .error)
        }
    }
    
    private func saveReqResAndGetJsons(startTime: Double, networkProtocol: String, multipath: Bool, runTime: Double, missed: Int, delays: [Int]) -> ([String: Any], [String: Any]) {
        let reqresResult = ReqResResult(startTime: startTime, networkProtocol: networkProtocol, multipath: multipath, durationNs: Int64(runTime * 1_000_000_000),
                                        missed: missed, delays: delays)
        reqresResults.append(reqresResult)
        saveReqResResults()
        let bench: [String: Any] = [
            "name": "msg",
            "config": [
                "server_port": "8008",
                "query_size": "750",
                "response_size": "750",
                "start_delay_query_response": "0",
                "nb_msgs": "60",
                "timeout_sec": "30",
            ],
            ]
        let result: [String: Any] = [
            "delays": delays,
            "missed": missed,
            "netcfgs": [],
            "run_time": String(format: "%.9f", runTime),
            ]
        return (bench, result)
    }
    
    private func collectQUICInfoAndDeleteLogFile() -> [Any] {
        var array = [Any]()
        do {
            let text = try String(contentsOf: logFileURL, encoding: .utf8)
            let lines = text.components(separatedBy: .newlines)
            for line in lines {
                print(line)
                let data = line.data(using: .utf8)
                let json = try? JSONSerialization.jsonObject(with: data!, options: [])
                if (json != nil) {
                    array.append(json!)
                }
            }
            try FileManager.default.removeItem(at: logFileURL)
        } catch { print("Nope...")}
        return array
    }
    
    private func sendTestToCollectServer(config: String, startTime: Double, serverIP: String, info: [Any], bench: [String: Any], result: [String: Any]) {
        // FIXME: no need now because hardcoded, but might be needed later
        // self.resolveURL()
        DispatchQueue.main.async {
            self.sendingLabel.text = "Trying to send..."
        }
        let json: [String: Any] = [
            "bench": bench,
            "config_name": config,
            "device_id": UIDevice.current.identifierForVendor!.uuidString,
            "proto_info": info,
            "result": result,
            "server_ip": serverIP,
            "smartphone": true,
            "start_time": startTime,
            ]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // Create POST request
        let url = URL(string: "https://ns387496.ip-176-31-249.eu/collect/save_test/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Insert JSON data to the request
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.sendingLabel.text = error?.localizedDescription ?? "No data"
                }
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
                DispatchQueue.main.async {
                    self.sendingLabel.text = responseJSON.debugDescription
                }
            }
        }
        
        task.resume()
    }
}

