//
//  TestResultTableViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/1/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class TestResultsTableViewController: UITableViewController {
    // MARK: Properties
    /*
     This value is passed by `MealTableViewController` in `prepare(for:sender:)`
     */
    struct TableItem {
        let title: String
        let nbSuccess: Int
        let testResults: [TestResult]
    }
    
    var testResults: [TestResult]?
    var sortedSections = ["TCP", "QUIC"]
    var items = [String: [TableItem]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        let resultDict = getTableDict()
        
        for k in resultDict.keys {
            items[k] = [TableItem]()
            for t in resultDict[k]!.keys {
                let testResults = resultDict[k]![t]
                var succeeded = 0
                for tr in testResults! {
                    if tr.succeeded() {
                        succeeded += 1
                    }
                }
                items[k]?.append(TableItem(title: t, nbSuccess: succeeded, testResults: testResults!))
            }
        }
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
        return items.keys.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let _ = testResults else {
            return 0
        }
        if items.keys.count == 1 {
            let key = items.keys.first
            return items[key!]!.count
        }
        return items[sortedSections[section]]!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "TestResultsTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TestResultsTableViewCell else {
            fatalError("The dequeued cell is not an instance of TestResultsTableViewCell.")
        }
        
        var sectionName: String = ""
        if items.keys.count == 1 {
            sectionName = items.keys.first!
        } else {
            sectionName = sortedSections[indexPath.section]
        }
        
        let tableItem = items[sectionName]![indexPath.row]
        
        // Fetches the appropriate testResult for the data source layout
        cell.nameLabel.text = tableItem.title
        cell.resultLabel.text = String(tableItem.nbSuccess) + "/" + String(tableItem.testResults.count)
        
        let bundle = Bundle(for: type(of: self))
        let ok = UIImage(named: "ok", in: bundle, compatibleWith: self.traitCollection)
        let failed = UIImage(named: "error", in: bundle, compatibleWith: self.traitCollection)
        
        if tableItem.nbSuccess == tableItem.testResults.count {
            cell.sucessImageView.image = ok
        } else {
            cell.sucessImageView.image = failed
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if items.keys.count == 1 {
            return items.keys.first
        }
        return sortedSections[section]
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40.0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 55.0
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
        case "ShowTestResultInstances":
            guard let testResultInstancesTableViewController = segue.destination as? TestResultInstancesTableViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedTestResultCell = sender as? TestResultsTableViewCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedTestResultCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            var sectionName: String = ""
            if items.keys.count == 1 {
                sectionName = items.keys.first!
            } else {
                sectionName = sortedSections[indexPath.section]
            }
            let tableItem = items[sectionName]![indexPath.row]
            
            var detailText: String = ""
            switch tableItem.title {
            case ConnectivityResult.getTestName():
                detailText = ConnectivityResult.getTestDescription()
            case BulkDownloadResult.getTestName():
                detailText = BulkDownloadResult.getTestDescription()
            case ReqResResult.getTestName():
                detailText = ReqResResult.getTestDescription()
            case PerfResult.getTestName():
                detailText = PerfResult.getTestDescription()
            case StreamResult.getTestName():
                detailText = StreamResult.getTestDescription()
            default:
                fatalError("Unknown test name " + tableItem.title)
            }
            
            testResultInstancesTableViewController.detailText = detailText
            testResultInstancesTableViewController.testResults = tableItem.testResults
            testResultInstancesTableViewController.navigationTitle = sectionName + " " + tableItem.title
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    
    // MARK: Private
    func getTableDict() -> [String: [String: [TestResult]]] {
        var dict = [String: [String: [TestResult]]]()
        for k in dict.keys {
            dict[k] = [
                ConnectivityResult.getTestName(): [TestResult](),
                BulkDownloadResult.getTestName(): [TestResult](),
                ReqResResult.getTestName(): [TestResult](),
                PerfResult.getTestName(): [TestResult](),
                StreamResult.getTestName(): [TestResult](),
            ]
        }
        
        for t in testResults! {
            let proto = t.getProtocol().main.rawValue
            if dict[proto] == nil {
                dict[proto] = [String: [TestResult]]()
            }
            let testName = type(of: t).getTestName()
            if dict[proto]![testName] == nil {
                dict[proto]![testName] = [TestResult]()
            }
            dict[proto]![testName]!.append(t)
        }

        return dict
    }

}
