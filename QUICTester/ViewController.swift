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
    
    var pickerDataSource = ["TCP", "QUIC"];
    var selectedProtocol: String = "TCP"
    
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
        return 1
    }
    
    // MARK: UIPickerViewDelegate methods
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count;
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        selectedProtocol = pickerDataSource[row]
        return pickerDataSource[row]
    }

    // MARK: Actions
    @IBAction func startTestButtonPressed(_ sender: UIButton) {
        // Avoid launching multiples tests in parallel
        sender.isEnabled = false
        
        print("Starting with \(selectedProtocol)")
        
        switch self.selectedProtocol {
        case "TCP": TCPTest(sender: sender, multipath: false, url: "http://5.196.169.232/testing_handover_20MB")
        case "QUIC":
            // Run the network test in background, then do the UI changes on main thread
            DispatchQueue.global(qos: .background).async {
                let res = QuictrafficRun("bulk", true, true, "", "https://ns387496.ip-176-31-249.eu:6121/random")
                print("End with time \(String(describing: res))")
                
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
    func TCPTest(sender: UIButton, multipath: Bool, url: String) {
        let config = URLSessionConfiguration.ephemeral
        
        if multipath {
            config.multipathServiceType = URLSessionConfiguration.MultipathServiceType.aggregate
        }
        let session = URLSession(configuration: config)
        
        let url = URL(string: url)
        
        let start = DispatchTime.now()
        let task = session.dataTask(with: url!) { (data, resp, error) in
            guard error == nil && data != nil else {
                // Only modify the UI on the main thread
                DispatchQueue.main.async {
                    // Show the result to the user
                    self.resultLabel.text = "TCP: \(String(describing: error))"
                    // Then reactivate the button
                    sender.isEnabled = true
                }
                return
            }
            guard resp != nil else {
                // Only modify the UI on the main thread
                DispatchQueue.main.async {
                    // Show the result to the user
                    self.resultLabel.text = "TCP: received no response"
                    // Then reactivate the button
                    sender.isEnabled = true
                }
                return
            }
            let length = CGFloat((resp?.expectedContentLength)!) / 1000000.0
            let elapsed = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
            let timeInterval = Double(elapsed) / 1_000_000_000
            
            // Only modify the UI on the main thread
            DispatchQueue.main.async {
                // Show the result to the user
                self.resultLabel.text = "TCP: \(timeInterval)s for \(length) MB"
                // Then reactivate the button
                sender.isEnabled = true
            }
        }
        task.resume()
    }
}

