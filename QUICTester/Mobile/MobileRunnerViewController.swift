//
//  MobileTesterViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/8/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Charts
import CoreLocation
import Quictraffic

class MobileRunnerViewController: UIViewController, ChartViewDelegate {
    @IBOutlet weak var distanceChartView: LineChartView!
    @IBOutlet weak var delaysChartView: LineChartView!
    @IBOutlet weak var userLabel: UILabel!
    
    // Provided by MobileMainViewController
    var testServer: TestServer?
    var medPing: Double?
    var stdPing: Double?
    
    var tests: [QUICStreamTest] = [QUICStreamTest]()
    var runningTest: QUICStreamTest?
    var startTime: Date = Date()
    var stopTime: Date = Date()
    var timer: Timer?
    var completed: Bool = false
    var stopping: Bool = false
    
    // Reachability does not warn about the cellular state if WiFi is on...
    var wasCellularOn: Bool = false
    var cellTimer: Timer?
    
    var internetReachability: Reachability = Reachability.forInternetConnection()
    var locationTracker: LocationTracker = LocationTracker.sharedTracker()
    var connectivities: [Connectivity] = [Connectivity]()
    
    var locations: [Location] = [Location]()
    var initialLocation: CLLocation?
    
    var distances: [ChartDataEntry] = [ChartDataEntry]()
    var lastReceivedWiFiBytes: UInt32 = 0
    var countNoWifi = 0
    var nextWiFiBytesDistance: Double = 0.0
    var nextWiFiBytesLostTime: Date = Date()
    var computedWiFiBytesDistance: Double = 0.0
    var computedWiFiBytesLostTime: Date = Date()
    var computedWiFiSystemDistance: Double = 0.0
    var computedWiFiSystemLostTime: Date = Date()
    
    var upDelays: [ChartDataEntry] = [ChartDataEntry]()
    var downDelays: [ChartDataEntry] = [ChartDataEntry]()
    
    var wifiBSSID: String = ""
    
    // Currently fixed to handover
    let multipathService: RunConfig.MultipathServiceType = .handover
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        
        // Do any additional setup after loading the view.
        LineChartHelper.initialize(chartView: distanceChartView, delegate: self, xValueFormatter: DateValueFormatter())
        LineChartHelper.initialize(chartView: delaysChartView, delegate: self, xValueFormatter: DateValueFormatter())
        
        tests = [
            QUICStreamTest(ipVer: .any, maxPathID: 255, runTime: 0, waitTime: 0.0)
        ]
        
        for i in 0..<tests.count {
            let test = tests[i]
            test.setTestServer(testServer: testServer!)
            test.setMultipathService(service: multipathService)
        }
        
        NotificationCenter.default.post(name: Utils.TestsLaunchedNotification, object: nil, userInfo: ["startNewTestsEnabled": false])
        
        NotificationCenter.default.addObserver(self, selector: #selector(MobileRunnerViewController.reachabilityChanged(note:)), name: .reachabilityChanged, object: nil)
        internetReachability.startNotifier()
        
        NotificationCenter.default.addObserver(self, selector: #selector(MobileRunnerViewController.locationChanged(note:)), name: LocationTracker.LocationTrackerNotification, object: nil)
        
        // This starts here, for avoiding old location info
        startTime = Date()
        locationTracker.forceUpdate()
        
        startTests()
    }
    
    @objc
    func reachabilityChanged(note: Notification) {
        let reachabilityStatus = internetReachability.currentReachabilityStatus()
        for i in 0..<tests.count {
            QuictrafficNotifyReachability(tests[i].getNotifyID())
        }
        let connectivity = Connectivity.getCurrentConnectivity(reachabilityStatus: reachabilityStatus)
        connectivities.append(connectivity)
        if (connectivity.networkType != .WiFiCellular && connectivity.networkType != .CellularWifi) || connectivity.wifiBSSID != wifiBSSID {
            stopping = true
            if let lastDistance = distances.last {
                computedWiFiSystemDistance = lastDistance.y
                computedWiFiSystemLostTime = Date()
            }
            print("stooooop")
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                for i in 0..<self.tests.count {
                    QuictrafficStopStream(self.tests[i].getNotifyID())
                }
            }
            print("traffic stopped")
            DispatchQueue.main.async {
                self.userLabel.text = "WiFi is lost."
            }
        }
    }
    
    @objc
    func locationChanged(note: Notification) {
        let info = note.userInfo
        guard let locations = info!["locations"] as? [CLLocation] else {
            return
        }
        for cl in locations {
            if cl.timestamp.compare(startTime) == .orderedAscending {
                // Old info, don't retain it
                continue
            }
            if self.locations.count == 0 {
                self.initialLocation = cl
            }
            let meters = cl.distance(from: self.initialLocation!)
            self.distances.append(ChartDataEntry(x: cl.timestamp.timeIntervalSince1970, y: meters))
            let location = Location(lon: cl.coordinate.longitude, lat: cl.coordinate.latitude, timestamp: cl.timestamp, accuracy: cl.horizontalAccuracy, altitude: cl.altitude, speed: cl.speed)
            self.locations.append(location)
            let wifiInfoStart = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
            if !self.stopping && lastReceivedWiFiBytes < wifiInfoStart.bytesReceived {
                // This idea to delay the assignation is to cover possible bytes exchanges when searching for another AP
                self.computedWiFiBytesDistance = self.nextWiFiBytesDistance
                self.computedWiFiBytesLostTime = self.nextWiFiBytesLostTime
                print(lastReceivedWiFiBytes, wifiInfoStart.bytesReceived)
                self.lastReceivedWiFiBytes = wifiInfoStart.bytesReceived
                self.nextWiFiBytesDistance = meters
                self.nextWiFiBytesLostTime = cl.timestamp
                self.countNoWifi = 0
                DispatchQueue.main.async {
                    self.userLabel.text = "Please move away from your WiFi Access Point."
                }
            } else if !self.stopping {
                self.computedWiFiBytesDistance = self.nextWiFiBytesDistance
                self.computedWiFiBytesLostTime = self.nextWiFiBytesLostTime
                self.countNoWifi += 1
                if self.countNoWifi >= 3 {
                    DispatchQueue.main.async {
                        self.userLabel.text = "No more data seen on WiFi..."
                    }
                }
            }
        }
        if !completed {
            self.updateDistances()
        }
    }
    
    func updateDistances() {
        LineChartHelper.clearData(to: distanceChartView)
        if distances.count > 0 {
            LineChartHelper.setData(to: distanceChartView, with: distances, label: "Distance from starting point (m)", color: UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0), mode: .horizontalBezier)
        }
        distanceChartView.notifyDataSetChanged()
    }
    
    func updateDelays() {
        LineChartHelper.clearData(to: delaysChartView)
        if upDelays.count > 0 {
            LineChartHelper.setData(to: delaysChartView, with: upDelays, label: "Delays upload (ms)", color: UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0), mode: .linear)
        }
        if downDelays.count > 0 {
            LineChartHelper.setData(to: delaysChartView, with: downDelays, label: "Delays download (ms)", color: UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0), mode: .linear)
        }
        
        delaysChartView.notifyDataSetChanged()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startTests() {
        let reachabilityStatus = internetReachability.currentReachabilityStatus()
        wasCellularOn = UIDevice.current.hasCellularConnectivity
        let connectivity = Connectivity.getCurrentConnectivity(reachabilityStatus: reachabilityStatus)
        wifiBSSID = connectivity.wifiBSSID!
        connectivities.append(connectivity)
        let wifiInfoStart = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        let cellInfoStart = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        startTime = Date()
        self.userLabel.text = "Please move away from your WiFi Access Point."
        self.navigationItem.hidesBackButton = true
        timer = Timer(timeInterval: 0.2, target: self, selector: #selector(MobileRunnerViewController.getDelays), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .commonModes)
        cellTimer = Timer(timeInterval: 0.5, target: self, selector: #selector(MobileRunnerViewController.probeCellular), userInfo: nil, repeats: true)
        RunLoop.current.add(cellTimer!, forMode: .commonModes)
        print("We start mobility!")
        upDelays = []
        downDelays = []
        
        DispatchQueue.global(qos: .background).async {
            let nbTests = self.tests.count
            for t in self.tests {
                self.runningTest = t
                _ = t.run()
            }
            self.runningTest = nil
            self.timer?.invalidate()
            self.timer = nil
            print("Finished!")
            
            DispatchQueue.main.async {
                self.userLabel.text = "Finalizing test, please wait..."
            }

            var testResults = [TestResult]()
            for i in 0..<nbTests {
                let test = self.tests[i]
                testResults.append(test.getTestResult())
            }
            self.completed = true
            self.stopTime = Date()
            NotificationCenter.default.removeObserver(self)
            let wifiInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
            let cellInfoEnd = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
            let wifiBytesSent = wifiInfoEnd.bytesSent - wifiInfoStart.bytesSent
            let wifiBytesReceived = wifiInfoEnd.bytesReceived - wifiInfoStart.bytesReceived
            let cellBytesSent = cellInfoEnd.bytesSent - cellInfoStart.bytesSent
            let cellBytesReceived = cellInfoEnd.bytesReceived - cellInfoStart.bytesReceived
            let duration = self.stopTime.timeIntervalSince(self.startTime)
            let benchmark = Benchmark(connectivities: self.connectivities, duration: duration, locations: self.locations, mobile: true, pingMed: self.medPing!, pingStd: self.stdPing!, wifiBytesReceived: wifiBytesReceived, wifiBytesSent: wifiBytesSent, cellBytesReceived: cellBytesReceived, cellBytesSent: cellBytesSent, multipathService: self.multipathService, serverName: self.testServer!, startTime: self.startTime, testResults: testResults)
            benchmark.wifiBytesDistance = self.computedWiFiBytesDistance
            benchmark.wifiBytesLostTime = self.computedWiFiBytesLostTime
            benchmark.wifiSystemDistance = self.computedWiFiSystemDistance
            benchmark.wifiSystemLostTime = self.computedWiFiSystemLostTime
            Utils.sendToServer(benchmark: benchmark, tests: self.tests)
            benchmark.save()
            self.cellTimer?.invalidate()
            self.cellTimer = nil
            NotificationCenter.default.post(name: Utils.TestsLaunchedNotification, object: nil, userInfo: ["startNewTestsEnabled": true])

            DispatchQueue.main.async {
                self.userLabel.text = String(format: "Test completed. You lost WiFi after walking %.1f m and your system detected it after you walked %.1f m.", self.computedWiFiBytesDistance, self.computedWiFiSystemDistance)
                self.navigationItem.hidesBackButton = false
            }
        }
    }
    
    // MARK: Timer function
    @objc func getDelays() {
        // TODO
        guard let streamTest = runningTest else {
            return
        }
        let (newUpDelays, newDownDelays) = streamTest.getProgressDelays()
        let newUpValues = stride(from: 0, to: newUpDelays.count, by: 1).map { (x) -> ChartDataEntry in
            return ChartDataEntry(x: newUpDelays[x].time, y: Double(newUpDelays[x].delayUs) / 1000.0)
        }
        let newDownValues = stride(from: 0, to: newDownDelays.count, by: 1).map { (x) -> ChartDataEntry in
            return ChartDataEntry(x: newDownDelays[x].time, y: Double(newDownDelays[x].delayUs) / 1000.0)
        }
        upDelays += newUpValues
        downDelays += newDownValues
        
        self.updateDelays()
    }
    
    @objc
    func probeCellular() {
        // This first instruction is not cellular probing here, but this will at least fill in location graph
        locationTracker.forceUpdate()
        let cellStatus = UIDevice.current.hasCellularConnectivity
        if cellStatus != wasCellularOn {
            wasCellularOn = cellStatus
            let reachabilityStatus = internetReachability.currentReachabilityStatus()
            let conn = Connectivity.getCurrentConnectivity(reachabilityStatus: reachabilityStatus)
            connectivities.append(conn)
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
