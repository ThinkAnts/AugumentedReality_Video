//
//  RecordingViewController.swift
//  OmniPresence_AR
//
//  Created by Ravi kishore on 5/31/20.
//  Copyright © 2020 Indegene. All rights reserved.
//

import UIKit


class RecordingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var recordingTableView: UITableView!
    @IBOutlet weak var preLoaderImage: UIImageView!

    var resultsArray = [NSDictionary]()
    override func viewDidLoad() {
        super.viewDidLoad()
        recordingTableView.tableFooterView = UIView()
        getDataFromFireBase()
        preLoaderImage.image = UIImage.gif(name: "45")
        if resultsArray.count > 0 {
            recordingTableView.isHidden = false
        } else {
            recordingTableView.isHidden = true
        }
    }
    
    func getDataFromFireBase() {
        preLoaderImage.isHidden = false
        let arImageData = ARImageDataBase()
        arImageData.fetchAllDataFromFireBase(success: { [weak self] (results) in
            if results.count > 0 {
                self?.resultsArray = results
                self?.recordingTableView.reloadData()
                self?.preLoaderImage.isHidden = true
                self?.recordingTableView.isHidden = false
            }
        }) { [weak self](error) in
            self?.preLoaderImage.isHidden = true
            self?.recordingTableView.isHidden = true
            print(error.localizedDescription)
        }
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "recordingCell", for: indexPath) as? RecordingLibraryCell else {return UITableViewCell()}
        let dic = resultsArray[indexPath.row]
        cell.recordingTitle.text = dic["Name"] as? String 
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = resultsArray[indexPath.row]
        guard let saveViewController = storyboard?.instantiateViewController(withIdentifier: "saveRecord") as? SaveRecordsViewController else { return }
        saveViewController.videoData = data
        saveViewController.setTitle = "Edit AR Video"
        self.navigationController?.pushViewController(saveViewController, animated: true)
    }
}

class RecordingLibraryCell: UITableViewCell {
    @IBOutlet weak var recordingTitle: UILabel!
}
