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
    
    var pingTests = [TCPConnectivityTest]()
    var tests: [Test] = [Test]()
    var allTests: [Test] = [Test]()
    var runningIndex: Int = -1
    var stoppedIndex: Int = -1
    
    var internetReachability: Reachability = Reachability.forInternetConnection()
    var locationTracker: LocationTracker = LocationTracker.sharedTracker()
    var locations: [Location] = []
    var connectivities = [Connectivity]()
    
    // Reachability does not warn about the cellular state if WiFi is on...
    var wasCellularOn: Bool = false
    var cellTimer: Timer?
    var stoppedTests: Bool = false
    
    // Value come from StaticMainViewController
    var aggregate: Bool = false
    
    // Detect app going to background
    var backgrounded = false
    
    var multipathService: RunConfig.MultipathServiceType = .aggregate
    
    //var debugCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = locationTracker.startIfAuthorized()
        self.progress.value = 0.0
        
        pingTests = [
            // Zero ping count because pingOne after
            TCPConnectivityTest(ipVer: .any, port: 443, testServer: .fr, pingCount: 0, pingWaitMs: 200),
            TCPConnectivityTest(ipVer: .any, port: 443, testServer: .ca, pingCount: 0, pingWaitMs: 200),
            TCPConnectivityTest(ipVer: .any, port: 443, testServer: .jp, pingCount: 0, pingWaitMs: 200),
        ]
        
        // This randomize the order of the pings, to avoid correlating traffic too much
        pingTests.shuffle()
        
        // Do any additional setup after loading the view.
        tests = [
            // TODO add tests to check gQUIC vs. IETF QUIC,...
            QUICConnectivityTest(ipVer: .any, port: 6121),
            QUICConnectivityTest(ipVer: .v4, port: 443),
            QUICConnectivityTest(ipVer: .v6, port: 443),
            //TCPConnectivityTest(ipVer: .v4, port: 443),
            //TCPConnectivityTest(ipVer: .v6, port: 443),
            QUICBulkDownloadTest(ipVer: .v4, urlPath: "/10MB", maxPathID: 0),
            QUICBulkDownloadTest(ipVer: .v6, urlPath: "/10MB", maxPathID: 0),
            QUICBulkDownloadTest(ipVer: .any, urlPath: "/10MB", maxPathID: 255),
            //TCPBulkDownloadTest(ipVer: .v4, urlPath: "/10MB", multipath: false),
            //TCPBulkDownloadTest(ipVer: .v6, urlPath: "/10MB", multipath: false),
            TCPBulkDownloadTest(ipVer: .any, urlPath: "/10MB", multipath: true),
            QUICStreamTest(ipVer: .v4, maxPathID: 0, runTime: 7),
            QUICStreamTest(ipVer: .v6, maxPathID: 0, runTime: 7),
            QUICStreamTest(ipVer: .any, maxPathID: 255, runTime: 7),
            //TCPStreamTest(ipVer: .v4, runTime: 7, multipath: false),
            //TCPStreamTest(ipVer: .v6, runTime: 7, multipath: false),
            TCPStreamTest(ipVer: .any, runTime: 7, multipath: true),
            QUICPerfTest(ipVer: .v4, maxPathID: 0),
            QUICPerfTest(ipVer: .v6, maxPathID: 0),
            QUICPerfTest(ipVer: .any, maxPathID: 255),
            //TCPPerfTest(ipVer: .v4, multipath: false),
            //TCPPerfTest(ipVer: .v6, multipath: false),
            TCPPerfTest(ipVer: .any, multipath: true),
        ]
        
        tests.shuffle()
        
        allTests = pingTests + tests
        
        multipathService = .handover
        if aggregate {
            multipathService = .aggregate
        }
        for t in allTests {
            t.setMultipathService(service: multipathService)
        }
        
        locations = []
        
        // Start observing app going to background notifications
        NotificationCenter.default.addObserver(self, selector: #selector(MobileRunnerViewController.applicationDidSwitchToBackground(note:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)

        
        NotificationCenter.default.post(name: Utils.TestsLaunchedNotification, object: nil, userInfo: ["startNewTestsEnabled": false])
        
        NotificationCenter.default.addObserver(self, selector: #selector(StaticRunnerViewController.reachabilityChanged(note:)), name: .reachabilityChanged, object: nil)
        internetReachability.startNotifier()
        
        NotificationCenter.default.addObserver(self, selector: #selector(StaticRunnerViewController.locationChanged(note:)), name: LocationTracker.LocationTrackerNotification, object: nil)
        
        locationTracker.forceUpdate()
        
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
        if backgrounded {
            let alert = UIAlertController(title: "Test interrupted!", message: "The tests stopped because the application backgrounded.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Test interrupted!", message: "The tests stopped because network conditions changed. If you want to evaluate mobile cases, please try mobile tests.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: App state tracking
    @objc
    func applicationDidSwitchToBackground(note: Notification) {
        backgrounded = true
        stopTests()
    }
    
    @objc
    func reachabilityChanged(note: Notification) {
        let reachabilityStatus = internetReachability.currentReachabilityStatus()
        let conn = Connectivity.getCurrentConnectivity(reachabilityStatus: reachabilityStatus)
        if conn.networkType != connectivities[0].networkType || (conn.wifiBSSID != nil && conn.wifiBSSID != connectivities[0].wifiBSSID) {
            connectivities.append(conn)
            print("Reachability changed!")
            for i in 0..<tests.count {
                QuictrafficNotifyReachability(tests[i].getNotifyID())
            }
            stopTests()
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
        UIApplication.shared.isIdleTimerDisabled = true
        connectivities = [Connectivity]()
        let reachabilityStatus = internetReachability.currentReachabilityStatus()
        wasCellularOn = UIDevice.current.hasCellularConnectivity
        connectivities.append(Connectivity.getCurrentConnectivity(reachabilityStatus: reachabilityStatus))
        let wifiInfoStart = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        let cellInfoStart = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        startTime = Date()
        self.navigationItem.hidesBackButton = true
        cellTimer = Timer(timeInterval: 0.5, target: self, selector: #selector(StaticRunnerViewController.probeCellular), userInfo: nil, repeats: true)
        RunLoop.current.add(cellTimer!, forMode: .commonModes)
        print("We start the tests")
        
        DispatchQueue.global(qos: .userInteractive).async {
            let nbTests = self.pingTests.count + self.tests.count
            var testDones = 0
            var bestServer: TestServer = .fr
            var bestMed: Double = Double.greatestFiniteMagnitude
            var bestStd: Double = Double.greatestFiniteMagnitude
            
            let queue = OperationQueue()
            let group = DispatchGroup()
            
            for i in 0..<self.pingTests.count {
                let test = self.pingTests[i]
                group.enter()
                queue.addOperation {
                    _ = test.run()
                    group.leave()
                }
            }
            DispatchQueue.main.async {
                self.progress.setProgress(value: CGFloat(0.0), animationDuration: 0.0) {}
                self.testsTable.reloadData()
                self.progress.setProgress(value: CGFloat((Float(self.pingTests.count) / Float(nbTests) * 100.0 / 6)), animationDuration: 1.0) {}
            }
            group.wait()
            
            let pingCount = 5
            for pc in 0..<pingCount {
                DispatchQueue.main.async {
                    self.testsTable.reloadData()
                    let fixPart: CGFloat = CGFloat(Float(self.pingTests.count) / Float(nbTests) * 100.0) / 6
                    let mobilePart: CGFloat = CGFloat(Float(pc) + 1.0)
                    self.progress.setProgress(value: fixPart * mobilePart, animationDuration: 1.0) {}
                }
                for i in 0..<self.pingTests.count {
                    let test = self.pingTests[i]
                    let succeeded = test.result["success"] as? Bool ?? false
                    if succeeded {
                        group.enter()
                        queue.addOperation {
                            _ = test.runOnePing()
                            group.leave()
                        }
                    }
                }
                group.wait()
                // Wait for 100 ms before next burst
                usleep(100 * 1000)
            }
            testDones += self.pingTests.count
            for i in 0..<self.pingTests.count {
                let test = self.pingTests[i]
                let res = test.result
                let success = res["success"] as? Bool ?? false
                let durations = res["durations"] as? [Double] ?? []
                if success && durations.count == pingCount {
                    let median = durations.median()
                    print("median duration of", test.getTestServer(), "is", median)
                    if median >= 0.0 && median < bestMed {
                        bestServer = test.getTestServer()
                        bestMed = median
                        bestStd = durations.standardDeviation()
                    }
                }
            }
            
            print("Best server is", bestServer)
            for i in 0..<self.tests.count {
                let test = self.tests[i]
                test.setTestServer(testServer: bestServer)
            }
            for i in 0..<self.tests.count {
                let test = self.tests[i]
                DispatchQueue.main.async {
                    self.progress.setProgress(value: CGFloat((Float(i + self.pingTests.count) / Float(nbTests) * 100.0)), animationDuration: 0.0) {}
                    self.runningIndex = i + self.pingTests.count
                    self.testsTable.reloadData()
                    let waitTime = test.getWaitTime()
                    let runTime = test.getRunTime()
                    let increment = waitTime / (waitTime + runTime)
                    let percentage = (Float(i) + Float(self.pingTests.count) + Float(increment)) / Float(nbTests) * 100.0
                    self.progress.setProgress(value: CGFloat(percentage), animationDuration: waitTime) {
                        // Do anything your heart desires...
                        print("wait completed")
                        self.progress.setProgress(value: CGFloat((Float(i + 1 + self.pingTests.count) / Float(nbTests) * 100.0) - 1.0), animationDuration: runTime) {print("test completed")}
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
            let wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
            let cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
            let wifiBytesSent = wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent
            let wifiBytesReceived = wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived
            let cellBytesSent = cellInfoEnd.bytesSent - cellInfoStart.bytesSent
            let cellBytesReceived = cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived
            self.runningIndex = testDones
            var testResults = [TestResult]()
            for i in 0..<testDones {
                let test = self.allTests[i]
                let result = test.getTestResult()
                if self.stoppedTests && self.backgrounded && i == testDones - 1 {
                    result.setAbortedBackgrounded()
                }
                else if self.stoppedTests && i == testDones - 1 {
                    result.setFailedByNetworkChange()
                }
                testResults.append(result)
            }
            DispatchQueue.main.async {
                self.testsTable.reloadData()
            }
            let duration = self.stopTime.timeIntervalSince(self.startTime)
            
            let benchmark = Benchmark(connectivities: self.connectivities, duration: duration, locations: self.locations, mobile: false, pingMed: bestMed, pingStd: bestStd, wifiBytesReceived: wifiBytesReceived, wifiBytesSent: wifiBytesSent, cellBytesReceived: cellBytesReceived, cellBytesSent: cellBytesSent, multipathService: self.multipathService, serverName: bestServer, startTime: self.startTime, testResults: testResults)
            Utils.sendToServer(benchmark: benchmark, tests: self.allTests)
            benchmark.save()
            self.cellTimer?.invalidate()
            self.cellTimer = nil
            print("Tests done")
            NotificationCenter.default.post(name: Utils.TestsLaunchedNotification, object: nil, userInfo: ["startNewTestsEnabled": true])
            NotificationCenter.default.removeObserver(self)
            DispatchQueue.main.async {
                UIApplication.shared.isIdleTimerDisabled = false
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
        return allTests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "StaticTestTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? StaticTestTableViewCell else {
            fatalError("The dequeued cell is not an instance of StaticTestTableViewCell.")
        }
        
        // Fetches the appropriate meal for the data source layout.
        let test = allTests[indexPath.row]
        
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
        // For debug
        // debugCount += 1
        //if debugCount >= 5 {
        //    print("Will debug")
        //    Utils.getDebug()
        //    debugCount = 0
        //}
        if cellStatus != wasCellularOn {
            let reachabilityStatus = internetReachability.currentReachabilityStatus()
            let conn = Connectivity.getCurrentConnectivity(reachabilityStatus: reachabilityStatus)
            connectivities.append(conn)
            print("Cellular changed! In static tests, this should abort the test!")
            for i in 0..<tests.count {
                QuictrafficNotifyReachability(tests[i].getNotifyID())
            }
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
