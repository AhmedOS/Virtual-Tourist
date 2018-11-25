//
//  Helpers.swift
//  VirtualTourist
//
//  Created by Ahmed Osama on 11/18/18.
//  Copyright © 2018 Ahmed Osama. All rights reserved.
//

import Foundation
import UIKit

enum Helpers {
    
    static func performDataTask(with request: URLRequest,
                                completionHandler: @escaping (Data?, String?) -> Void) {
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard data != nil else {
                completionHandler(nil, error?.localizedDescription)
                return
            }
            let status = (response as! HTTPURLResponse).statusCode
            guard status >= 200 && status <= 299 else {
                completionHandler(nil, "Invalid server response: \(status)")
                return
            }
            completionHandler(data, nil)
        }
        task.resume()
    }
    
    static func showSimpleAlert(viewController: UIViewController, title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
}
