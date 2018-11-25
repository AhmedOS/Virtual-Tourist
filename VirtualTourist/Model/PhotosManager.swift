//
//  PhotosManager.swift
//  VirtualTourist
//
//  Created by Ahmed Osama on 11/20/18.
//  Copyright © 2018 Ahmed Osama. All rights reserved.
//

import Foundation

class PhotosManager {
    
    static fileprivate let photosManager = PhotosManager()
    
    static func shared() -> PhotosManager {
        return photosManager
    }
    
    func downloadAndSave(url: URL, id: String, pin owner: MapPin,
                  completionHandler: @escaping (_ url: URL?, _ errorMessage: String?) -> Void) {
        
        let task = URLSession.shared.downloadTask(with: url) { (downloadedAtURL, response, error) in
            guard error == nil else {
                completionHandler(nil, error!.localizedDescription)
                return
            }
            let fileManager = FileManager.default
            var fileURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            let fileName = "\(owner.latitude)_\(owner.longitude)_\(id)_\(Int.random(in: 1..<1000000))"
            fileURL?.appendPathComponent(fileName)
            do {
                try fileManager.moveItem(at: downloadedAtURL!, to: fileURL!)
                ModelManager.shared().saveContext()
                completionHandler(fileURL, nil)
            }
            catch {
                completionHandler(nil, "Failed to save image")
            }
        }
        task.resume()
        
    }
    
    func delete(path: String, pin owner: MapPin) -> String? {
        do {
            try FileManager.default.removeItem(at: URL(fileURLWithPath: path))
            for i in 0..<(owner.images?.count)! {
                if owner.images?[i] == path {
                    owner.images?.remove(at: i)
                    break
                }
            }
            ModelManager.shared().saveContext()
            return nil
        }
        catch {
            return "Failed to delete file"
        }
    }
    
}
