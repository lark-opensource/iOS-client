//
//  BTTextHeightStorage.swift
//  SKBitable
//
//  Created by X-MAN on 2022/12/15.
//

import Foundation
import LarkSetting
import SKFoundation

final class BTTextHeightStorage {
    
    static let shared = BTTextHeightStorage()
    
    var cache: NSCache<NSString, NSNumber>
    
    init() {
        let store = NSCache<NSString, NSNumber>()
        let countLimit: Int
        do {
            let settings = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "bitable_config"))
            if let config = settings["card_cache_config"] as? [String: Int],
                let limit = config["layoutLimit"] {
                countLimit = limit
            } else {
                countLimit = 1000
            }
        } catch {
            DocsLogger.btError("[BTFieldLayoutCacheManager] cetch setting faild: \(error)")
            countLimit = 1000
        }
        store.countLimit = countLimit
        self.cache = store
    }
    
    private func cacheKey(_ attributteString: NSAttributedString,
                          font: UIFont,
                          inWidth width: CGFloat,
                          numberOfLine: Int = 0) -> NSString {
        return "\(numberOfLine)_\(width)_\(font.familyName)_\(font.pointSize)_`~*`\(attributteString.string)" as NSString
    }
            
    func set(_ attributteString: NSAttributedString,
             font: UIFont,
             inWidth width: CGFloat,
             height: CGFloat,
             numberOfLine: Int = 0) {
        let key = cacheKey(attributteString, font: font, inWidth: width)
        cache.setObject(NSNumber(value: height), forKey: key)
    }
    
    func get(_ attributteString: NSAttributedString,
             font: UIFont,
             inWidth width: CGFloat,
             numberOfLine: Int = 0) -> CGFloat? {
        let key = cacheKey(attributteString, font: font, inWidth: width)
        return cache.object(forKey: key) as? CGFloat
    }
        
}
