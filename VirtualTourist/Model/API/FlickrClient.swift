//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Ahmed Osama on 11/17/18.
//  Copyright © 2018 Ahmed Osama. All rights reserved.
//

import Foundation

class FlickrClient {
    
    private init () { }
    
    static private let apiKey = "aed7f2c6ef69d013d249edb253e208a8"
    
    static func getPhotosFor(latitude: Float, longitude: Float,
                      completionHandler: @escaping ([FlickrPhoto]?, String?) -> Void) {
        
        let url = URL(string: "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(latitude)+&lon=\(longitude)&radius=1&extras=url_m&format=json&nojsoncallback=1&per_page=200")!
        let request = URLRequest(url: url)
        
        Helpers.performDataTask(with: request) { (response, errorMessage) in
            guard let response = response else {
                completionHandler(nil, errorMessage)
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: response) as? [String: Any]
                let jsonPhotos = json?["photos"] as? [String: Any]
                let photosArrayAsData = try JSONSerialization.data(withJSONObject: (jsonPhotos?["photo"])!)
                let decoder = JSONDecoder()
                var photosArray = try decoder.decode([FlickrPhoto].self, from: photosArrayAsData)
                photosArray.shuffle()
                let slice = photosArray.prefix(20)
                let finalArray = [FlickrPhoto](slice)
                completionHandler(finalArray, nil)
            }
            catch let error as NSError {
                completionHandler(nil, error.localizedDescription)
            }
        }
        
    }
    
}
