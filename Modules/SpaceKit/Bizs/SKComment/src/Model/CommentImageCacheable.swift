//
//  CommentImageCacheable.swift
//  SKCommon
//
//  Created by huayufan on 2022/8/27.
//  


import UIKit
import SKFoundation

protocol CommentImageCacheable {
    var cacheKey: String { get }
}

class CommentImageMemoryCache {

    private var cache = ThreadSafeDictionary<String, UIImage>()
    
    func cache(_ cacheable: CommentImageCacheable, _ image: UIImage) {
        cache.updateValue(image, forKey: cacheable.cacheKey)
    }
    
    func fetch(_ cacheable: CommentImageCacheable) -> UIImage? {
        return cache.value(ofKey: cacheable.cacheKey)
    }
    
    func fetch(key: String) -> UIImage? {
        return cache.value(ofKey: key)
    }
}
