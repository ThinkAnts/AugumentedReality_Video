//
//  AzureServiceViewController.swift
//  OmniPresence_AR
//
//  Created by Ravi kishore on 6/14/20.
//  Copyright © 2020 Indegene. All rights reserved.
//

import UIKit

class AzureServiceViewController {

    // If using a SAS token, fill it in here.  If using Shared Key access, comment out the following line.
    var containerURL = "https://arresources.blob.core.windows.net/arvideocontainer?sv=2019-10-10&ss=bfqt&srt=sco&sp=rwdlacupx&se=2020-06-19T17:36:36Z&st=2020-06-14T09:36:36Z&spr=https&sig=3YECYmscCInBlnZdpJoHsoy4cnKluq%2FKnGtCwb4ZG0o%3D"
    var usingSAS = true
    
    // If using Shared Key access, fill in your credentials here and un-comment the "UsingSAS" line:
    var connectionString = "DefaultEndpointsProtocol=https;AccountName=arresources;AccountKey=zr+kJ5squREEy9PpiqZVHUTZurXaoZfRcNo49sLMjtdqZDTtMNQVSmg/ThuL+uLYTVrleMSZ8s4+5st1nXZ1vg==;EndpointSuffix=core.windows.net"
    var containerName = "arvideocontainer"
    var blobs = [AZSCloudBlob]()
    var container : AZSCloudBlobContainer?
    var continuationToken : AZSContinuationToken?
    static let shared = AzureServiceViewController()


    init(){
        initalizeAzureContainer()
    }

    func initalizeAzureContainer() {
        if (usingSAS) {
            var error: NSError?
            self.container = AZSCloudBlobContainer(url: URL(string: containerURL)!, error: &error)
            if ((error) != nil) {
                print("Error in creating blob container object.  Error code = %ld, error domain = %@, error userinfo = %@", error!.code, error!.domain, error!.userInfo);
            }
        }
        else {
            //            do {
            let storageAccount : AZSCloudStorageAccount;
            try! storageAccount = AZSCloudStorageAccount(fromConnectionString: connectionString)
            let blobClient = storageAccount.getBlobClient()
            self.container = blobClient.containerReference(fromName: containerName)
            
            let condition = NSCondition()
            var containerCreated = false
            
            self.container?.createContainerIfNotExists { (error : Error?, created) -> Void in
                condition.lock()
                containerCreated = true
                condition.signal()
                condition.unlock()
            }
            
            condition.lock()
            while (!containerCreated) {
                condition.wait()
            }
            condition.unlock()
        }
        
        self.continuationToken = nil
    }

    func uploadToAzure(name: String, videoUrl: URL, imageUrl: URL, completion: @escaping (Bool)->()) {
        let blobDirectory = container?.directoryReference(fromName: "ARVideos")
        let videoBlob = blobDirectory?.blockBlobReference(fromName: name + ".mp4")
        
        videoBlob?.uploadFromFile(with: videoUrl as URL){(error: Error?) -> Void in
                if (error.debugDescription.count > 0) {
                    print(error.debugDescription)
                    completion(false)
                } else {
                    completion(true)
            }
        }
        
        let imageBlob = blobDirectory?.blockBlobReference(fromName: name + ".jpg")
        
        imageBlob?.uploadFromFile(with: imageUrl) { (error: Error?) -> Void in
            if (error.debugDescription.count > 0) {
                print(error.debugDescription)
                completion(false)
            } else {
                completion(true)
            }
        }
        
    }
    
    func downLoadVideoFromAzure(name: String, completion: @escaping (URL)->()) {
        let blobDirectory = container?.directoryReference(fromName: "ARVideos")
        let videoBlob = blobDirectory?.blockBlobReference(fromName: name + ".mp4")
        
        let filename = getDocumentsDirectory().appendingPathComponent("arVideo.mp4")
        videoBlob?.downloadToFile(with: filename, append: true, completionHandler: { (error) in
            if error.debugDescription.count != 0 {
                completion(filename)
            }
        })
    }
    
    func downloadImageFromAzure(name: String, completion: @escaping (Data)->()) {
        let blobDirectory = container?.directoryReference(fromName: "ARVideos")
        let imageBlob = blobDirectory?.blockBlobReference(fromName: name + ".jpg")
        imageBlob?.downloadToData { (error, data) in
            if data?.count != 0 {
                completion(data!)
            }
        }
    }
            
       private func getDocumentsDirectory() -> URL {
           let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
           return paths[0]
       }
}
