//
//  PhotosCollectionVC.swift
//  VirtualTourist
//
//  Created by Ahmed Osama on 11/17/18.
//  Copyright © 2018 Ahmed Osama. All rights reserved.
//

import UIKit
import MapKit

class PhotosCollectionVC: UIViewController {
    
    private let reuseIdentifier = "Cell"
    private let photoVCSegueID = "showPhoto"
    
    var pin: MapPin!
    var selectedImage: UIImage?
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var deletePinButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setupDoubleTap()
        setupLayout()
        setupMap()
        collectionView.delegate = self
        collectionView.dataSource = self
        if pin.images?.count == 0 {
            getNewPhotos()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let item = collectionView.indexPathsForSelectedItems?.first {
            collectionView.deselectItem(at: item, animated: false)
        }
        selectedImage = nil
    }
    
    @IBAction func deletePinButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Delete Pin", message: "Are you sure you want to delete this pin?", preferredStyle: .alert)
        let yes = UIAlertAction(title: "Yes, Delete", style: .destructive) { (action) in
            ModelManager.shared().deletePin(pin: self.pin)
            self.navigationController?.popViewController(animated: true)
        }
        let no = UIAlertAction(title: "No", style: .cancel, handler: nil)
        alert.addAction(yes)
        alert.addAction(no)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func newCollectionButtonTapped(_ sender: Any) {
        getNewPhotos()
    }
    
    func setupLayout() {
        let spaceH:CGFloat = 2.0
        let spaceV:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * spaceH)) / 3.0
        flowLayout.minimumInteritemSpacing = spaceH
        flowLayout.minimumLineSpacing = spaceV
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    func setupMap() {
        mapView.isUserInteractionEnabled = false
        let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin!.latitude),
                                                longitude: CLLocationDegrees(pin!.longitude))
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
        mapView.setRegion(region, animated: false)
    }
    
    func setupDoubleTap() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delaysTouchesBegan = true
        //doubleTapGesture.cancelsTouchesInView = false
        collectionView.addGestureRecognizer(doubleTapGesture)
    }
    
    @objc func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        if sender.state != .recognized {
            return
        }
        let point = sender.location(in: collectionView)
        if let indexPath = collectionView.indexPathForItem(at: point) {
            let cell = collectionView.cellForItem(at: indexPath) as! FancyCollectionCell
            if let path = cell.imagePath {
                let error = PhotosManager.shared().delete(path: path, pin: pin)
                if let errorMessage = error {
                    Helpers.showSimpleAlert(viewController: self, title: "Failed to delete image", message: errorMessage)
                }
                else {
                    collectionView.deleteItems(at: [indexPath])
                }
            }
        }
    }
    
    func getNewPhotos() {
        prepareUIForGettingPhotosList()
        let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin!.latitude),
                                                longitude: CLLocationDegrees(pin!.longitude))
        FlickrClient.getPhotosFor(latitude: Float(coordinate.latitude),
                                  longitude: Float(coordinate.longitude))
        { (photos, errorMessage) in
            guard let photos = photos else {
                Helpers.showSimpleAlert(viewController: self, title: "Error", message: errorMessage!)
                return
            }
            self.pin.images = [String](repeating: "", count: photos.count)
            self.prepareUIForGettingPhotos()
            var downloaded = 0
            var i = 0
            for item in photos {
                PhotosManager.shared().downloadAndSave(url: URL(string: item.url_m!)!, id: item.id!, pin: self.pin, completionHandler: { [i] (fileURL, errorMessage) in
                    downloaded += 1
                    let row = i
                    let index = IndexPath(row: row, section: 0)
                    self.pin.images?[row] = fileURL != nil ? (fileURL?.path)! : "-BROKEN-"
                    DispatchQueue.main.async {
                        self.collectionView.reloadItems(at: [index])
                        if downloaded == self.pin.images?.count {
                            self.finishedDownloadingAll()
                        }
                    }
                })
                i += 1
            }
        }
    }
    
    func prepareUIForGettingPhotosList() {
        DispatchQueue.main.async {
            self.newCollectionButton.isEnabled = false
            self.deletePinButton.isEnabled = false
            self.statusLabel.text = "Getting photos list.."
            self.statusLabel.isHidden = false
            self.pin.images?.removeAll()
            ModelManager.shared().saveContext()
            self.collectionView.reloadData()
        }
    }
    
    func prepareUIForGettingPhotos() {
        DispatchQueue.main.async {
            self.statusLabel.isHidden = true
            self.collectionView.reloadData()
        }
    }
    
    func finishedDownloadingAll() {
        DispatchQueue.main.async {
            ModelManager.shared().saveContext()
            self.newCollectionButton.isEnabled = true
            self.deletePinButton.isEnabled = true
        }
    }
    
}

extension PhotosCollectionVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = pin.images?.count, count > 0 {
            statusLabel.isHidden = true
            return count
        }
        statusLabel.text = "No Photos"
        statusLabel.isHidden = false
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FancyCollectionCell
        let path = pin.images?[indexPath.row]
        cell.imagePath = path
        if FileManager.default.fileExists(atPath: path!) {
            cell.activityIndicator.stopAnimating()
            cell.imageView.image = UIImage(contentsOfFile: path!)
        }
        else if path == "" {
            cell.imageView.image = nil
            cell.activityIndicator.startAnimating()
        }
        else {
            cell.activityIndicator.stopAnimating()
            cell.imageView.image = UIImage(named: "broken")
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! FancyCollectionCell
        if cell.imagePath != nil {
            selectedImage = cell.imageView.image
            performSegue(withIdentifier: photoVCSegueID, sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == photoVCSegueID {
            let vc = segue.destination as! PhotoVC
            vc.passedImage = selectedImage
        }
    }
    
}
