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
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var protocolPicker: UIPickerView!
    
    var bulkResults = [BulkResult]()
    var reqresResults = [ReqResResult]()
    
    var pickerDataSource = [["Bulk", "Req/Res", "Siri"], ["SinglePath", "MultiPath"], ["TCP", "QUIC"]];
    var selectedProtocol: String = "TCP"
    var multipath: Bool = false
    var traffic: String = "bulk"
    
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
        
        switch self.selectedProtocol {
        case "TCP":
            DispatchQueue.global(qos: .background).async {
                let (bench, result) = self.TCPTest()
                print("Result is \(String(describing: result))")
                
                // FIXME: no need now because hardcoded, but might be needed later
                // self.resolveURL()
                let json: [String: Any] = [
                    "bench": bench,
                    "config_name": multipath ? "MPTCP": "SPTCP",
                    "device_id": UIDevice.current.identifierForVendor!.uuidString,
                    "result": result,
                    "server_ip": "5.196.169.232",
                    "smartphone": true,
                    "start_time": startTime,
                ]
                print(json)
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
                let res = self.QUICTest()
                print("Result is \(String(describing: res))")
                
                DispatchQueue.main.async {
                    // Show the result to the user
                    self.resultLabel.text = "QUIC: " + res!
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
    
    func TCPTest() -> ([String: Any], [String: Any]) {
        let startTime = Date().timeIntervalSince1970
        let multipath = self.multipath
        switch traffic {
        case "bulk":
            let durationSecond = TCPClientBulk(multipath: multipath, url: "http://5.196.169.232/testing_handover_20MB").Run()
            let bulkResult = BulkResult(startTime: startTime, networkProtocol: "TCP", multipath: multipath, durationNs: Int64(durationSecond * 1_000_000_000))
            bulkResults.append(bulkResult)
            saveBulkResults()
            let bench: [String: Any] = [
                "name": "simple_http_get",
                "config": [
                    "file_name": "testing_handover_20MB",
                    "server_url": "http://5.196.169.232/testing_handover_20MB",
                ],
            ]
            let result: [String: Any] = [
                "netcfgs": [],
                "run_time": String(format: "%.9f", durationSecond),
            ]
            return (bench, result)
        case "reqres":
            let (runTime, missed, delays) = TCPClientReqRes(multipath: multipath, url: "http://5.196.169.232:8008/").Run()
            let reqresResult = ReqResResult(startTime: startTime, networkProtocol: "TCP", multipath: multipath, durationNs: Int64(runTime * 1_000_000_000),
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
        case "siri":
            print(TCPClientSiri(multipath: multipath, addr: "5.196.169.232:8080").Run())
            return ([:], [:])
        default: fatalError("WTF is \(traffic)")
        }
    }
    
    func QUICTest() -> String? {
        let url: String = {
            switch self.traffic {
            case "bulk": return "https://ns387496.ip-176-31-249.eu:6121/random"
            case "reqres": return "ns387496.ip-176-31-249.eu:8775"
            case "siri": return "ns387496.ip-176-31-249.eu:8776"
            default: fatalError("WTF is traffic \(self.traffic)")
            }
        }()
        return QuictrafficRun(traffic, true, multipath, "", url)
    }
    
    // MARK: Private
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
}

