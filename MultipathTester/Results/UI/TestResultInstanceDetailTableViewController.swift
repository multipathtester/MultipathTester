//
//  TestResultInstanceDetailTableViewController.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/12/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Charts

class TestResultInstanceDetailTableViewController: UITableViewController, ChartViewDelegate {
    
    var testResult: TestResult?
    var chartValues: [ChartEntries] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        chartValues = testResult!.getChartData()

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
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            return chartValues.count
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Description"
        }
        if section == 1 {
            return "Succeeded"
        }
        return "Details"
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 2 {
            let screenSize: CGRect = UIScreen.main.bounds
            return screenSize.width - 10
        }
        if indexPath.section == 0 { // Test description
            return CGFloat(20.0 * (Double(testResult!.getDescription().count) / 40.0)) + 20.0
        }
        // section 1, result
        return CGFloat(20.0 * (Double(testResult!.getResult().count) / 40.0)) + 40.0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45.0
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 2 {
            let cellIdentifier = "TestResultInstanceDetailLineChartTableViewCell"
            guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TestResultInstanceDetailLineChartTableViewCell else {
                    fatalError("The dequeued cell is not an instance of TestResultInstanceDetailLineChartTableViewCell.")
            }
            switch chartValues[indexPath.row].type {
            case .lineChartEntries:
                let lineChartEntries = chartValues[indexPath.row] as! LineChartEntries
                LineChartHelper.initialize(chartView: cell.chart, delegate: self, xValueFormatter: lineChartEntries.xValueFormatter)
                LineChartHelper.setData(to: cell.chart, with: lineChartEntries.data, label: lineChartEntries.dataLabel, color: UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1), mode: .linear)
                cell.chart.animate(xAxisDuration: 2)
                cell.xAxisTitleLabel.text = lineChartEntries.xLabel
                // Rotate Y axis
                cell.yAxisTitleLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
                cell.yAxisTitleLabel.text = lineChartEntries.yLabel
            case .multiLineChartEntries:
                let colors = [
                    UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1),
                    UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1),
                    UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1)
                ]
                let multiLineChartEntries = chartValues[indexPath.row] as! MultiLineChartEntries
                LineChartHelper.initialize(chartView: cell.chart, delegate: self, xValueFormatter: DateValueFormatter())
                for (index, k) in multiLineChartEntries.dataLines.keys.enumerated() {
                    LineChartHelper.setData(to: cell.chart, with: multiLineChartEntries.dataLines[k]!, label: k, color: colors[index], mode: .linear)
                }
                cell.chart.animate(xAxisDuration: 2)
                cell.xAxisTitleLabel.text = multiLineChartEntries.xLabel
                // Rotate Y axis
                cell.yAxisTitleLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
                cell.yAxisTitleLabel.text = multiLineChartEntries.yLabel
            }
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TestResultInstanceDetailTextTableViewCell", for: indexPath) as? TestResultInstanceDetailTextTableViewCell else {
            fatalError("The dequeued cell is not an instance of TestResultInstanceDetailTextTableViewCell.")
        }
        
        if indexPath.section == 0 {
            cell.detailLabel.text = testResult?.getDescription()
        } else { // section == 1
            cell.detailLabel.text = testResult?.getResult()
            if (testResult?.succeeded())! {
                cell.backgroundColor = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
            } else {
                cell.backgroundColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
            }
        }

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
