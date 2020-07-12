//
//  SaveRecordsViewController.swift
//  OmniPresence_AR
//
//  Created by Ravi kishore on 7/3/20.
//  Copyright © 2020 Indegene. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import VisionKit
import AVKit


class SaveRecordsViewController: UIViewController {

    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var arImageField: UITextField!
    @IBOutlet weak var titleField: UILabel!
    @IBOutlet weak var errorField: UILabel!
    var videoData = NSDictionary()
    var videoURL: URL!
    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!
    var originalImageURL: URL? {
          didSet {
              if let url = originalImageURL {
                  _ = UIImage(contentsOfFile: url.path)
              }
          }
      }
    var setTitle: String = ""
    var imageObservations: [String] = []
    var identifiers: String = ""
    var confidence: Float = 0.0
    var firebaseVideoUrl: String = ""


    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isTranslucent = true
        nameField.setBottomBorder()
        descriptionField.setBottomBorder()
        arImageField.setBottomBorder()
        if videoData.count > 0 {
            videoURL = URL(string: videoData["VideoUrl"] as? String ?? "")
            nameField.text = videoData["Name"] as? String ?? ""
            descriptionField.text = videoData["Description"] as? String ?? ""
            arImageField.text = videoData["ARImageName"] as? String ?? ""
        }
        playVideo(videoUrl: videoURL, to: videoView)
    }

    @IBAction func cancel() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func save() {
        if nameField.text?.count != 0 && descriptionField.text?.count != 0 && arImageField.text?.count != 0 {
            let arImageData = ARImageDataBase()
            arImageData.addOrUpdateDatabase(imageObs: imageObservations, identifiers: identifiers, confidence: confidence, videoUrl: firebaseVideoUrl, name: nameField.text ?? "temp",description: descriptionField.text ?? "temp", arImageName: arImageField.text ?? "temp", success: { [weak self] (success) in
                _ = self?.navigationController?.popViewController(animated: true)
            }) { [weak self] (error) in
                print(error.localizedDescription)
                _ = self?.navigationController?.popViewController(animated: true)
            }
        } else {
            errorField.isHidden = false
            if nameField.text == nil {
                errorField.text = "Name is required"
            } else if arImageField.text == nil {
                errorField.text = "AR Image Name is required"
            }
        }
   }
    
    @IBAction func takeARImage() {
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = self
        present(documentCameraViewController, animated: true)
      }
    
    
    /* Embedded player with controls */
    func playVideo(videoUrl: URL, to view: UIView) {
        let player = AVPlayer(url: videoUrl)
        let playerController = AVPlayerViewController()
        playerController.player = player
        self.addChild(playerController)
        // Add your view Frame
        playerController.view.frame = view.bounds
        // Add sub view in your view
        view.addSubview(playerController.view)
        player.play()
    }
}

extension SaveRecordsViewController {
    private func saveImage(_ image: UIImage) -> URL? {
        guard let imageData = image.pngData() else {
            return nil
        }
        let baseURL = FileManager.default.temporaryDirectory
        let imageURL = baseURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
        do {
            try imageData.write(to: imageURL)
            return imageURL
        } catch {
            print("Error saving image to \(imageURL.path): \(error)")
            return nil
        }
    }
    
    func featureprintObservationForImage(atURL url: URL) -> [VNClassificationObservation] {
          let requestHandler = VNImageRequestHandler(url: url, options: [:])
          let request = VNClassifyImageRequest()
          do {
              try requestHandler.perform([request])
            guard let observations = request.results as? [VNClassificationObservation] else { return [VNClassificationObservation]() }
            return observations
          } catch {
              print("Vision error: \(error)")
              return [VNClassificationObservation]()
          }
      }
    
    private func createImageModel(observations : [VNClassificationObservation], pathName: String) {
        for observation in observations {
            let imageData = ImageObservations(confidence: observation.confidence, identifier: observation.identifier)
            var jsonData = Data()
            do {
                jsonData = try imageData.jsonData()
            } catch {
                print("Error in converting to json data: \(error)")
            }
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                return
            }
            identifiers += observation.identifier
            imageObservations.append(jsonString)
            confidence += observation.confidence
        }
        confidence = confidence * 100
        uploadTOFireBaseVideo(url: videoURL, success: { [weak self] (downloadUrl) in
            if downloadUrl.count > 0 {
                self?.firebaseVideoUrl = downloadUrl
            }
        }) {(error) in
            print(error.localizedDescription)
        }
    }

    func uploadTOFireBaseVideo(url: URL,
                                      success : @escaping (String) -> Void,
                                      failure : @escaping (Error) -> Void) {

        let name = "\(Int(Date().timeIntervalSince1970)).mp4"
        let path = NSTemporaryDirectory() + name

        let data = NSData(contentsOf: url as URL)
        do {
            try data?.write(to: URL(fileURLWithPath: path), options: .atomic)
        } catch {
            print(error)
        }
        
        let arImageData = ARImageDataBase()
        arImageData.uploadVideoToStorage(name: name, data: data ?? NSData(), success: { (videoDownloadUrl) in
           success(videoDownloadUrl)
        }) { (error) in
            failure(error)
        }
    }
}

extension SaveRecordsViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        originalImageURL = saveImage(scan.imageOfPage(at: 0))
        let observations = featureprintObservationForImage(atURL: originalImageURL!)
        let searchObservations = observations.filter { $0.hasMinimumPrecision(0.2, forRecall: 0.8)}
        if searchObservations.count > 0 && searchObservations.first!.confidence > 0.2 {
            createImageModel(observations: searchObservations,pathName: searchObservations.first!.identifier + String(format: "%.1f", searchObservations.first!.confidence))
        }
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true) { [weak self] in
            self?.navigationController?.popToRootViewController(animated: true)
        }
    }
}
