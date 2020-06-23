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
    var firstData: Data?
    var fileUrlString: URL?
    var newReferenceImages:Set<ARReferenceImage> = Set<ARReferenceImage>()
    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    private let textRecognitionWorkQueue = DispatchQueue(label: "TextRecognitionQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scanningImage.image = UIImage.gif(name: "22494-scan-animation")
        sceneView.delegate = self
        showScanner(isVisible: false)
        //scanButton.isHidden = false
        sceneView.isHidden = false
        setupVision()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //loadARView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        resetTracking()
    }
    
    func loadARView() {
        let configuration = ARImageTrackingConfiguration()
        guard let trackedImages = ARReferenceImage.referenceImages(inGroupNamed: "AR", bundle: nil) else {
            fatalError("Couldn't load tracking images.")
        }
        configuration.trackingImages = newReferenceImages
        sceneView.session.run(configuration)
    }
    
    
    public func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = newReferenceImages;
        configuration.maximumNumberOfTrackedImages = 1;
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func showScanner(isVisible: Bool) {
        if isVisible {
            scanningImage.isHidden = false
            scanButton.isHidden = true
        } else {
            scanningImage.isHidden = true
            scanButton.isHidden = false
        }
    }
    
    @IBAction func scanImage() {
        scanDocument()
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let imageAnchor = anchor as? ARImageAnchor else { return nil }
//        guard let fileUrlString = Bundle.main.path(forResource: "Test", ofType: "mp4") else {
//            debugPrint("video not found")
//            return nil
//        }
        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
        let videoItem = AVPlayerItem(url: fileUrlString!)
        let player = AVPlayer(playerItem: videoItem)
        let videoNode = SKVideoNode(avPlayer: player)
        player.play()
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { (notification) in
            player.seek(to: CMTime.zero)
            player.play()
        }
        
        
        let videoScene = SKScene(size: CGSize(width: 480, height: 360))
        videoNode.position = CGPoint(x: videoScene.size.width / 2, y: videoScene.size.height / 2)
        videoNode.yScale = -1.0
        videoScene.addChild(videoNode)
        plane.firstMaterial?.diffuse.contents = videoScene
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2
        DispatchQueue.main.async {
            self.showScanner(isVisible: false)
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

extension ViewController: VNDocumentCameraViewControllerDelegate {

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
