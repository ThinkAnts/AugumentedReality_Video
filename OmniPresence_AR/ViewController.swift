//
//  ViewController.swift
//  OmniPresence_AR
//
//  Created by Ravi kishore on 5/22/20.
//  Copyright © 2020 Indegene. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import SwiftGifOrigin
import CocoaImageHashing
import Vision
import VisionKit
import RealityKit

class ViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var scanningImage: UIImageView!
    @IBOutlet var imageView: BoundingBoxImageView!
    var requiredImage: UIImage?
    var firstData: Data?
    var fileUrlString: URL?
    var newReferenceImages:Set<ARReferenceImage> = Set<ARReferenceImage>()
    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    private let textRecognitionWorkQueue = DispatchQueue(label: "TextRecognitionQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    var originalImageURL: URL? {
        didSet {
            if let url = originalImageURL {
                requiredImage = UIImage(contentsOfFile: url.path)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scanningImage.image = UIImage.gif(name: "scanner")
        sceneView.delegate = self
        showScanner(isVisible: false)
        //scanButton.isHidden = false
        sceneView.isHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if sceneView.isHidden == false {
            sceneView.isHidden = true
        }
        
        if scanButton.isHidden == true {
            scanButton.isHidden = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        resetTracking()
        if sceneView.isHidden == false {
            sceneView.isHidden = true
        }
    }
    
    func loadARView() {
        if sceneView.isHidden == true {
            sceneView.isHidden = false
        }
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = newReferenceImages
        configuration.maximumNumberOfTrackedImages = 1;
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration)
    }
    
    
//    public func resetTracking() {
//        let configuration = ARWorldTrackingConfiguration()
//        configuration.detectionImages = newReferenceImages;
//        configuration.maximumNumberOfTrackedImages = 1;
//        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
//    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        resetTracking()
    }
    private func resetTracking() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.vertical, .horizontal]
        sceneView.scene.rootNode.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
        sceneView.session.run(config, options: [.removeExistingAnchors,
                                             .resetTracking, ])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func showScanner(isVisible: Bool) {
        if isVisible {
            scanningImage.isHidden = false
        } else {
            scanningImage.isHidden = true
        }
    }
    
    @IBAction func scanImage() {
        //scanDocument()
        showCameraView()
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let imageAnchor = anchor as? ARImageAnchor else { return nil }
        //let filePath = Bundle.main.url(forResource: "Test", withExtension: "mp4")
        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
//        guard let urlSt = URL(string: "https:/firebasestorage.googleapis.com/v0/b/omni-ar.appspot.com/o/Videos%252F1593328648.mp4%3Falt=media&token=cbdc0113-5ede-4d6d-9bd0-c3ea97f8a8be -- file:///") else { return nil }
        let videoItem = AVPlayerItem(url:fileUrlString!)
        let player = AVPlayer(playerItem: videoItem)
        let videoNode = SKVideoNode(avPlayer: player)
        player.play()
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { [weak self] (notification) in
            self?.scanButton.isHidden = false
            self?.sceneView.isHidden = true
            
        }
        
        
        let videoScene = SKScene(size: CGSize(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height))
        videoScene.backgroundColor = UIColor.clear
        videoNode.position = CGPoint(x: videoScene.size.width / 2, y: videoScene.size.height / 2)
        videoNode.yScale = 1.0
        videoScene.addChild(videoNode)
        plane.firstMaterial?.diffuse.contents = videoScene
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2
        DispatchQueue.main.async {
            self.showScanner(isVisible: false)
            self.scanButton.isHidden = true
        }
        
        let node = SCNNode()
        node.addChildNode(planeNode)
        return node
    }

}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
{

 func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
    guard let image = info[.originalImage] as? UIImage else {
            print("No image found")
            return
        }

        if image.imageAsset != nil {
            let arImage = ARReferenceImage(image.cgImage!, orientation: CGImagePropertyOrientation.up, physicalWidth: 480.0)
            arImage.name = "Test";
            let str = String((image.pngData()?.base64EncodedString().prefix(30))!)
            print(str)
//            newReferenceImages.insert(arImage);
//            sceneView.isHidden = false
//            self.loadARView();
        }
    }
}

extension ViewController {
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
                    print(detectedText.prefix(5))
                    self.downloadFromAzure(name: String(detectedText.prefix(5)))
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
         
         recognizeTextInImage(image)
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
    
    func downloadFromAzure(name: String) {
        let azureService = AzureServiceViewController()
        showScanner(isVisible: true)
        azureService.downLoadVideoFromAzure(name: name, completion: { [weak self] (videoPath) in
            self?.fileUrlString = videoPath
            azureService.downloadImageFromAzure(name: name, completion: { [weak self] (data) in
                   if data.count != 0 {
                       let requiredImage = UIImage(data: data)
                    let arImage = ARReferenceImage((requiredImage?.cgImage!)!, orientation: CGImagePropertyOrientation.up, physicalWidth: 480.0)
                       self?.newReferenceImages.insert(arImage)
                    DispatchQueue.main.async {
                        self?.loadARView();
                    }
                   }
               })
        })
    }
    
    func downloadImageFromAzure(name: String) {
   

    }
}

extension ViewController {
   
    func showCameraView() {
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = self
        present(documentCameraViewController, animated: true)
    }
    
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
    
    private func fetchImageData(confidence: Float, identifiers: String) {
        showScanner(isVisible: true)
        let arImageData = ARImageDataBase()
        arImageData.retrieveFromDatabase(confidence: confidence, identifiers: identifiers, success: { [weak self] (videoUrl) in
            let arImage = ARReferenceImage((self?.requiredImage?.cgImage!)!, orientation: CGImagePropertyOrientation.up, physicalWidth: 480.0)
                    self?.newReferenceImages.insert(arImage)
                 DispatchQueue.main.async {
                    if videoUrl.count != 0 {
                        self?.fileUrlString = URL(string: videoUrl)
                        self?.loadARView();
                        self?.scanButton.isHidden = true
                    } else {
                        self?.sceneView.isHidden = true
                        self?.showScanner(isVisible: false)
                        self?.scanButton.isHidden = false
                    }
            }
        }) { [weak self](error) in
            self?.sceneView.isHidden = true
            self?.showScanner(isVisible: false)
            self?.scanButton.isHidden = false
            print(error.localizedDescription)
        }
    }
    
    private func showErrorAlert() {
        let alert = UIAlertController(title: "Image is not proper", message: "Please choose good quality image", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func createImageModel(observations : [VNClassificationObservation]) {
        var arrayOfObservations = [String]()
        var identifiersString: String = ""
        var confidence: Float = 0.0
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
            identifiersString += observation.identifier
            arrayOfObservations.append(jsonString)
            confidence += observation.confidence
        }
        confidence = confidence * 100
        fetchImageData(confidence: confidence, identifiers: identifiersString)
    }
}

extension ViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        originalImageURL = saveImage(scan.imageOfPage(at: 0))
        let observations = featureprintObservationForImage(atURL: originalImageURL!)
        let searchObservations = observations.filter { $0.hasMinimumPrecision(0.2, forRecall: 0.8)}
        if searchObservations.count > 0 && searchObservations.first!.confidence > 0.3 {
            createImageModel(observations: searchObservations)
        } else {
            showErrorAlert()
        }
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true) { [weak self] in
            self?.sceneView.isHidden = true
            self?.navigationController?.popToRootViewController(animated: true)
        }
    }
}
