//
//  FetchPhotoOperation.swift
//  Astronomy
//
//  Created by FGT MAC on 3/30/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import Foundation


class FetchPhotoOperation: ConcurrentOperation {
    
    var marsPhotoReference: MarsPhotoReference
    var imageData: Data?
    private var task: URLSessionTask?
    
    init(marsPhotoReference: MarsPhotoReference) {
        self.marsPhotoReference = marsPhotoReference
    }
    
    //This tells the operation queue machinery that the operation has started running.
    override func start() {
        state = .isExecuting
        
       guard let url = marsPhotoReference.imageURL.usingHTTPS else {
            NSLog("Image URL is not using HTTPS")
            return
        }
        
       task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            
            if let error = error {
                NSLog("Error loading image data: \(error)")
                return
            }
            
            //Data to be use
            self.imageData = data
            
            self.state = .isFinished
            
            })
        
        task?.resume()
    }
    
    override func cancel() {
        task?.cancel()
    }
    
    
    
    
}
