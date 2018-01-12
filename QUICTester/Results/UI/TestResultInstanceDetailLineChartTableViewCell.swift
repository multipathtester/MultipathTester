//
//  TestResultInstanceDetailChartTableViewCell.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/12/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit
import Charts

class TestResultInstanceDetailLineChartTableViewCell: UITableViewCell {
    @IBOutlet weak var chart: LineChartView!
    @IBOutlet weak var xAxisTitleLabel: UILabel!
    @IBOutlet weak var yAxisTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
