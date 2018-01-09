//
//  StaticRunnerViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/9/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Quictraffic
import os.log

class StaticRunnerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var testsTable: UITableView!
    @IBOutlet weak var progress: UICircularProgressRingView!
    
    var startTime: Double = Date().timeIntervalSince1970
    
    var tests: [Test] = [Test]()
    var runningIndex: Int = -1
    
    var internetReachability: Reachability = Reachability.forInternetConnection()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.progress.value = 0.0
        
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(StaticRunnerViewController.reachabilityChanged(note:)), name: .reachabilityChanged, object: nil)
        internetReachability.startNotifier()
        
        Utils.traceroute(toIP: "coucou")
        testsTable.dataSource = self
        testsTable.delegate = self
        
        startTests()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc
    func reachabilityChanged(note: Notification) {
        print("Reachability changed!")
        for i in 0..<tests.count {
            QuictrafficNotifyReachability(tests[i].getNotifyID())
        }
    }
    
    func startTests() {
        startTime = Date().timeIntervalSince1970
        self.navigationItem.hidesBackButton = true
        print("We start the tests")
        
        DispatchQueue.global(qos: .background).async {
            let nbTests = self.tests.count
            var results = [[String:Any]]()
            var testResults = [TestResult]()
            for i in 0..<nbTests {
                let test = self.tests[i]
                self.runningIndex = i
                DispatchQueue.main.async {
                    self.progress.setProgress(value: CGFloat((Float(i) / Float(nbTests) * 100.0)), animationDuration: 0.0) {}
                    self.testsTable.reloadData()
                    self.progress.setProgress(value: CGFloat((Float(i + 1) / Float(nbTests) * 100.0) - 1.0), animationDuration: 10.0) {
                        print("Done animating!")
                        // Do anything your heart desires...
                    }
                }
                results.append(test.run())
            }
            self.runningIndex = nbTests
            DispatchQueue.main.async {
                self.testsTable.reloadData()
            }
            print("send the following to the collect server", results)
            for i in 0..<nbTests {
                let test = self.tests[i]
                testResults.append(test.getTestResult())
                let result = results[i]
                // TODO update serverIP
                Utils.sendTestToCollectServer(test: test, result: result, serverIP: "176.31.249.161", benchStartTime: self.startTime)
            }
            let benchmarkResult = BenchmarkResult(startTime: self.startTime, testResults: testResults)
            self.saveBenchmarkTest(result: benchmarkResult!)
            print("Tests done")
            DispatchQueue.main.async {
                self.progress.setProgress(value: 100.0, animationDuration: 0.2) {}
                self.navigationItem.hidesBackButton = false
            }
        }
    }
    
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
    
    // MARK: Protocols
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "StaticTestTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? StaticTestTableViewCell else {
            fatalError("The dequeued cell is not an instance of StaticTestTableViewCell.")
        }
        
        // Fetches the appropriate meal for the data source layout.
        let test = tests[indexPath.row]
        
        cell.nameLabel.text = test.getDescription()
        // Load images
        let bundle = Bundle(for: type(of: self))
        let okTest = UIImage(named: "ok_test", in: bundle, compatibleWith: self.traitCollection)
        let failedTest = UIImage(named: "failed_test", in: bundle, compatibleWith: self.traitCollection)
        let runningTest = UIImage(named: "running_test", in: bundle, compatibleWith: self.traitCollection)
        let comingTest = UIImage(named: "blank", in: bundle, compatibleWith: self.traitCollection)
        
        if indexPath.row == self.runningIndex {
            cell.resultImageView.image = runningTest
        } else if indexPath.row < self.runningIndex {
            let result = test.getTestResult()
            if result.getResult() == "Failed" {
                cell.resultImageView.image = failedTest
            } else {
                cell.resultImageView.image = okTest
            }
        } else {
            cell.resultImageView.image = comingTest
        }
        
        return cell
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
