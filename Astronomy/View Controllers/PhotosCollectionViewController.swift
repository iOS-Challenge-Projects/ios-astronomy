//
//  PhotosCollectionViewController.swift
//  Astronomy
//
//  Created by Andrew R Madsen on 9/5/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit

class PhotosCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        client.fetchMarsRover(named: "curiosity") { (rover, error) in
            if let error = error {
                NSLog("Error fetching info for curiosity: \(error)")
                return
            }
            
            self.roverInfo = rover
        }
    }
    
    // UICollectionViewDataSource/Delegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoReferences.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCollectionViewCell ?? ImageCollectionViewCell()
        
        loadImage(forCell: cell, forItemAt: indexPath)
        
        return cell
    }
    
    // Make collection view cells fill as much available width as possible
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        var totalUsableWidth = collectionView.frame.width
        let inset = self.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: indexPath.section)
        totalUsableWidth -= inset.left + inset.right
        
        let minWidth: CGFloat = 150.0
        let numberOfItemsInOneRow = Int(totalUsableWidth / minWidth)
        totalUsableWidth -= CGFloat(numberOfItemsInOneRow - 1) * flowLayout.minimumInteritemSpacing
        let width = totalUsableWidth / CGFloat(numberOfItemsInOneRow)
        return CGSize(width: width, height: width)
    }
    
    // Add margins to the left and right side
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10.0, bottom: 0, right: 10.0)
    }
    
    // MARK: - Private
    
    private func loadImage(forCell cell: ImageCollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let photoReference = photoReferences[indexPath.item]
        
        //store fetch operations by the associated photo reference id
        var fetchOperations: [Int:FetchPhotoOperation] = [:]
    
        
        
        
        //If the image exist in the cache then set it to the imageView
        if let image = cache.value(for: photoReference.id) {
            print("Image from Cache")
            cell.imageView.image = image
 
        }else{
       
            print("Image from Fetch")
            
            //Main Operation
            let fetchData = FetchPhotoOperation(marsPhotoReference: photoReference)
            //Add the fetch operation to your dictionary
            fetchOperations[photoReference.id] = fetchData
           
            //1st Operation
            let cacheOperation = BlockOperation {
                print("Save to cache")
                //convert data to UIImage
                guard let imageData = fetchData.imageData, let image = UIImage(data: imageData) else {
                    NSLog("Cound not convert data to UIImage")
                    return
                }
                //save in cache for later use
                self.cache.cache(for: photoReference.id, value: image)
            }
            
            //2nd Operation
            let completion = BlockOperation {
                print("Set image to cell")
                guard let imageData = fetchData.imageData,let image = UIImage(data: imageData) else {
                              NSLog("Cound not convert data to UIImage")
                              return
                          }
                //if cell still in view
                if self.collectionView.visibleCells.contains(cell) {
                    
                    cell.imageView.image = image
                }
            }
            
           //Both depend on completion of the fetch operation.
           cacheOperation.addDependency(fetchData)
           completion.addDependency(fetchData)

            //add operations to the queue
            photoFetchQueue.addOperations([cacheOperation, fetchData], waitUntilFinished: false)
            
            
            //UIKit API and must run on the main queue
            OperationQueue.main.addOperation(completion)
        }
    }
    
    // Properties
    private let cache = Cache<Int, UIImage>()
    
    private let client = MarsRoverClient()
    
    private var photoFetchQueue = OperationQueue()
    
    private var roverInfo: MarsRover? {
        didSet {
            solDescription = roverInfo?.solDescriptions[3]
        }
    }
    private var solDescription: SolDescription? {
        didSet {
            if let rover = roverInfo,
                let sol = solDescription?.sol {
                client.fetchPhotos(from: rover, onSol: sol) { (photoRefs, error) in
                    if let e = error { NSLog("Error fetching photos for \(rover.name) on sol \(sol): \(e)"); return }
                    self.photoReferences = photoRefs ?? []
                }
            }
        }
    }
    private var photoReferences = [MarsPhotoReference]() {
        didSet {
            DispatchQueue.main.async { self.collectionView?.reloadData() }
        }
    }
    
    @IBOutlet var collectionView: UICollectionView!
}

