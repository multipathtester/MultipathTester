//
//  StaticRunnerViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/9/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import CoreLocation
import UIKit
import Quictraffic
import os.log

class StaticRunnerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var testsTable: UITableView!
    @IBOutlet weak var progress: UICircularProgressRingView!
    
    var startTime: Date = Date()
    var stopTime: Date = Date()
    
    var tests: [Test] = [Test]()
    var runningIndex: Int = -1
    
    var internetReachability: Reachability = Reachability.forInternetConnection()
    var locationTracker: LocationTracker = LocationTracker.sharedTracker()
    var locations: [Location] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = locationTracker.startIfAuthorized()
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(StaticRunnerViewController.locationChanged(note:)), name: LocationTracker.LocationTrackerNotification, object: nil)
        
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
        print("Reachability changed! In static tests, this should abort the test!")
        for i in 0..<tests.count {
            QuictrafficNotifyReachability(tests[i].getNotifyID())
        }
    }
    
    @objc
    func locationChanged(note: Notification) {
        let info = note.userInfo
        guard let locations = info!["locations"] as? [CLLocation] else {
            return
        }
        for cl in locations {
            let location = Location(lon: cl.coordinate.longitude, lat: cl.coordinate.latitude, timestamp: cl.timestamp, accuracy: cl.horizontalAccuracy, altitude: cl.altitude, speed: cl.speed)
            self.locations.append(location)
        }
    }
    
    func startTests() {
        let reachabilityStatus = internetReachability.currentReachabilityStatus()
        var connectivities = [Connectivity]()
        if reachabilityStatus == ReachableViaWiFi {
            connectivities.append(Connectivity(networkType: .WiFi, networkName: "WiFi Network Name", timestamp: Date().timeIntervalSince1970))
        } else if reachabilityStatus == ReachableViaWWAN {
            connectivities.append(Connectivity(networkType: .Cellular, networkName: "Cellular Network Name", timestamp: Date().timeIntervalSince1970))
        }
        startTime = Date()
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
            self.stopTime = Date()
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
                Utils.sendTestToCollectServer(test: test, result: result, serverIP: "176.31.249.161", benchStartTime: self.startTime.timeIntervalSince1970)
            }
            let duration = self.stopTime.timeIntervalSince(self.startTime)
            // FIXME
            let benchmark = Benchmark(connectivities: connectivities, duration: duration, locations: self.locations, pingMean: 0.1, pingVar: 0.05, serverName: "FR", startTime: self.startTime, testResults: testResults)
            self.saveBenchmark(benchmark: benchmark)
            print("Tests done")
            DispatchQueue.main.async {
                self.progress.setProgress(value: 100.0, animationDuration: 0.2) {}
                self.navigationItem.hidesBackButton = false
            }
        }
    }
    
    // MARK: Private
    private func saveBenchmark(benchmark: Benchmark) {
        var benchmarks: [Benchmark] = [Benchmark]()
        if let benchmarksOk = Benchmark.loadBenchmarks() {
            benchmarks = benchmarksOk
        }
        // Add the new result at the top of the list
        benchmarks = [benchmark] + benchmarks
        // And save the results
        do {
            let data = try PropertyListEncoder().encode(benchmarks)
            let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(data, toFile: Benchmark.ArchiveURL.path)
            if isSuccessfulSave {
                os_log("Benchmarks successfully saved.", log: OSLog.default, type: .debug)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateResult"), object: nil)
            } else {
                os_log("Failed to save benchmarks...", log: OSLog.default, type: .error)
            }
        } catch {
            os_log("Failed to save benchmarks...", log: OSLog.default, type: .error)
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
