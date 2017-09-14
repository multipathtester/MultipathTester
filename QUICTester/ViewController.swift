//
//  ViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 9/6/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Quictraffic

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    // MARK: Properties
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var protocolPicker: UIPickerView!
    
    var pickerDataSource = [["Bulk", "Req/Res", "Siri"], ["SinglePath", "MultiPath"], ["TCP", "QUIC"]];
    var selectedProtocol: String = "TCP"
    var multipath: Bool = false
    var traffic: String = "bulk"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.protocolPicker.dataSource = self;
        self.protocolPicker.delegate = self;
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
        
        print("Starting with \(selectedProtocol) with traffic \(traffic) and multipath \(multipath)")
        
        switch self.selectedProtocol {
        case "TCP":
            DispatchQueue.global(qos: .background).async {
                let res = self.TCPTest()
                print("Result is \(String(describing: res))")
                
                DispatchQueue.main.async {
                    // Show the result to the user
                    self.resultLabel.text = "TCP: " + res
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
    func TCPTest() -> String {
        switch traffic {
        case "bulk": return TCPClientBulk(multipath: multipath, url: "http://5.196.169.232/testing_handover_20MB").Run()
        case "reqres":
            let (missed, delays) = TCPClientReqRes(multipath: multipath, url: "http://5.196.169.232:8008/").Run()
            return "\(missed) " + delays.map({"\($0)"}).joined(separator: ",")
        case "siri": return TCPClientSiri(multipath: multipath, addr: "5.196.169.232:8080").Run()
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
}

