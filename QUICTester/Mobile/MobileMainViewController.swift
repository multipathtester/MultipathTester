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

class MobileMainViewController: UIViewController {
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
        print(NEHotspotHelper.supportedNetworkInterfaces())

        internetReachability.startNotifier()
        
        locationAuthorized = LocationTracker.sharedTracker().startIfAuthorized()
        
        let reachabilityStatus = internetReachability.currentReachabilityStatus()
        wasCellularOn = UIDevice.current.hasCellularConnectivity
        let conn = Connectivity.getCurrentConnectivity(reachabilityStatus: reachabilityStatus)
        updateUI(conn: conn)
        
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
        DispatchQueue.global(qos: .background).async {
            let pingTests = [
                QUICConnectivityTest(ipVer: .any, port: 443, testServer: .fr, pingCount: 5, pingWaitMs: 50),
                QUICConnectivityTest(ipVer: .any, port: 443, testServer: .ca, pingCount: 5, pingWaitMs: 50),
                QUICConnectivityTest(ipVer: .any, port: 443, testServer: .jp, pingCount: 5, pingWaitMs: 50),
            ]
            var currentBestServer: TestServer = .fr
            self.bestMedPing = Double.greatestFiniteMagnitude
            self.bestStdPing = Double.greatestFiniteMagnitude
            let queue = OperationQueue()
            let group = DispatchGroup()
            for i in 0..<pingTests.count {
                group.enter()
                let test = pingTests[i]
                queue.addOperation {
                    let res = test.run()
                    let success = res["success"] as! Bool
                    let durations = res["durations"] as! [Double]
                    let median = durations.median()
                    print("median duration of", test.getTestServer(), "is", median)
                    OperationQueue.main.addOperation {
                        if success && median >= 0.0 && median < self.bestMedPing {
                            currentBestServer = test.getTestServer()
                            self.bestMedPing = median
                            self.bestStdPing = durations.standardDeviation()
                        }
                        group.leave()
                    }
                }
            }
            group.wait()
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
            summaryLabel.text = "You are ready to perform this test."
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

}
