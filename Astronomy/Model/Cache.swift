//
//  Cache.swift
//  Astronomy
//
//  Created by FGT MAC on 3/30/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import Foundation

//Use to cache the photos to prevent unnecesary API fecth request
//Key and Value are use as placeholders for generic types
class Cache<Key: Hashable,Value> {
    
    //Initializing a diccionary
    private var items: [Key:Value] = [:]
    
    private var queue = DispatchQueue(label: "Cache access management queue")
    
    func cache(for key: Key, value: Value) {
        queue.async {
            self.items[key] = value
        }
    }
    
    func value(for key: Key) -> Value? {
       return queue.sync {
            items[key]
        }
    }
}
