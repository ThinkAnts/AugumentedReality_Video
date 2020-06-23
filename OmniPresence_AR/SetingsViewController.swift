//
//  SetingsViewController.swift
//  OmniPresence_AR
//
//  Created by Ravi kishore on 5/23/20.
//  Copyright © 2020 Indegene. All rights reserved.
//

import UIKit

class SetingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var settingsCell:UITableViewCell!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        5
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? SettingsCell else {return UITableViewCell()}
         
        if indexPath.row == 0 {
            cell.title.text = "Profile"
        } else if indexPath.row == 1 {
             cell.title.text = "Plans"
        } else if indexPath.row == 2 {
             cell.title.text = "Recording Library"
        } else if indexPath.row == 3 {
            cell.title.text = "Data and Storage"
        } else if indexPath.row == 4 {
            cell.title.text = "Help"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 2 {
            guard let recordingVC = storyboard?.instantiateViewController(identifier: "RecordingVC") as? RecordingViewController else { return }
            navigationController?.pushViewController(recordingVC, animated: true)
        }
    }
}
 

class SettingsCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
}
