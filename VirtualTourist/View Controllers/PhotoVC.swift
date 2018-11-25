//
//  PhotoVC.swift
//  VirtualTourist
//
//  Created by Ahmed Osama on 11/21/18.
//  Copyright © 2018 Ahmed Osama. All rights reserved.
//

import UIKit

class PhotoVC: UIViewController {
    
    var passedImage: UIImage!
    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = passedImage
    }
    
}
