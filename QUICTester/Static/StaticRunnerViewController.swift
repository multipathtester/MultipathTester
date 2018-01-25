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

class StaticRunnerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var testsTable: UITableView!
    @IBOutlet weak var progress: UICircularProgressRingView!
    
    var startTime: Date = Date()
    var stopTime: Date = Date()
    
    var tests: [Test] = [Test]()
    var runningIndex: Int = -1
    var stoppedIndex: Int = -1
    
    var internetReachability: Reachability = Reachability.forInternetConnection()
    var locationTracker: LocationTracker = LocationTracker.sharedTracker()
    var locations: [Location] = []
    
    // Reachability does not warn about the cellular state if WiFi is on...
    var wasCellularOn: Bool = false
    var cellTimer: Timer?
    var stoppedTests: Bool = false
    
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
        
        locations = []
        
        NotificationCenter.default.post(name: Utils.TestsLaunchedNotification, object: nil, userInfo: ["startNewTestsEnabled": false])
        
        NotificationCenter.default.addObserver(self, selector: #selector(StaticRunnerViewController.reachabilityChanged(note:)), name: .reachabilityChanged, object: nil)
        internetReachability.startNotifier()
        
        NotificationCenter.default.addObserver(self, selector: #selector(StaticRunnerViewController.locationChanged(note:)), name: LocationTracker.LocationTrackerNotification, object: nil)
        
        locationTracker.forceUpdate()
        
        Utils.traceroute(toIP: "coucou")
        testsTable.dataSource = self
        testsTable.delegate = self
        
        startTests()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func stopTests() {
        self.stoppedTests = true
        self.stoppedIndex = self.runningIndex
        let alert = UIAlertController(title: "Test interrupted!", message: "The tests stopped because network conditions changed. If you want to evaluate mobile cases, please try mobile tests.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc
    func reachabilityChanged(note: Notification) {
        print("Reachability changed! In static tests, this should abort the test!")
        for i in 0..<tests.count {
            QuictrafficNotifyReachability(tests[i].getNotifyID())
        }
        stopTests()
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
        var connectivities = [Connectivity]()
        let reachabilityStatus = internetReachability.currentReachabilityStatus()
        wasCellularOn = UIDevice.current.hasCellularConnectivity
        connectivities.append(Connectivity.getCurrentConnectivity(reachabilityStatus: reachabilityStatus))
        startTime = Date()
        self.navigationItem.hidesBackButton = true
        cellTimer = Timer(timeInterval: 0.5, target: self, selector: #selector(StaticRunnerViewController.probeCellular), userInfo: nil, repeats: true)
        RunLoop.current.add(cellTimer!, forMode: .commonModes)
        print("We start the tests")
        
        DispatchQueue.global(qos: .background).async {
            let nbTests = self.tests.count
            var testDones = 0
            for i in 0..<nbTests {
                let test = self.tests[i]
                DispatchQueue.main.async {
                    self.progress.setProgress(value: CGFloat((Float(i) / Float(nbTests) * 100.0)), animationDuration: 0.0) {}
                    self.runningIndex = i
                    self.testsTable.reloadData()
                    self.progress.setProgress(value: CGFloat((Float(i + 1) / Float(nbTests) * 100.0) - 1.0), animationDuration: 10.0) {
                        print("Done animating!")
                        // Do anything your heart desires...
                    }
                }
                if self.stoppedTests {
                    break
                }
                _ = test.run()
                testDones += 1
                if self.stoppedTests {
                    break
                }
            }
            self.stopTime = Date()
            self.runningIndex = testDones
            var testResults = [TestResult]()
            for i in 0..<testDones {
                let test = self.tests[i]
                let result = test.getTestResult()
                if self.stoppedTests && i == testDones - 1 {
                    result.setFailedByNetworkChange()
                }
                testResults.append(result)
            }
            DispatchQueue.main.async {
                self.testsTable.reloadData()
            }
            let duration = self.stopTime.timeIntervalSince(self.startTime)
            // FIXME
            let benchmark = Benchmark(connectivities: connectivities, duration: duration, locations: self.locations, mobile: false, pingMean: 0.1, pingVar: 0.05, serverName: "FR", startTime: self.startTime, testResults: testResults)
            Utils.sendToServer(benchmark: benchmark, tests: self.tests)
            benchmark.save()
            self.cellTimer?.invalidate()
            self.cellTimer = nil
            print("Tests done")
            NotificationCenter.default.post(name: Utils.TestsLaunchedNotification, object: nil, userInfo: ["startNewTestsEnabled": true])
            DispatchQueue.main.async {
                self.progress.setProgress(value: 100.0, animationDuration: 0.2) {}
                self.navigationItem.hidesBackButton = false
            }
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
        
        if indexPath.row == self.runningIndex && !stoppedTests {
            cell.resultImageView.image = runningTest
        } else if indexPath.row < self.runningIndex {
            let result = test.getTestResult()
            if result.succeeded() && indexPath.row != stoppedIndex {
                cell.resultImageView.image = okTest
            } else {
                cell.resultImageView.image = failedTest
            }
        } else {
            cell.resultImageView.image = comingTest
        }
        
        return cell
    }
    
    @objc
    func probeCellular() {
        let cellStatus = UIDevice.current.hasCellularConnectivity
        if cellStatus != wasCellularOn {
            stopTests()
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

}
