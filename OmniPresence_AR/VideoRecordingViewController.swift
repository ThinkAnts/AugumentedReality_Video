//
//  VideoRecordingViewController.swift
//  OmniPresence_AR
//
//  Created by Ravi kishore on 5/22/20.
//  Copyright © 2020 Indegene. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

class VideoRecordingViewController: UIViewController {

    var imagePickerController = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
         
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let vc = segue.destination as! VideoPlaybackViewController
        vc.videoURL = sender as? URL
    }
}


extension VideoRecordingViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let videoURL = info[.mediaURL] as? URL else {
            return imagePickerController.dismiss(animated: true, completion: nil)
        }
        //performSegue(withIdentifier: "showVideo", sender: videoURL)
        guard let saveViewController = storyboard?.instantiateViewController(withIdentifier: "saveRecord") as? SaveRecordsViewController else { return }
        saveViewController.videoURL = videoURL
        saveViewController.setTitle = "Save AR Video"
        saveViewController.enableEditButton = true
        saveViewController.isUpdating = false
        self.navigationController?.pushViewController(saveViewController, animated: true)
         imagePickerController.dismiss(animated: true, completion: nil)
    }
}

extension VideoRecordingViewController {
    
    @IBAction func uploadFromLibrary() {
            imagePickerController.sourceType = .photoLibrary
            imagePickerController.delegate = self
            imagePickerController.mediaTypes = ["public.movie"]
            present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func takeAVideo() {
        // 1 Check if project runs on a device with camera available
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            
            // 2 Present UIImagePickerController to take video
            imagePickerController.sourceType = .camera
            imagePickerController.mediaTypes = [kUTTypeMovie as String]
            imagePickerController.delegate = self
            
            present(imagePickerController, animated: true, completion: nil)
        }
        else {
            print("Camera is not available")
        }
    }
    
}
