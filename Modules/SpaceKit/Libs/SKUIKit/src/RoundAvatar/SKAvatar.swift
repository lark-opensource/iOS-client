//
//  SKAvatar.swift
//  SKUIKit
//
//  Created by chensi on 2021/8/16.
//  


import Foundation
import ByteWebImage
import UniverseDesignAvatar

public typealias SKAvatar = UDAvatar

//extension SKAvatar {
//
//    open func set(avatarKey: String = "",
//                  fsUnit: String? = nil,
//                  placeholder: UIImage? = nil,
//                  image: UIImage? = nil,
//                  completion: ByteWebImage.ImageRequestCompletion? = nil) {
//
//        guard !avatarKey.isEmpty else {
//            self.image = image
//            return
//        }
//
//        var fixedKey = avatarKey.replacingOccurrences(of: "lark.avatar/", with: "")
//        fixedKey = fixedKey.replacingOccurrences(of: "mosaic-legacy/", with: "")
//        bt.setLarkImage(with: .avatar(key: fixedKey, entityID: ""),
//                        placeholder: placeholder,
//                        completion: completion)
//    }
//}
