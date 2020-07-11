//
//  VideoPlaybackViewController.swift
//  OmniPresence_AR
//
//  Created by Ravi kishore on 5/22/20.
//  Copyright © 2020 Indegene. All rights reserved.
//

import UIKit
import AVFoundation
import SceneKit
import Vision
import VisionKit
import RealityKit
import ARKit


class VideoPlaybackViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var videoView: UIView!
    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!
    var videoURL: URL!
    var progressHUD: ProgressHUD?
    var imageUrl: URL!
    var originalImageURL: URL? {
         didSet {
             if let url = originalImageURL {
                 _ = UIImage(contentsOfFile: url.path)
             }
         }
     }
    override func viewDidLoad() {
        super.viewDidLoad()
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.frame = view.bounds
        //avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        //videoView.layer.insertSublayer(avPlayerLayer, at: 0)
        self.view.layer.addSublayer(avPlayerLayer)

         //view.layoutIfNeeded()

        let playerItem = AVPlayerItem(url: videoURL as URL)
        avPlayer.replaceCurrentItem(with: playerItem)

//        avPlayer.play()
        
        progressHUD = ProgressHUD(text: "Saving Photo")
        self.view.addSubview(progressHUD ?? UIView())
        self.view.backgroundColor = UIColor.black
        progressHUD?.hide()
    }
        
    @IBAction func cancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save() {
        guard let saveViewController = storyboard?.instantiateViewController(withIdentifier: "saveRecord") as? SaveRecordsViewController else { return }
        saveViewController.videoURL = self.videoURL
        self.navigationController?.pushViewController(saveViewController, animated: true)
    }
    
    func uploadToAzure(name: String, imageUrl: URL) {
        let azureService = AzureServiceViewController()
        azureService.uploadToAzure(name: name, videoUrl: videoURL, imageUrl: imageUrl, completion: { [weak self] (_) in
            self?.progressHUD?.hide()
        })
    }

        @objc func scanDocument() {
            let documentCameraViewController = VNDocumentCameraViewController()
            documentCameraViewController.delegate = self
            present(documentCameraViewController, animated: true)
        }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

extension VideoPlaybackViewController: VNDocumentCameraViewControllerDelegate {
//    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
//        originalImageURL = saveImage(scan.imageOfPage(at: 0))
//        let observations = featureprintObservationForImage(atURL: originalImageURL!)
//        let searchObservations = observations.filter { $0.hasMinimumPrecision(0.2, forRecall: 0.8)}
//        if searchObservations.count > 0 && searchObservations.first!.confidence > 0.2 {
//            createImageModel(observations: searchObservations,pathName: searchObservations.first!.identifier + String(format: "%.1f", searchObservations.first!.confidence))
//        }
//        controller.dismiss(animated: true)
//        progressHUD?.show()
//    }
//    
//    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
//        controller.dismiss(animated: true) { [weak self] in
//            self?.navigationController?.popToRootViewController(animated: true)
//        }
//    }
}

//extension VideoPlaybackViewController {
//    private func saveImage(_ image: UIImage) -> URL? {
//        guard let imageData = image.pngData() else {
//            return nil
//        }
//        let baseURL = FileManager.default.temporaryDirectory
//        let imageURL = baseURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
//        do {
//            try imageData.write(to: imageURL)
//            return imageURL
//        } catch {
//            print("Error saving image to \(imageURL.path): \(error)")
//            return nil
//        }
//    }
//
//    func featureprintObservationForImage(atURL url: URL) -> [VNClassificationObservation] {
//          let requestHandler = VNImageRequestHandler(url: url, options: [:])
//          let request = VNClassifyImageRequest()
//          do {
//              try requestHandler.perform([request])
//            guard let observations = request.results as? [VNClassificationObservation] else { return [VNClassificationObservation]() }
//            return observations
//          } catch {
//              print("Vision error: \(error)")
//              return [VNClassificationObservation]()
//          }
//      }
//
//    private func createImageModel(observations : [VNClassificationObservation], pathName: String) {
//        var arrayOfObservations = [String]()
//        var arrayOfIdentifiers: String = ""
//        var confidence: Float = 0.0
//        for observation in observations {
//            let imageData = ImageObservations(confidence: observation.confidence, identifier: observation.identifier)
//            var jsonData = Data()
//            do {
//                jsonData = try imageData.jsonData()
//            } catch {
//                print("Error in converting to json data: \(error)")
//            }
//            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
//                return
//            }
//            arrayOfIdentifiers += observation.identifier
//            arrayOfObservations.append(jsonString)
//            confidence += observation.confidence
//        }
//        confidence = confidence * 100
//        uploadTOFireBaseVideo(url: videoURL, success: { (downloadUrl) in
//            if downloadUrl.count > 0 {
//                let arImageData = ARImageDataBase()
//
//                arImageData.addOrUpdateDatabase(imageObs: arrayOfObservations, identifiers: arrayOfIdentifiers, confidence: confidence, videoUrl: downloadUrl, success: { [weak self] (success) in
//                    self?.progressHUD?.hide()
//                    _ = self?.navigationController?.popViewController(animated: true)
//                }) { [weak self] (error) in
//                    self?.progressHUD?.hide()
//                    print(error.localizedDescription)
//                    _ = self?.navigationController?.popViewController(animated: true)
//                }
//            }
//        }) { [weak self](error) in
//            self?.progressHUD?.hide()
//            print(error.localizedDescription)
//        }
//        progressHUD?.hide()
//    }
//
//    func uploadTOFireBaseVideo(url: URL,
//                                      success : @escaping (String) -> Void,
//                                      failure : @escaping (Error) -> Void) {
//
//        let name = "\(Int(Date().timeIntervalSince1970)).mp4"
//        let path = NSTemporaryDirectory() + name
//
//        let data = NSData(contentsOf: url as URL)
//        do {
//            try data?.write(to: URL(fileURLWithPath: path), options: .atomic)
//        } catch {
//            print(error)
//        }
//
//        let arImageData = ARImageDataBase()
//        arImageData.uploadVideoToStorage(name: name, data: data ?? NSData(), success: { (videoDownloadUrl) in
//           success(videoDownloadUrl)
//        }) { (error) in
//            failure(error)
//        }
//    }
//}
