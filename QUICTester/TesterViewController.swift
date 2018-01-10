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
    
    var timer: Timer?
    var startTime: Double = Date().timeIntervalSince1970
    
    var tests: [Test] = [Test]()
    
    var internetReachability: Reachability = Reachability.forInternetConnection()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.progressBar.progress = 0.0

        // Do any additional setup after loading the view.
        tests = [
            // TODO add tests to check gQUIC vs. IETF QUIC,...
            QUICConnectivityTest(port: 443, ipVer: .any),
            QUICConnectivityTest(port: 6121, ipVer: .any),
            QUICConnectivityTest(port: 443, ipVer: .v4),
            QUICConnectivityTest(port: 443, ipVer: .v6),
            QUICBulkDownloadTest(urlPath: "10MB", maxPathID: 0, ipVer: .v4),
            QUICBulkDownloadTest(urlPath: "10MB", maxPathID: 0, ipVer: .v6),
            QUICBulkDownloadTest(urlPath: "10MB", maxPathID: 255, ipVer: .any),
            QUICReqResTest(maxPathID: 0, ipVer: .v4),
            QUICReqResTest(maxPathID: 0, ipVer: .v6),
            QUICReqResTest(maxPathID: 255, ipVer: .any),
            QUICPerfTest(maxPathID: 0, ipVer: .v4),
            QUICPerfTest(maxPathID: 0, ipVer: .v6),
            QUICPerfTest(maxPathID: 255, ipVer: .any),
        ]
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.reachabilityChanged(note:)), name: .reachabilityChanged, object: nil)
        internetReachability.startNotifier()
        
        Utils.traceroute(toIP: "coucou")
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
        startTime = Date().timeIntervalSince1970
        sender.isEnabled = false
        print("We start the tests")
        self.timeLabel.text = "0:00"
        timer = Timer(timeInterval: 1.0, target: self, selector: #selector(TesterViewController.getTime), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: RunLoopMode.commonModes)
        
        DispatchQueue.global(qos: .background).async {
            let nbTests = self.tests.count
            var results = [[String:Any]]()
            var testResults = [TestResult]()
            for i in 0..<nbTests {
                let test = self.tests[i]
                DispatchQueue.main.async {
                    self.countLabel.text = String(i + 1) + "/" + String(nbTests)
                    self.testLabel.text = test.getDescription()
                    self.progressBar.progress = Float(i) / Float(nbTests)
                }
                results.append(test.run())
            }
            print("send the following to the collect server", results)
            for i in 0..<nbTests {
                let test = self.tests[i]
                testResults.append(test.getTestResult())
                let result = results[i]
                // TODO update serverIP
                Utils.sendTestToCollectServer(test: test, result: result, serverIP: "176.31.249.161", benchStartTime: self.startTime)
            }
            let benchmarkResult = BenchmarkResult(connectivities: [], startTime: self.startTime, testResults: testResults)
            self.saveBenchmarkTest(result: benchmarkResult)
            print("Tests done")
            self.timer?.invalidate()
            self.timer = nil
            DispatchQueue.main.async {
                self.progressBar.progress = 1.0
                self.testLabel.text = "Done, results are available"
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
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateResult"), object: nil)
        } else {
            os_log("Failed to save results...", log: OSLog.default, type: .error)
        }
    }
    
    // MARK: Timer function
    @objc func getTime() {
        let curTime = Date().timeIntervalSince1970
        let timeDiff = curTime - startTime
        let timeDiffInt = Int(timeDiff)
        
        timeLabel.text = String(format: "%d:%02d", timeDiffInt / 60, timeDiffInt % 60)
    }
}
