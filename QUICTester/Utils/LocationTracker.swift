//
//  LocationTracker.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/17/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import CoreLocation
import UIKit

class LocationTracker: NSObject, CLLocationManagerDelegate {
    static let LocationTrackerNotification = NSNotification.Name("LocationTrackerNotification")
    
    // MARK: Static
    static var sharedLocationTracker: LocationTracker?
    
    static func sharedTracker() -> LocationTracker {
        if sharedLocationTracker == nil {
            sharedLocationTracker = LocationTracker()
        }
        return sharedLocationTracker!
    }
    
    // MARK: Instance
    
    var locationManager: CLLocationManager
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 3.0
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startIfAuthorized() -> Bool {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            return true
        }
        return false
    }
    
    func stop() {
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        NotificationCenter.default.post(name: LocationTracker.LocationTrackerNotification, object: self, userInfo: ["locations": locations])
    }
}
