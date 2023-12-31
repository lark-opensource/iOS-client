//
//  TMAEmtionResource.swift
//  OPPluginBiz
//
//  Created by xiongmin on 2022/5/24.
//

import Foundation
import LarkEmotion
import UIKit

@objc
public final class TMAEmotionResource: NSObject {
    // 获取所有资源
    @objc public class func allResource() -> [String] {
        return EmotionResouce.reactions
    }
    // 根据imageKey获取描述
    @objc public class func i18N(by key: String?) -> String? {
        guard let key = key else { return nil }
        return EmotionResouce.shared.i18nBy(key: key)
    }
    // 根据imageKey获取image
    @objc public class func image(by key:String?) -> UIImage? {
        guard let key = key else { return nil }
        let extralResourceMap = [
            "来看我": "16",
            "互粉": "51",
            "去污粉": "56",
            "666": "57"
        ]
        if let image = EmotionResouce.shared.imageBy(key: key) {
            return image
        } else if let extralKey = extralResourceMap[key] {
            return UIImage.ema_imageNamed(extralKey)
        }
        return nil
    }
    
}
