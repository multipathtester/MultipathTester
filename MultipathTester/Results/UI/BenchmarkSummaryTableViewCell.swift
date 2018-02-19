//
//  BenchmarkDetailTableViewCell.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/10/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class BenchmarkSummaryTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
