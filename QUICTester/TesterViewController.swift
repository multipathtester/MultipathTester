//
//  TesterViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 11/28/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import os.log

import Quictraffic

class TesterViewController: UIViewController {

    // MARK: Properties
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var testLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    
    var tests: [Test] = [Test]()
    
    var internetReachability: Reachability = Reachability.forInternetConnection()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.progressBar.progress = 0.0

        // Do any additional setup after loading the view.
        tests = [
            // TODO add tests to check gQUIC vs. IETF QUIC, v4 vs. v6,...
            QUICConnectivityTest(port: 443, ipVer: .any),
            QUICConnectivityTest(port: 6121, ipVer: .any),
            QUICConnectivityTest(port: 443, ipVer: .v4),
            QUICConnectivityTest(port: 443, ipVer: .v6),
        ]
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.reachabilityChanged(note:)), name: .reachabilityChanged, object: nil)
        internetReachability.startNotifier()
    }
    
    @objc
    func reachabilityChanged(note: Notification) {
        print("Reachability changed!")
        for i in 0..<tests.count {
            QuictrafficNotifyReachability(tests[i].getNotifyID())
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    @IBAction func startTests(_ sender: UIButton) {
        let startTime = Date().timeIntervalSince1970
        sender.isEnabled = false
        print("We start the tests")
        
        DispatchQueue.global(qos: .background).async {
            let nbTests = self.tests.count
            var results = [[String:Any]]()
            var testResults = [TestResult]()
            var quicInfos = [[[String: Any]]]()
            for i in 0..<nbTests {
                let test = self.tests[i]
                DispatchQueue.main.async {
                    self.countLabel.text = String(i + 1) + "/" + String(nbTests)
                    self.timeLabel.text = "0:00"
                    self.testLabel.text = test.getDescription()
                    self.progressBar.progress = Float(i) / Float(nbTests)
                }
                results.append(test.run())
                quicInfos.append(test.getQUICInfo())
            }
            print("send the following to the collect server", results)
            for i in 0..<nbTests {
                let test = self.tests[i]
                testResults.append(test.getTestResult())
                let result = results[i]
                let quicInfo = quicInfos[i]
                // TODO update config, serverIP and info
                Utils.sendTestToCollectServer(test: test, config: "QUIC", result: result, serverIP: "176.31.249.161", info: quicInfo)
            }
            let benchmarkResult = BenchmarkResult(startTime: startTime, testResults: testResults)
            self.saveBenchmarkTest(result: benchmarkResult!)
            print("Tests done")
            DispatchQueue.main.async {
                self.progressBar.progress = 1.0
                self.testLabel.text = "Done"
                sender.isEnabled = true
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: Private
    private func saveBenchmarkTest(result: BenchmarkResult) {
        var results: [BenchmarkResult] = [BenchmarkResult]()
        if let resultsOk = NSKeyedUnarchiver.unarchiveObject(withFile: BenchmarkResult.ArchiveURL.path) as? [BenchmarkResult] {
            results = resultsOk
        }
        // Add the new result at the top of the list
        results = [result] + results
        // And save the results
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(results, toFile: BenchmarkResult.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Results successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save results...", log: OSLog.default, type: .error)
        }
    }
}
