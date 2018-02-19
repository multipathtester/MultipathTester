//
//  BenchmarkResultTableViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/1/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class BenchmarkTableViewController: UITableViewController {
    // MARK: Properties
    var benchmarks = [Benchmark]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        NotificationCenter.default.addObserver(self, selector: #selector(BenchmarkTableViewController.updateResult(note:)), name: NSNotification.Name(rawValue: "UpdateResult"), object: nil)
        self.updateResults()
    }
    
    @objc
    func updateResult(note: Notification) {
        print("Notified to update results")
        self.updateResults()
    }
    
    func updateResults() {
        if let savedBenchmarks = Benchmark.loadBenchmarks() {
            self.benchmarks = savedBenchmarks
        }
        print(self.benchmarks)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
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
        return benchmarks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "BenchmarkTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? BenchmarkTableViewCell else {
            fatalError("The dequeued cell is not an instance of BenchmarkTableViewCell.")
        }

        // Fetches the appropriate benchmarkResult for the data source layout
        let benchmark = benchmarks[indexPath.row]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM HH:mm"
        dateFormatter.locale = .current
        if benchmark.mobile {
            cell.testTypeLabel.text = "Mobile Tests"
        } else {
            cell.testTypeLabel.text = "Static Tests"
        }
        cell.startTimeLabel.text = dateFormatter.string(from: benchmark.startTime)
        
        let bundle = Bundle(for: type(of: self))
        let wifi = UIImage(named: "wifi", in: bundle, compatibleWith: self.traitCollection)
        let cellular = UIImage(named: "cellular", in: bundle, compatibleWith: self.traitCollection)
        let wifi_cell = UIImage(named: "wifi_cell", in: bundle, compatibleWith: self.traitCollection)
        let blank = UIImage(named: "blank", in: bundle, compatibleWith: self.traitCollection)
        
        if benchmark.connectivities.count > 0 {
            let conn = benchmark.connectivities[0]
            switch conn.networkType {
            case .WiFi:
                cell.networkImageView.image = wifi
            case .Cellular:
                cell.networkImageView.image = cellular
            case .WiFiCellular:
                cell.networkImageView.image = wifi_cell
            default:
                cell.networkImageView.image = blank
            }
            
        } else {
            cell.networkImageView.image = blank
        }
        
        // TODO when TCP tests will be present
        cell.tcpLabel.text = ""
        cell.tcpResultsLabel.text = ""
        
        let testCount = benchmark.testResults.count
        var testSucceeded = 0
        for i in 0..<testCount {
            let testResult = benchmark.testResults[i]
            if testResult.succeeded() {
                testSucceeded += 1
            }
        }
        cell.quicResultsLabel.text = String(testSucceeded) + "/" + String(testCount)
        cell.pingResultsLabel.text = String.init(format: "%.0f ms", benchmark.pingMed)
        
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
        case "ShowBenchmarkSummary":
            guard let benchmarkSummaryTableViewController = segue.destination as? BenchmarkSummaryTableViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedBenchmarkCell = sender as? BenchmarkTableViewCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedBenchmarkCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            let selectedBenchmark = benchmarks[indexPath.row]
            benchmarkSummaryTableViewController.benchmark = selectedBenchmark
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
}
