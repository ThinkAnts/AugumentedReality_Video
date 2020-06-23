//
//  VideoRecordingViewController.swift
//  OmniPresence_AR
//
//  Created by Ravi kishore on 5/22/20.
//  Copyright © 2020 Indegene. All rights reserved.
//

import UIKit
import AVFoundation


class VideoRecordingViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {

    @IBOutlet weak var camPreview: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var recordTimer: UILabel!
       let captureSession = AVCaptureSession()
       let movieOutput = AVCaptureMovieFileOutput()
       var previewLayer: AVCaptureVideoPreviewLayer!
       var activeInput: AVCaptureDeviceInput!
       var outputURL: URL!
       var timeHr = 0
       var timeMin = 0
       var timeSec = 0
       weak var timer: Timer?

       override func viewDidLoad() {
           super.viewDidLoad()
            recordTimer.text = String(format: "%02d:%02d:%02d", timeHr, timeMin, timeSec)
           if setupSession() {
               setupPreview()
               startSession()
           }
       }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            resetTimerToZero()
        }

       func setupPreview() {
           // Configure previewLayer
           previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
           previewLayer.frame = camPreview.bounds
           previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
           camPreview.layer.addSublayer(previewLayer)
       }

       //MARK:- Setup Camera

       func setupSession() -> Bool {

           captureSession.sessionPreset = AVCaptureSession.Preset.high

           // Setup Camera
        guard let camera = AVCaptureDevice.default(for: AVMediaType.video) else { return false}

           do {

               let input = try AVCaptureDeviceInput(device: camera)

               if captureSession.canAddInput(input) {
                   captureSession.addInput(input)
                   activeInput = input
               }
           } catch {
               print("Error setting device video input: \(error)")
               return false
           }

           // Setup Microphone
           let microphone = AVCaptureDevice.default(for: AVMediaType.audio)!

           do {
               let micInput = try AVCaptureDeviceInput(device: microphone)
               if captureSession.canAddInput(micInput) {
                   captureSession.addInput(micInput)
               }
           } catch {
               print("Error setting device audio input: \(error)")
               return false
           }


           // Movie output
           if captureSession.canAddOutput(movieOutput) {
               captureSession.addOutput(movieOutput)
           }

           return true
       }

       func setupCaptureMode(_ mode: Int) {
           // Video Mode

       }
    
        @IBAction func startCapture() {
             startRecording()
            if movieOutput.isRecording == false {
                
            } else {
                
            }
         }


       //MARK:- Camera Session
       func startSession() {

           if !captureSession.isRunning {
               videoQueue().async {
                   self.captureSession.startRunning()
               }
           }
       }

       func stopSession() {
           if captureSession.isRunning {
               videoQueue().async {
                   self.captureSession.stopRunning()
               }
           }
       }

       func videoQueue() -> DispatchQueue {
           return DispatchQueue.main
       }

       func currentVideoOrientation() -> AVCaptureVideoOrientation {
           var orientation: AVCaptureVideoOrientation

           switch UIDevice.current.orientation {
               case .portrait:
                   orientation = AVCaptureVideoOrientation.portrait
               case .landscapeRight:
                   orientation = AVCaptureVideoOrientation.landscapeLeft
               case .portraitUpsideDown:
                   orientation = AVCaptureVideoOrientation.portraitUpsideDown
               default:
                    orientation = AVCaptureVideoOrientation.landscapeRight
            }

            return orientation
        }

       //EDIT 1: I FORGOT THIS AT FIRST

       func tempURL() -> URL? {
           let directory = NSTemporaryDirectory() as NSString

           if directory != "" {
               let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
               return URL(fileURLWithPath: path)
           }

           return nil
       }

       override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

           let vc = segue.destination as! VideoPlaybackViewController
           vc.videoURL = sender as? URL

       }

       func startRecording() {

           if movieOutput.isRecording == false {
                
               recordButton.setImage(UIImage(named: "music-player"), for: .normal)
               startTimer()
               let connection = movieOutput.connection(with: AVMediaType.video)

               if (connection?.isVideoOrientationSupported)! {
                   connection?.videoOrientation = currentVideoOrientation()
               }

               if (connection?.isVideoStabilizationSupported)! {
                   connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
               }

               let device = activeInput.device

               if (device.isSmoothAutoFocusSupported) {

                   do {
                       try device.lockForConfiguration()
                       device.isSmoothAutoFocusEnabled = false
                       device.unlockForConfiguration()
                   } catch {
                      print("Error setting configuration: \(error)")
                   }

               }

               //EDIT2: And I forgot this
               outputURL = tempURL()
               movieOutput.startRecording(to: outputURL, recordingDelegate: self)

               }
               else {
                   stopRecording()
               }

          }

      func stopRecording() {

          if movieOutput.isRecording == true {
              movieOutput.stopRecording()
                recordButton.setImage(UIImage(named: "Record"), for: .normal)
                resetTimerAndLabel()
           }
      }

       func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {

       }

       func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {

           if (error != nil) {

               print("Error recording movie: \(error!.localizedDescription)")

           } else {

               let videoRecorded = outputURL! as URL

               performSegue(withIdentifier: "showVideo", sender: videoRecorded)

           }

       }
}

extension VideoRecordingViewController {
    // MARK:- Timer Functions
    fileprivate func startTimer(){

        // if you want the timer to reset to 0 every time the user presses record you can uncomment out either of these 2 lines

        // timeSec = 0
        // timeMin = 0

        // If you don't use the 2 lines above then the timer will continue from whatever time it was stopped at
        let timeNow = String(format: "%02d:%02d:%02d", timeHr, timeMin, timeSec)
        recordTimer.text = timeNow

        stopTimer() // stop it at it's current time before starting it again
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    self?.timerTick()
                }
    }

    @objc fileprivate func timerTick(){
         timeSec += 1

         if timeSec == 60{
             timeSec = 0
             timeMin += 1
         }
        
        if timeHr == 60 {
            timeSec = 0
            timeMin = 0
            timeHr += 1
        }

         let timeNow = String(format: "%02d:%02d:%02d", timeHr, timeMin, timeSec)

         recordTimer.text = timeNow
    }

    // resets both vars back to 0 and when the timer starts again it will start at 0
    @objc fileprivate func resetTimerToZero(){
         timeHr = 0
         timeSec = 0
         timeMin = 0
         stopTimer()
    }

    // if you need to reset the timer to 0 and yourLabel.txt back to 00:00
    @objc fileprivate func resetTimerAndLabel(){

         resetTimerToZero()
         recordTimer.text = String(format: "%02d:%02d:%02d", timeHr, timeMin, timeSec)
    }

    // stops the timer at it's current time
    @objc fileprivate func stopTimer(){

         timer?.invalidate()
    }
}
