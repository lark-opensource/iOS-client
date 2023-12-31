//
//  IconImageCache.swift
//  IconfontGen
//
//  Created by yangyao on 2019/10/8.
//

import Foundation
import UIKit

extension UIColor {
    var hexComponents: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)
        return "\(r)\(g)\(b)\(a)"
    }
}

extension IconImageCache {
    subscript(key: NSString) -> UIImage? {
        get {
            return image(forKey: key)
        }
        set {
            guard let value = newValue else {
                removeImage(forKey: key)
                return
            }
            set(value, forKey: key)
        }
    }
}

public final class IconImageCache<Key: Hashable, Value> {
    let cache = NSCache<NSString, UIImage>()
    init() {
        cache.countLimit = 100
    }

    public func cleanCache() {
        cache.removeAllObjects()
    }

    func image(forKey key: NSString) -> UIImage? {
        return cache.object(forKey: key)
    }

    func set(_ image: UIImage, forKey key: NSString) {
        cache.setObject(image, forKey: key)
    }

    func removeImage(forKey key: NSString) {
        cache.removeObject(forKey: key)
    }
}
