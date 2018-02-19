//
//  TestResultInstancesTableViewCell.swift
//  QUICTester
//
//  Created by Quentin De Coninck on 1/12/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class TestResultInstancesTableViewCell: UITableViewCell {
    @IBOutlet weak var testNameLabel: UILabel!
    @IBOutlet weak var testDetailLabel: UILabel!
    @IBOutlet weak var successImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
