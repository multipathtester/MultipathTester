//
//  MobileSettingsTableViewCell.swift
//  MultipathTester
//
//  Created by Quentin De Coninck on 4/27/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

import UIKit

class MobileSettingsTableViewCell: UITableViewCell {

    @IBOutlet weak var settingsLabel: UILabel!
    @IBOutlet weak var settingsSwitch: UISwitch!
    var settingsKey: String?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func toggleSwitch(_ sender: Any) {
        if let key = settingsKey {
            UserDefaults.standard.set(settingsSwitch.isOn, forKey: key)
        }
    }
}
