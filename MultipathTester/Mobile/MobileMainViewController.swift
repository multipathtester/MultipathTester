//
//  MobileMainViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/22/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import CoreLocation
import UIKit
import NetworkExtension
import UserNotifications

class MobileMainViewController: UIViewController {
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var startButton: UIButton?
    
    @IBOutlet weak var wifiImageView: UIImageView!
    @IBOutlet weak var wifiLabel: UILabel!
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var locImageView: UIImageView!
    @IBOutlet weak var locLabel: UILabel!
    
    @IBOutlet weak var summaryLabel: UILabel!
    
    var locationTracker: LocationTracker = LocationTracker.sharedTracker()
    var goodAccuracy: Bool = false
    var locationAuthorized: Bool = false
    
    var internetReachability: Reachability = Reachability.forInternetConnection()
    // Reachability does not warn about the cellular state if WiFi is on...
    var wasCellularOn: Bool = false
    var timer: Timer?
    
    var bestServer: TestServer = .fr
    var ready : Bool = false
    var bestMedPing: Double = Double.greatestFiniteMagnitude
    var bestStdPing: Double = Double.greatestFiniteMagnitude
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self, selector: #selector(MobileMainViewController.testsLaunched(note:)), name: Utils.TestsLaunchedNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startButton!.isEnabled = Utils.startNewTestsEnabled

        internetReachability.startNotifier()
        
        locationAuthorized = LocationTracker.sharedTracker().startIfAuthorized()
        
        let reachabilityStatus = internetReachability.currentReachabilityStatus()
        wasCellularOn = UIDevice.current.hasCellularConnectivity
        let conn = Connectivity.getCurrentConnectivity(reachabilityStatus: reachabilityStatus)
        updateUI(conn: conn)
        
        descriptionLabel.text = """
        How far can you reach your WiFi?
        
        Getting best recorded result...
        """
        
        // Get the current best result for WiFi distance
        DispatchQueue.global(qos: .background).async {
            let (maxWifiDistance, wifiSwitches) = Utils.getMaxWifiDistanceAndSwitches()
            DispatchQueue.main.async {
                if wifiSwitches > 0 {
                    self.descriptionLabel.text = String(format:"""
                    How far can you reach your WiFi?
                    
                    The record is %.1f m by switching WiFi Access Point %d times.
                    """, maxWifiDistance, wifiSwitches)
                } else {
                    self.descriptionLabel.text = String(format:"""
                    How far can you reach your WiFi?
                    
                    The record is %.1f m.
                    """, maxWifiDistance)
                }
            }
        }
        
        timer = Timer(timeInterval: 0.5, target: self, selector: #selector(MobileMainViewController.probeCellular), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .commonModes)
        determineClosestServer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(MobileMainViewController.locationChanged(note:)), name: LocationTracker.LocationTrackerNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MobileMainViewController.reachabilityChanged(note:)), name: .reachabilityChanged, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc
    func locationChanged(note: Notification) {
        let info = note.userInfo
        guard let locations = info!["locations"] as? [CLLocation] else {
            return
        }
        for cl in locations {
            if cl.horizontalAccuracy <= 10.0 {
                goodAccuracy = true
            } else {
                goodAccuracy = false
            }
        }
        askForUIUpdate()
    }

    func determineClosestServer() {
        DispatchQueue.global(qos: .userInteractive).async {
            let pingTests = [
                TCPConnectivityTest(ipVer: .any, port: 443, testServer: .fr, pingCount: 0, pingWaitMs: 200),
                TCPConnectivityTest(ipVer: .any, port: 443, testServer: .ca, pingCount: 0, pingWaitMs: 200),
                TCPConnectivityTest(ipVer: .any, port: 443, testServer: .jp, pingCount: 0, pingWaitMs: 200),
            ]
            var currentBestServer: TestServer = .fr
            self.bestMedPing = Double.greatestFiniteMagnitude
            self.bestStdPing = Double.greatestFiniteMagnitude
            
            let queue = OperationQueue()
            let group = DispatchGroup()
            
            for i in 0..<pingTests.count {
                let test = pingTests[i]
                group.enter()
                queue.addOperation {
                    test.run()
                    group.leave()
                }
            }
            group.wait()
            print("All connected")
            
            let pingCount = 5
            for _ in 0..<pingCount {
                for i in 0..<pingTests.count {
                    let test = pingTests[i]
                    if test.succeeded() {
                        group.enter()
                        queue.addOperation {
                            test.runOnePing()
                            group.leave()
                        }
                    }
                }
                group.wait()
                // Wait for 100 ms before next burst
                usleep(100 * 1000)
            }
            for i in 0..<pingTests.count {
                let test = pingTests[i]
                // Close file descriptors
                test.finish()
                let durations = test.durations
                if test.succeeded() && durations.count == pingCount {
                    let median = durations.median()
                    print("median duration of", test.getTestServer(), "is", median)
                    if median >= 0.0 && median < self.bestMedPing {
                        currentBestServer = test.getTestServer()
                        self.bestMedPing = median
                        self.bestStdPing = durations.standardDeviation()
                    }
                }
            }
            
            print("Best server is", currentBestServer)
            self.bestServer = currentBestServer
            self.ready = true
            self.askForUIUpdate()
        }
    }
    
    func updateUI(conn: Connectivity) {
        let bundle = Bundle(for: type(of: self))
        var (wifi, cell) = (false, false)
        
        if conn.networkType == .WiFi || conn.networkType == .WiFiCellular {
            if conn.wifiAddresses!.count > 0 {
                let wifiIm = UIImage(named: "wifi", in: bundle, compatibleWith: self.traitCollection)
                wifiImageView.image = wifiIm
                wifiLabel.text = "Wifi is ready."
                wifi = true
            } else {
                let no_wifi = UIImage(named: "no_wifi", in: bundle, compatibleWith: self.traitCollection)
                wifiImageView.image = no_wifi
                wifiLabel.text = "Wifi has no addresses."
            }
        } else if conn.networkType == .CellularWifi {
            let no_wifi = UIImage(named: "no_wifi", in: bundle, compatibleWith: self.traitCollection)
            wifiImageView.image = no_wifi
            wifiLabel.text = "Wifi is not ready yet."
        } else {
            let no_wifi = UIImage(named: "no_wifi", in: bundle, compatibleWith: self.traitCollection)
            wifiImageView.image = no_wifi
            wifiLabel.text = "Wifi is not available."
        }
        
        if conn.networkType == .Cellular || conn.networkType == .WiFiCellular || conn.networkType == .CellularWifi {
            if conn.cellularAddresses!.count > 0 {
                let cellular = UIImage(named: "cellular", in: bundle, compatibleWith: self.traitCollection)
                cellImageView.image = cellular
                cellLabel.text = "Cellular is ready."
                cell = true
            } else {
                let no_cellular = UIImage(named: "no_cellular", in: bundle, compatibleWith: self.traitCollection)
                cellImageView.image = no_cellular
                cellLabel.text = "Cellular has no addresses."
            }
        } else {
            let no_cellular = UIImage(named: "no_cellular", in: bundle, compatibleWith: self.traitCollection)
            cellImageView.image = no_cellular
            cellLabel.text = "Cellular is not available."
        }
        
        if locationAuthorized {
            let location = UIImage(named: "location", in: bundle, compatibleWith: self.traitCollection)
            locImageView.image = location
            if goodAccuracy {
                locLabel.text = "You can estimate how far your WiFi is reachable."
            } else {
                locLabel.text = "Location is enabled, please wait for more precise estimation..."
            }
            
        } else {
            let no_location = UIImage(named: "no_location", in: bundle, compatibleWith: self.traitCollection)
            locImageView.image = no_location
            locLabel.text = "Location is disabled, the application cannot estimate how far your WiFi is reachable."
        }
        
        if wifi && cell && ready {
            summaryLabel.text = "Everything is set up. Are you ready?"
            startButton!.isEnabled = Utils.startNewTestsEnabled
        } else if wifi && cell {
            summaryLabel.text = "Determining closest server..."
            startButton!.isEnabled = false
        } else {
            summaryLabel.text = "You need both WiFi and cellular networks to perform this test."
            startButton!.isEnabled = false
        }
        
    }
    
    func askForUIUpdate() {
        let reachabilityStatus = internetReachability.currentReachabilityStatus()
        let conn = Connectivity.getCurrentConnectivity(reachabilityStatus: reachabilityStatus)
        DispatchQueue.main.async {
            self.updateUI(conn: conn)
        }
    }
    
    @objc
    func reachabilityChanged(note: Notification) {
        self.ready = false
        askForUIUpdate()
        determineClosestServer()
    }
    
    @objc
    func testsLaunched(note: Notification) {
        let info = note.userInfo
        guard let enabled = info!["startNewTestsEnabled"] as? Bool else {
            return
        }
        Utils.startNewTestsEnabled = enabled
        if let button = startButton {
            DispatchQueue.main.async {
                button.isEnabled = enabled
            }
        }
    }
    
    @objc
    func probeCellular() {
        // This first instruction is not cellular probing here, but this will check location accuracy
        locationTracker.forceUpdate()
        let cellStatus = UIDevice.current.hasCellularConnectivity
        if cellStatus != wasCellularOn {
            wasCellularOn = cellStatus
            // This should not be an issue, WiFi should be used
            // self.ready = false
            askForUIUpdate()
        }
    }
    

    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
        case "RunMobileTests":
            guard let mobileRunnerViewController = segue.destination as? MobileRunnerViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            mobileRunnerViewController.testServer = bestServer
            mobileRunnerViewController.medPing = bestMedPing
            mobileRunnerViewController.stdPing = bestStdPing
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }

    @IBAction func aboutTests(_ sender: Any) {
        let alert = UIAlertController(title: "About mobile tests", message: """
        This mode allows you to test how your device deals with multiple paths when it is in mobility scenario. It studies when the WiFi starts to be lossy and when the cellular starts to be used.
        
        The test stops once the WiFi network is lost or changed. The transfer rate is about 80 KB/s.

        This mode asks for location permission to estimate how far you can reach your WiFi. This estimation is not available if the permission is not granted.
        """, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
