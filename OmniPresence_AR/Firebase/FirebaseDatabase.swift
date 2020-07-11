//
//  FirebaseDatabase.swift
//  OmniPresence_AR
//
//  Created by Ravi kishore on 6/24/20.
//  Copyright © 2020 Indegene. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage

class ARImageDataBase {
    static let shared = ARImageDataBase()

    func addOrUpdateDatabase(imageObs: [String], identifiers: String, confidence: Float, videoUrl: String, name: String,
                             description: String, arImageName: String,
                             success : @escaping (String) -> Void,
                             failure : @escaping (Error) -> Void) {
        let arImageDB = Database.database().reference().child("ARImageObservations")
        let imageDictionary : NSDictionary = ["Name": name, "Description": description, "ARImageName": arImageName, "ImageClassification" : imageObs, "Identifiers": identifiers, "confidence": confidence, "VideoUrl": videoUrl]
        arImageDB.childByAutoId().setValue(imageDictionary) {
             (error, ref) in
             if error != nil {
                failure(error!)
                 print(error!)
             }
             else {
                  success("Data saved successfully")
                 print("Data saved successfully!")
             }
        }
    }
    
    func retrieveFromDatabase(confidence: Float, identifiers: String,
                              success : @escaping (String) -> Void,
                              failure : @escaping (Error) -> Void) {
        let ref = Database.database().reference().child("ARImageObservations")
        _=ref.queryOrdered(byChild: "Identifiers").queryStarting(atValue: identifiers).queryEnding(atValue: identifiers+"\u{f8ff}").observeSingleEvent(of: .value, with: { (snapshot) in
           
            var confValue: Float = 0.0
            var downLoadUrl: String = ""
            for snap in snapshot.children {
                let postDic = (snap as? DataSnapshot)?.value as? NSDictionary
                let conf = postDic?["confidence"] as? Float
                let downloadUrl = postDic?["VideoUrl"] as? String ?? ""
                if confValue == 0.0 {
                    confValue = conf ?? 0.0
                    downLoadUrl = downloadUrl
                } else if Int(conf ?? 0.0) > Int(confValue) {
                    downLoadUrl = postDic?["VideoUrl"] as? String ?? ""
                    success(downLoadUrl)
                } else {
                    success(downLoadUrl)
                }
            };

            if snapshot.childrenCount == 1 {
                success(downLoadUrl)
            } else if snapshot.childrenCount == 0 {
                let error = NSError(domain: "", code: 100, userInfo: [ NSLocalizedDescriptionKey: "No Data Found"])
                failure(error)
            }
        })
    }
    
    func uploadVideoToStorage(name: String, data: NSData,
                              success : @escaping (String) -> Void,
                               failure : @escaping (Error) -> Void) {
        let storageRef = Storage.storage().reference().child("Videos").child(name)
        if let uploadData = data as Data? {
            storageRef.putData(uploadData, metadata: nil
                , completion: { (metadata, error) in
                    if let error = error {
                        failure(error)
                    }else{
                        storageRef.downloadURL { (downloadUrl, error) in
                            if let error = error {
                                failure(error)
                            } else {
                                 success(downloadUrl!.absoluteString)
                            }
                        }
                    }
            })
        }

    }
    
    func fetchAllDataFromFireBase(success : @escaping ([NSDictionary]) -> Void,
                                   failure : @escaping (Error) -> Void)  {
        var resultsArray = [NSDictionary]()
        let ref = Database.database().reference().child("ARImageObservations")
        ref.observeSingleEvent(of: .value) { (snapshot) in
            for snap in snapshot.children {
                let postDic = (snap as? DataSnapshot)?.value as? NSDictionary
                resultsArray.append(postDic ?? NSDictionary())
            }
        if resultsArray.count > 0 {
                success(resultsArray)
            } else {
                let error = NSError(domain: "", code: 100, userInfo: [ NSLocalizedDescriptionKey: "No Data Found"])
                failure(error)
            }
        }
        
    }
}
