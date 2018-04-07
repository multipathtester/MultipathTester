//
//  BenchmarkDetailTableViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/11/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import CoreLocation
import UIKit

class BenchmarkDetailTableViewController: UITableViewController {
    
    struct TableItem {
        let title: String
        let detail: String
    }
    
    var benchmark: Benchmark?
    var benchmarkDetails = [TableItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM YYYY HH:mm:ss"
        dateFormatter.locale = .current
        
        let bench = benchmark!
        
        benchmarkDetails = [
            TableItem(title: "Test time", detail: dateFormatter.string(from: bench.startTime)),
            TableItem(title: "Timezone", detail: bench.timezone.abbreviation() ?? bench.timezone.description),
            TableItem(title: "Ping", detail: String.init(format: "%.1f ms", bench.pingMed)),
            TableItem(title: "Ping standard deviation", detail: String.init(format: "%.1f ms", bench.pingStd)),
            TableItem(title: "Multipath Service", detail: bench.multipathService.rawValue),
        ]
        if let wifiBytesDistance = bench.wifiBytesDistance, let wifiSystemDistance = bench.wifiSystemDistance {
            benchmarkDetails += [
                TableItem(title: "WiFi reachability", detail: String(format: "%.1f m", wifiBytesDistance)),
                TableItem(title: "WiFi system reachability", detail: String(format: "%.1f m", wifiSystemDistance)),
            ]
        }
        if bench.locations.count > 0 {
            let loc = bench.locations[bench.locations.count - 1]
            benchmarkDetails += [TableItem(title: "Location", detail: loc.getDescription())]
        } else {
            benchmarkDetails += [TableItem(title: "Location", detail: "No data")]
        }
        
        if bench.connectivities.count > 0 {
            let conn = bench.connectivities[0]
            benchmarkDetails += [
                TableItem(title: "Network", detail: conn.getNetworkTypeDescription()),
            ]
            if conn.networkType == .WiFi || conn.networkType == .WiFiCellular || conn.networkType == .CellularWifi {
                benchmarkDetails += [
                    TableItem(title: "WiFi SSID", detail: conn.wifiNetworkName ?? "No WiFi SSID"),
                    TableItem(title: "WiFi BSSID", detail: conn.wifiBSSID ?? "No BSSID"),
                    // TableItem(title: "Country of WiFi AS", detail: "BE"),
                    // TableItem(title: "Country of WiFI IP", detail: "BE"),
                    // TableItem(title: "WiFi IP network (AS)", detail: "2611"),
                    // TableItem(title: "WiFi IP network name", detail: "BELNET, BE"),
                ]
            }
            if conn.networkType == .Cellular || conn.networkType == .WiFiCellular || conn.networkType == .CellularWifi {
                benchmarkDetails += [
                    TableItem(title: "Cellular operator", detail: conn.cellularNetworkName ?? "No network name"),
                    TableItem(title: "Country of cellular AS", detail: conn.telephonyNetworkSimCountry ?? "No cellular country"),
                    // TableItem(title: "Country of cellular IP", detail: "BE"),
                    // TableItem(title: "Cellular IP network (AS)", detail: "2611"),
                    TableItem(title: "Cellular IP network name", detail: conn.telephonyNetworkSimOperator ?? "No cellular name"),
                ]
            }
        } else {
            benchmarkDetails += [
                TableItem(title: "Network", detail: "None"),
            ]
        }
        benchmarkDetails += [
            TableItem(title: "Test duration", detail: Utils.stringSecondsToMinutesSeconds(seconds: Int(bench.duration))),
            TableItem(title: "Sent on WiFi", detail: Utils.formatBytes(bytes: bench.wifiBytesSent)),
            TableItem(title: "Received on WiFi", detail: Utils.formatBytes(bytes: bench.wifiBytesReceived)),
            TableItem(title: "Sent on cellular", detail: Utils.formatBytes(bytes: bench.cellBytesSent)),
            TableItem(title: "Received on cellular", detail: Utils.formatBytes(bytes: bench.cellBytesReceived)),
            TableItem(title: "Server name", detail: bench.serverName.rawValue),
            TableItem(title: "Platform", detail: bench.platform),
            TableItem(title: "Platform version", detail: bench.platformVersion),
            TableItem(title: "Model", detail: bench.model),
            TableItem(title: "Software name", detail: bench.softwareName),
            TableItem(title: "Software version", detail: bench.softwareVersion),
            TableItem(title: "Benchmark ID", detail: bench.uuid.uuidString),
        ]

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return benchmarkDetails.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == benchmarkDetails.count - 1 {
            // UUID field
            let cellIdentifier = "BenchmarkUUIDTableViewCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? BenchmarkUUIDTableViewCell else {
                fatalError("The dequeued cell is not an instance of BenchmarkUUIDTableViewCell.")
            }
            let tableItem = benchmarkDetails[indexPath.row]
            
            cell.titleLabel.text = tableItem.title
            cell.uuidLabel.text = tableItem.detail
            
            return cell
        }
        let cellIdentifier = "BenchmarkDetailTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? BenchmarkDetailTableViewCell else {
            fatalError("The dequeued cell is not an instance of BenchmarkDetailTableViewCell.")
        }
        
        let tableItem = benchmarkDetails[indexPath.row]
        
        cell.titleLabel.text = tableItem.title
        cell.detailLabel.text = tableItem.detail
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == benchmarkDetails.count - 1 {
            // UUID cell
            return 60.0
        }
        return 40.0
    }
}
