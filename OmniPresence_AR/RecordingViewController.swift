//
//  RecordingViewController.swift
//  OmniPresence_AR
//
//  Created by Ravi kishore on 5/31/20.
//  Copyright © 2020 Indegene. All rights reserved.
//

import UIKit

class RecordingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var recordingTableView:UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        recordingTableView.tableFooterView = UIView()
        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        5
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "recordingCell", for: indexPath) as? RecordingLibraryCell else {return UITableViewCell()}
        cell.recordingTitle.text = "Recording"
        return cell
    }
}

class RecordingLibraryCell: UITableViewCell {
    @IBOutlet weak var recordingTitle: UILabel!
}
