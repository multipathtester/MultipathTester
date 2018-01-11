//
//  BenchmarkDetailTableViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/10/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

protocol StringTag {
    var string: String { get }
}

class BenchmarkSummaryTableViewController: UITableViewController {
    
    enum Tags: Int, StringTag {
        case None
        case BenchmarkDetailTableViewController
        case TestResultsTableViewController
        
        var string: String {
            switch self {
            case .None:
                return ""
            case .BenchmarkDetailTableViewController:
                return "BenchmarkDetailTableViewController"
            case .TestResultsTableViewController:
                return "TestResultsTableViewController"
            }
        }
    }
    
    struct TableItem {
        let title: String
        let detail: String
        let tag: Tags
    }
    
    var sections = Dictionary<String, Array<TableItem>>()
    var sortedSections = [String]()
    var benchmark: BenchmarkResult?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prepare sections
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM YYYY HH:mm:ss"
        dateFormatter.locale = .current
        
        sortedSections = ["Network", "Benchmark", "Tests"]
        sections["Network"] = [
            TableItem(title: "Network", detail: "WiFi + LTE (4G)", tag: .None),
            TableItem(title: "WiFi SSID", detail: "Cr4ckM31fUC4N", tag: .None),
            TableItem(title: "Cellular operator", detail: "Orange Improved", tag: .None),
        ]
        sections["Benchmark"] = [
            TableItem(title: "Time", detail: dateFormatter.string(from: Date(timeIntervalSince1970: benchmark!.startTime)), tag: .None),
            TableItem(title: "More details", detail: "ARROW", tag: .BenchmarkDetailTableViewController),
        ]
        sections["Tests"] = [
            TableItem(title: "Results", detail: "100 % (834/834)", tag: .None),
            TableItem(title: "Results details", detail: "ARROW", tag: .TestResultsTableViewController),
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
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[sortedSections[section]]!.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "BenchmarkSummaryTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? BenchmarkSummaryTableViewCell else {
            fatalError("The dequeued cell is not an instance of BenchmarkSummaryTableViewCell.")
        }
        
        let tableSection = sections[sortedSections[indexPath.section]]
        let tableItem = tableSection![indexPath.row]
        
        cell.titleLabel.text = tableItem.title
        if tableItem.detail == "ARROW" {
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.detailLabel.text = tableItem.detail
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortedSections[section]
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40.0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 55.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tableSection = sections[sortedSections[indexPath.section]]
        let tableItem = tableSection![indexPath.row]
        
        switch tableItem.tag {
        case .BenchmarkDetailTableViewController:
            guard let benchmarkDetailTableViewController = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(withIdentifier: "BenchmarkDetailTableViewController") as? BenchmarkDetailTableViewController else {
                fatalError("Could not instanciate BenchmarkDetailTableViewController")
            }
            benchmarkDetailTableViewController.benchmark = benchmark
            self.navigationController?.pushViewController(benchmarkDetailTableViewController, animated: true)
        case .TestResultsTableViewController:
            guard let testResultsTableViewController = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(withIdentifier: "TestResultsTableViewController") as? TestResultsTableViewController else {
                fatalError("Could not instanciate TestResultsTableViewController")
            }
            testResultsTableViewController.testResults = benchmark?.testResults
            self.navigationController?.pushViewController(testResultsTableViewController, animated: true)
        default:
            break
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
