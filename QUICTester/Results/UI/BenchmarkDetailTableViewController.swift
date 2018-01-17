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
            TableItem(title: "Ping", detail: String.init(format: "%.1f ms", bench.pingMean * 1000.0)),
            TableItem(title: "Ping variance", detail: String.init(format: "%.1f ms", bench.pingVar * 1000.0)),
        ]
        if bench.locations.count > 0 {
            let loc = bench.locations[bench.locations.count - 1]
            benchmarkDetails += [TableItem(title: "Location", detail: loc.getDescription())]
        } else {
            benchmarkDetails += [TableItem(title: "Location", detail: "No data")]
        }
        benchmarkDetails += [
            TableItem(title: "Network type", detail: "WiFi + LTE (4G)"),
            TableItem(title: "WiFi SSID", detail: "Cr4ckM31fUC4N"),
            TableItem(title: "WiFi BSSID", detail: "00:f2:8b:aa:89:30"),
            TableItem(title: "Country of WiFi AS", detail: "BE"),
            TableItem(title: "Country of WiFI IP", detail: "BE"),
            TableItem(title: "WiFi IP network (AS)", detail: "2611"),
            TableItem(title: "WiFi IP network name", detail: "BELNET, BE"),
            TableItem(title: "Cellular operator", detail: "Orange Improved"),
            TableItem(title: "Country of cellular AS", detail: "BE"),
            TableItem(title: "Country of cellular IP", detail: "BE"),
            TableItem(title: "Cellular IP network (AS)", detail: "2611"),
            TableItem(title: "Cellular IP network name", detail: "BELNET, BE"),
            TableItem(title: "Test duration", detail: Utils.stringSecondsToMinutesSeconds(seconds: Int(bench.duration))),
            TableItem(title: "Data amount WiFi interface", detail: "40 MB"),
            TableItem(title: "Data amount cellular interface", detail: "34 MB"),
            TableItem(title: "Server name", detail: bench.serverName),
            TableItem(title: "Platform", detail: bench.platform),
            TableItem(title: "Platform version", detail: bench.platformVersion),
            TableItem(title: "Model", detail: bench.model),
            TableItem(title: "Software name", detail: bench.softwareName),
            TableItem(title: "Software version", detail: bench.softwareVersion),
            TableItem(title: "QUIC version", detail: bench.quicVersion),
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
        return 40.0
    }
}
