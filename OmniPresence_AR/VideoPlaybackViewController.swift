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

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet var imageView: BoundingBoxImageView!
    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!
    var videoURL: URL!
    var progressHUD: ProgressHUD?
    var imageUrl: URL!

    
    // MARK: Authentication
    
//    // If using a SAS token, fill it in here.  If using Shared Key access, comment out the following line.
//    var containerURL = "https://arresources.blob.core.windows.net/arvideocontainer?sv=2019-10-10&ss=bfqt&srt=sco&sp=rwdlacupx&se=2020-06-19T17:36:36Z&st=2020-06-14T09:36:36Z&spr=https&sig=3YECYmscCInBlnZdpJoHsoy4cnKluq%2FKnGtCwb4ZG0o%3D"
//    var usingSAS = true
//
//    // If using Shared Key access, fill in your credentials here and un-comment the "UsingSAS" line:
//    var connectionString = "DefaultEndpointsProtocol=https;AccountName=arresources;AccountKey=zr+kJ5squREEy9PpiqZVHUTZurXaoZfRcNo49sLMjtdqZDTtMNQVSmg/ThuL+uLYTVrleMSZ8s4+5st1nXZ1vg==;EndpointSuffix=core.windows.net"
//    var containerName = "arvideocontainer"
//    var blobs = [AZSCloudBlob]()
//    var container : AZSCloudBlobContainer
//    var continuationToken : AZSContinuationToken?
    
    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    private let textRecognitionWorkQueue = DispatchQueue(label: "TextRecognitionQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
        
    // MARK: Initializers
    
//    required init?(coder aDecoder: NSCoder) {
//        if (usingSAS) {
//            var error: NSError?
//            self.container = AZSCloudBlobContainer(url: URL(string: containerURL)!, error: &error)
//            if ((error) != nil) {
//                print("Error in creating blob container object.  Error code = %ld, error domain = %@, error userinfo = %@", error!.code, error!.domain, error!.userInfo);
//            }
//        }
//        else {
//            //            do {
//            let storageAccount : AZSCloudStorageAccount;
//            try! storageAccount = AZSCloudStorageAccount(fromConnectionString: connectionString)
//            let blobClient = storageAccount.getBlobClient()
//            self.container = blobClient.containerReference(fromName: containerName)
//
//            let condition = NSCondition()
//            var containerCreated = false
//
//            self.container.createContainerIfNotExists { (error : Error?, created) -> Void in
//                condition.lock()
//                containerCreated = true
//                condition.signal()
//                condition.unlock()
//            }
//
//            condition.lock()
//            while (!containerCreated) {
//                condition.wait()
//            }
//            condition.unlock()
//        }
//
//        self.continuationToken = nil
//        super.init(coder: aDecoder)
//    }
    
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
        
        imageView.layer.cornerRadius = 10.0
        //scanButton.layer.cornerRadius = 10.0
        
        sceneView.delegate = self

        setupVision()
    }
        
    @IBAction func cancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save() {
 // create the alert
        let alert = UIAlertController(title: "Thumbnail Image", message: "Please set a thumbnail image ", preferredStyle: UIAlertController.Style.alert)

        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: {[weak self] (_: UIAlertAction!) in
            self?.scanDocument()
           }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))

        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    func uploadToAzure(name: String, imageUrl: URL) {
        let azureService = AzureServiceViewController()
        azureService.uploadToAzure(name: name, videoUrl: videoURL, imageUrl: imageUrl, completion: { [weak self] (_) in
            self?.progressHUD?.hide()
        })
    }
    
        /// Setup the Vision request as it can be reused
        private func setupVision() {
            textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                
                var detectedText = ""
                var boundingBoxes = [CGRect]()
                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { return }
                    
                    detectedText += topCandidate.string
                    detectedText += "\n"
                    
                    do {
                        guard let rectangle = try topCandidate.boundingBox(for: topCandidate.string.startIndex..<topCandidate.string.endIndex) else { return }
                        boundingBoxes.append(rectangle.boundingBox)
                    } catch {
                        // You should handle errors appropriately in your app
                        print(error)
                    }
                }
                
                DispatchQueue.main.async {
                    self.progressHUD?.show()
                    print(detectedText.prefix(5))
                    self.uploadToAzure(name: String(detectedText.prefix(5)), imageUrl: self.imageUrl)
                    self.imageView.load(boundingBoxes: boundingBoxes)
                }
            }
            textRecognitionRequest.recognitionLevel = .accurate
        }
        
        /// Shows a `VNDocumentCameraViewController` to let the user scan documents
        @objc func scanDocument() {
            let scannerViewController = VNDocumentCameraViewController()
            scannerViewController.delegate = self
            present(scannerViewController, animated: true)
        }
    // MARK: - Scan Handling
     
     /// Processes the image by displaying it and extracting text which is shown to the user
     /// - Parameter image: A `UIImage` to process
     private func processImage(_ image: UIImage) {
         imageView.image = image
         imageView.removeExistingBoundingBoxes()
         storeToImagePath(image)
         recognizeTextInImage(image)
     }
    
    private func storeToImagePath(_ image: UIImage) {
        let filename = getDocumentsDirectory().appendingPathComponent("copy.png")
        if let data = image.jpegData(compressionQuality: 0.8) {
               try? data.write(to: filename)
        }
 
        imageUrl = filename
    }
     
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
     /// Recognizes and displays the text from the image
     /// - Parameter image: `UIImage` to process and perform OCR on
     private func recognizeTextInImage(_ image: UIImage) {
         guard let cgImage = image.cgImage else { return }
         
         //textView.text = ""
         textRecognitionWorkQueue.async {
             let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
             do {
                 try requestHandler.perform([self.textRecognitionRequest])
                 
             } catch {
                 print(error)
             }
         }
     }
    
    func reloadedImage(_ originalImage: UIImage) -> UIImage {
           guard let imageData = originalImage.jpegData(compressionQuality: 1),
               let reloadedImage = UIImage(data: imageData) else {
                   return originalImage
           }
           return reloadedImage
       }
}

extension VideoPlaybackViewController: VNDocumentCameraViewControllerDelegate {

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        guard scan.pageCount >= 1 else {
            controller.dismiss(animated: true)
            return
        }
        let originalImage = scan.imageOfPage(at: 0)
        let fixedImage = reloadedImage(originalImage)
        
        controller.dismiss(animated: true)
        
        processImage(fixedImage)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print(error)
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }
}
