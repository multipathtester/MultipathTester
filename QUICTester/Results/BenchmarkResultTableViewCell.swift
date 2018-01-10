//
//  BenchmarkResultTableViewCell.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 12/1/17.
//  Copyright © 2017 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class BenchmarkResultTableViewCell: UITableViewCell {
    // MARK: Properties
    @IBOutlet weak var networkImageView: UIImageView!
    @IBOutlet weak var testTypeLabel: UILabel!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var tcpResultsLabel: UILabel!
    @IBOutlet weak var quicResultsLabel: UILabel!
    @IBOutlet weak var pingResultsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
