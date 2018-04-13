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

class MobileRunnerViewController: UIViewController, ChartViewDelegate {
    @IBOutlet weak var distanceChartView: LineChartView!

    @IBOutlet weak var downDelaysChartView: LineChartView!
    @IBOutlet weak var upDelaysChartView: LineChartView!
    @IBOutlet weak var userLabel: UILabel!
    
    // Provided by MobileMainViewController
    var testServer: TestServer?
    var medPing: Double?
    var stdPing: Double?
    
    var streamTests = [BaseStreamTest]()
    var startTime: Date = Date()
    var stopTime: Date = Date()
    var timer: Timer?
    var completed: Bool = false
    var stopping: Bool = false
    var userInterrupted: Bool = false
    var stopNow: Bool = false
    
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
    var lastReceivedCellBytes: UInt32 = 0
    var countNoWifi = 0
    var gotDelays = false
    var nextWiFiBytesDistance: Double = 0.0
    var nextWiFiBytesLostTime: Date = Date()
    var computedWiFiBytesDistance: Double = 0.0
    var computedWiFiBytesLostTime: Date = Date()
    var computedWiFiSystemDistance: Double = 0.0
    var computedWiFiSystemLostTime: Date = Date()
    
    var upQUICDelays: [ChartDataEntry] = [ChartDataEntry]()
    var downQUICDelays: [ChartDataEntry] = [ChartDataEntry]()
    var upMPTCPDelays: [ChartDataEntry] = [ChartDataEntry]()
    var downMPTCPDelays: [ChartDataEntry] = [ChartDataEntry]()
    
    var wifiBSSID: String = ""
    var wifiSSID: String = ""
    var wifiIPs: [String] = []
    var wifiBSSIDSwitches = 0
    
    // For debug
    //var debugCount = 0
    
    // Detect app going to background
    var backgrounded = false
    
    // Currently fixed to handover
    let multipathService: RunConfig.MultipathServiceType = .handover
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        
        // Do any additional setup after loading the view.
        LineChartHelper.initialize(chartView: distanceChartView, delegate: self, xValueFormatter: DateValueFormatter())
        LineChartHelper.initialize(chartView: upDelaysChartView, delegate: self, xValueFormatter: DateValueFormatter())
        LineChartHelper.initialize(chartView: downDelaysChartView, delegate: self, xValueFormatter: DateValueFormatter())
        
        streamTests = [
            QUICStreamTest(ipVer: .any, maxPathID: 255, runTime: 0, waitTime: 0.0),
            TCPStreamTest(ipVer: .any, runTime: 0, waitTime: 0.0, multipath: true),
        ]
        
        for t in streamTests {
            t.setTestServer(testServer: testServer!)
            t.setMultipathService(service: multipathService)
        }
        
        // Start observing app going to background notifications
        NotificationCenter.default.addObserver(self, selector: #selector(MobileRunnerViewController.applicationDidSwitchToBackground(note:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        NotificationCenter.default.post(name: Utils.TestsLaunchedNotification, object: nil, userInfo: ["startNewTestsEnabled": false])
        
        NotificationCenter.default.addObserver(self, selector: #selector(MobileRunnerViewController.reachabilityChanged(note:)), name: .reachabilityChanged, object: nil)
        internetReachability.startNotifier()
        
        NotificationCenter.default.addObserver(self, selector: #selector(MobileRunnerViewController.locationChanged(note:)), name: LocationTracker.LocationTrackerNotification, object: nil)
        
        // This starts here, for avoiding old location info
        startTime = Date()
        locationTracker.forceUpdate()
        
        startTests()
    }
    
    func stopTraffic(after: TimeInterval) {
        stopping = true
        if let lastDistance = distances.last {
            computedWiFiSystemDistance = lastDistance.y
        }
        computedWiFiSystemLostTime = Date()
        print("stooooop")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + after) {
            self.stopNow = true
            for t in self.streamTests {
                t.stopTraffic()
            }
            print("Done my stop job")
        }
    }
    
    // MARK: App state tracking
    @objc
    func applicationDidSwitchToBackground(note: Notification) {
        backgrounded = true
        print("Application backgrounded")
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            for t in self.streamTests {
                t.stopTraffic()
            }
        }
    }
    
    @objc
    func reachabilityChanged(note: Notification) {
        let reachabilityStatus = internetReachability.currentReachabilityStatus()
        for t in streamTests {
            t.notifyReachability()
        }
        let connectivity = Connectivity.getCurrentConnectivity(reachabilityStatus: reachabilityStatus)
        connectivities.append(connectivity)
        if !stopping && ((connectivity.networkType != .WiFiCellular && connectivity.networkType != .CellularWifi)) {
            self.stopTraffic(after: 2.0)
            DispatchQueue.main.async {
                self.userLabel.text = "WiFi is lost, the test will stop now."
            }
        } else if !stopping && connectivity.wifiBSSID != wifiBSSID && connectivity.wifiNetworkName! == wifiSSID && connectivity.wifiAddresses!.containsSameElements(as: self.wifiIPs) {
            // Same network, but different AP; continue the test, might be interesting...
            wifiBSSIDSwitches += 1
            wifiBSSID = connectivity.wifiBSSID!
            DispatchQueue.main.async {
                self.userLabel.text = "You keep WiFi connectivity after access point change! You got \(self.wifiBSSIDSwitches) WiFi access point switches so far. How far can you go while keeping the same WiFi network?"
            }
        } else if !stopping && (connectivity.wifiNetworkName! != wifiSSID || !connectivity.wifiAddresses!.containsSameElements(as: self.wifiIPs)) {
            print(connectivity.wifiNetworkName!, wifiSSID)
            print(connectivity.wifiAddresses!, self.wifiIPs)
            self.stopTraffic(after: 2.0)
            DispatchQueue.main.async {
                self.userLabel.text = "The WiFi network changed, the test will stop now."
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
            // Avoid logging several times the same value
            if self.locations.count == 0 || self.locations.last?.timestamp != location.timestamp {
                self.locations.append(location)
            }
            let wifiInfoStart = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
            let cellInfo = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
            if !self.stopping && lastReceivedWiFiBytes < wifiInfoStart.bytesReceived {
                // This idea to delay the assignation is to cover possible bytes exchanges when searching for another AP
                self.computedWiFiBytesDistance = self.nextWiFiBytesDistance
                self.computedWiFiBytesLostTime = self.nextWiFiBytesLostTime
                print(lastReceivedWiFiBytes, wifiInfoStart.bytesReceived)
                let bytesOnWifi = wifiInfoStart.bytesReceived - self.lastReceivedWiFiBytes
                let bytesOnCell = cellInfo.bytesReceived - self.lastReceivedCellBytes
                // We also want to be sure WiFi works, and not cellular
                if gotDelays && bytesOnWifi >= bytesOnCell {
                    // A way to ensure WiFi is still there
                    self.nextWiFiBytesDistance = meters
                    self.nextWiFiBytesLostTime = cl.timestamp
                    DispatchQueue.main.async {
                        if self.wifiBSSIDSwitches > 0 {
                            self.userLabel.text = "You keep WiFi connectivity after access point change! You got \(self.wifiBSSIDSwitches) WiFi access point switches so far. How far can you go while keeping the same WiFi network?"
                        } else {
                            self.userLabel.text = "Please move away from your WiFi Access Point. The test will stop once the WiFi is lost."
                        }
                    }
                    self.countNoWifi = 0
                }
                self.lastReceivedWiFiBytes = wifiInfoStart.bytesReceived
                self.lastReceivedCellBytes = cellInfo.bytesReceived
                gotDelays = false
            } else if !self.stopping {
                self.computedWiFiBytesDistance = self.nextWiFiBytesDistance
                self.computedWiFiBytesLostTime = self.nextWiFiBytesLostTime
                self.countNoWifi += 1
                if self.countNoWifi >= 3 {
                    DispatchQueue.main.async {
                        self.userLabel.text = "No more data seen on WiFi, but system did not yet consider WiFi lost... How far do you need to move in order to let the system noticing it?"
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
        LineChartHelper.clearData(to: upDelaysChartView)
        LineChartHelper.clearData(to: downDelaysChartView)
        if upQUICDelays.count > 0 {
            LineChartHelper.setData(to: upDelaysChartView, with: upQUICDelays, label: "QUIC delays upload (ms)", color: UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0), mode: .linear)
        }
        if upMPTCPDelays.count > 0 {
            LineChartHelper.setData(to: upDelaysChartView, with: upMPTCPDelays, label: "MPTCP delays upload (ms)", color: UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0), mode: .linear)
        }
        if downQUICDelays.count > 0 {
            LineChartHelper.setData(to: downDelaysChartView, with: downQUICDelays, label: "QUIC Delays download (ms)", color: UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0), mode: .linear)
        }
        if downMPTCPDelays.count > 0 {
            LineChartHelper.setData(to: downDelaysChartView, with: downMPTCPDelays, label: "MPTCP Delays download (ms)", color: UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0), mode: .linear)
        }
        
        upDelaysChartView.notifyDataSetChanged()
        downDelaysChartView.notifyDataSetChanged()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startTests() {
        UIApplication.shared.isIdleTimerDisabled = true
        stopNow = false
        backgrounded = false
        let reachabilityStatus = internetReachability.currentReachabilityStatus()
        wasCellularOn = UIDevice.current.hasCellularConnectivity
        let connectivity = Connectivity.getCurrentConnectivity(reachabilityStatus: reachabilityStatus)
        wifiBSSID = connectivity.wifiBSSID!
        wifiSSID = connectivity.wifiNetworkName!
        wifiIPs = connectivity.wifiAddresses!
        connectivities.append(connectivity)
        let wifiInfoStart = InterfaceInfo.getInterfaceInfo(netInterface: .WiFi)
        let cellInfoStart = InterfaceInfo.getInterfaceInfo(netInterface: .Cellular)
        startTime = Date()
        self.userLabel.text = "Please move away from your WiFi Access Point. The test will stop once the WiFi is lost."
        self.navigationItem.hidesBackButton = true
        timer = Timer(timeInterval: 0.2, target: self, selector: #selector(MobileRunnerViewController.getDelays), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .commonModes)
        cellTimer = Timer(timeInterval: 0.5, target: self, selector: #selector(MobileRunnerViewController.probeCellular), userInfo: nil, repeats: true)
        RunLoop.current.add(cellTimer!, forMode: .commonModes)
        print("We start mobility!")
        upQUICDelays = []
        downQUICDelays = []
        upMPTCPDelays = []
        downMPTCPDelays = []
        
        DispatchQueue.global(qos: .userInteractive).async {
            let queue = OperationQueue()
            let group = DispatchGroup()
            for t in self.streamTests {
                group.enter()
                queue.addOperation {
                    t.run()
                    group.leave()
                }
            }
            // To be sure we can escape if something goes wrong in runs
            var res = group.wait(timeout: .now() + 1.0)
            while res == .timedOut && !self.stopNow {
                res = group.wait(timeout: .now() + 1.0)
            }
            self.timer?.invalidate()
            self.timer = nil
            
            DispatchQueue.main.async {
                self.userLabel.text = "Terminating connections, please wait..."
            }
            
            if res == .timedOut && self.stopNow {
                // We give 7 seconds to close the connection
                res = group.wait(timeout: .now() + 7.0)
            }
            
            print("Finished!")
            
            if res == .timedOut {
                print("Something went wrong...")
                DispatchQueue.main.async {
                    self.userLabel.text = "Forcing termination of connections and finalizing test, please wait..."
                }
            } else {
                DispatchQueue.main.async {
                    self.userLabel.text = "Finalizing test, please wait..."
                }
            }

            var testResults = [TestResult]()
            for t in self.streamTests {
                let res = t.getTestResult()
                if self.backgrounded {
                    res.setAbortedBackgrounded()
                }
                testResults.append(res)
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
            if self.backgrounded {
                benchmark.wifiBytesDistance = 0
                benchmark.wifiBytesLostTime = Date()
                benchmark.wifiSystemDistance = 0
                benchmark.wifiSystemLostTime = Date()
                benchmark.wifiBSSIDSwitches = self.wifiBSSIDSwitches
            } else {
                benchmark.wifiBytesDistance = self.computedWiFiBytesDistance
                benchmark.wifiBytesLostTime = self.computedWiFiBytesLostTime
                benchmark.wifiSystemDistance = self.computedWiFiSystemDistance
                benchmark.wifiSystemLostTime = self.computedWiFiSystemLostTime
                // This is a sanity check
                if self.computedWiFiBytesDistance > self.computedWiFiSystemDistance + 10.0 && self.computedWiFiBytesDistance > 11.0 {
                    // This is very strange, probably an issue occurred, so set wifiBytesDistance to a lower value
                    benchmark.wifiBytesDistance = self.computedWiFiBytesDistance - 11.0
                }
                benchmark.wifiBSSIDSwitches = self.wifiBSSIDSwitches
            }
            if self.userInterrupted {
                benchmark.userInterrupted = true
            }
            Utils.sendToServer(benchmark: benchmark, tests: self.streamTests)
            benchmark.save()
            self.cellTimer?.invalidate()
            self.cellTimer = nil
            NotificationCenter.default.post(name: Utils.TestsLaunchedNotification, object: nil, userInfo: ["startNewTestsEnabled": true])

            DispatchQueue.main.async {
                UIApplication.shared.isIdleTimerDisabled = false
                if self.backgrounded {
                    self.userLabel.text = "Test aborted: application backgrounded."
                } else if self.userInterrupted {
                    if self.countNoWifi < 3 {
                        self.userLabel.text = String(format: "You stopped the test while still reaching your WiFi Access Point %.1f m far away.", self.computedWiFiSystemDistance)
                    } else {
                        self.userLabel.text = String(format: "You stopped the test while your WiFi Access Point was fading out (after walking %.1f m) but your system still considered your WiFi usable %.1f m far away.", self.computedWiFiBytesDistance, self.computedWiFiSystemDistance)
                    }
                } else {
                    if self.wifiBSSIDSwitches > 0 {
                        self.userLabel.text = String(format: "Test completed. You lost WiFi after walking %.1f m (by switching WiFi Access Point \(self.wifiBSSIDSwitches) times) and your system detected it after you walked %.1f m.", self.computedWiFiBytesDistance, self.computedWiFiSystemDistance)
                    } else {
                        self.userLabel.text = String(format: "Test completed. You lost WiFi after walking %.1f m and your system detected it after you walked %.1f m.", self.computedWiFiBytesDistance, self.computedWiFiSystemDistance)
                    }
                }
                self.navigationItem.hidesBackButton = false
            }
        }
    }
    
    // MARK: Timer function
    @objc func getDelays() {
        for t in streamTests {
            let (newUpDelays, newDownDelays) = t.getProgressDelays()
            let newUpValues = stride(from: 0, to: newUpDelays.count, by: 1).map { (x) -> ChartDataEntry in
                return ChartDataEntry(x: newUpDelays[x].time, y: Double(newUpDelays[x].delayUs) / 1000.0)
            }
            let newDownValues = stride(from: 0, to: newDownDelays.count, by: 1).map { (x) -> ChartDataEntry in
                return ChartDataEntry(x: newDownDelays[x].time, y: Double(newDownDelays[x].delayUs) / 1000.0)
            }
            switch t.getProtocol().main {
            case .TCP:
                upMPTCPDelays += newUpValues
                downMPTCPDelays += newDownValues
            case .QUIC:
                upQUICDelays += newUpValues
                downQUICDelays += newDownValues
            }
            
            if newUpValues.count > 0 || newDownValues.count > 0 {
                gotDelays = true
            }
        }
        self.updateDelays()
    }
    
    @objc
    func probeCellular() {
        // For debug
        //debugCount += 1
        //if debugCount >= 5 {
        //    print("Will debug")
        //    Utils.getDebug()
        //    debugCount = 0
        //}
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
    
    // MARK: User button
    @IBAction func stopMobileTests(_ sender: UIBarButtonItem) {
        self.userInterrupted = true
        self.stopTraffic(after: 0.0)
        DispatchQueue.main.async {
            sender.isEnabled = false
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
