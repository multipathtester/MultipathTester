//
//  TestResultInstancesTableViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/12/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class TestResultInstancesTableViewController: UITableViewController {
    
    var detailText: String?
    var testResults: [TestResult]?
    var navigationTitle: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = navigationTitle
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return testResults!.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Details"
        }
        return "Tests"
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return CGFloat(20.0 * (Double(detailText!.count) / 50.0)) + 20.0
        }
        return 60.0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45.0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cellIdentifier = "TestResultDetailTableViewCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TestResultDetailTableViewCell else {
                fatalError("The dequeued cell is not an instance of TestResultDetailTableViewCell.")
            }
            
            cell.detailLabel.text = detailText
            return cell
        }
        
        let cellIdentifier = "TestResultInstancesTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TestResultInstancesTableViewCell else {
            fatalError("The dequeued cell is not an instance of TestResultInstancesTableViewCell.")
        }
        
        let testResult = testResults![indexPath.row]
        cell.testNameLabel.text = "Test #" + String(indexPath.row + 1)
        cell.testDetailLabel.text = testResult.getDescription()
        
        let bundle = Bundle(for: type(of: self))
        let ok = UIImage(named: "ok", in: bundle, compatibleWith: self.traitCollection)
        let failed = UIImage(named: "error", in: bundle, compatibleWith: self.traitCollection)

        if testResult.succeeded() {
            cell.successImageView.image = ok
        } else {
            cell.successImageView.image = failed
        }

        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
        case "ShowTestInstanceDetail":
            guard let testResultInstanceDetailTableViewController = segue.destination as? TestResultInstanceDetailTableViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedTestResultCell = sender as? TestResultInstancesTableViewCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedTestResultCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            testResultInstanceDetailTableViewController.testResult = testResults?[indexPath.row]
        default:
            fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }

}
