//
//  BitableCacheProvider.swift
//  Demo
//
//  Created by yinyuan on 2023/2/24.
//

import UIKit
import UniverseDesignIcon
import UniverseDesignColor
import SKFoundation

/// Bitable 缓存 Provider，对耗时资源提供临时高速缓存，每次 bitable 退出时会清理一次缓存
final class BitableCacheProvider {
    
    private var iconCache: [String: UIImage] = [:]
    private var ratingIconCache: [String: BTRatingView.Icon] = [:]
    
    private(set) static var current: BitableCacheProvider = BitableCacheProvider()
    
    /// 实际测试，UDIcon 的读取耗时不可忽略，在高频调用相同 icon 的场景，可以使用该缓存接口
    func icon(_ key: UDIconType) -> UIImage {
        spaceAssertMainThread()
        if let resource = iconCache[key.rawValue] {
            return resource
        }
        let resource = UDIcon.getIconByKey(key)
        iconCache[key.rawValue] = resource
        return resource
    }
    
    /// 增加根据symbol获取Simple Icon方法
    func simpleIcon(with symbol: String) -> UIImage {
        switch symbol {
        case "star":
            return icon(.ratingStarColorful)
        case "heart":
            return icon(.ratingLikeColorful)
        case "thumbsup":
            return icon(.ratingThumbsupColorful)
        case "fire":
            return icon(.ratingHotColorful)
        case "smile":
            return icon(.ratingSmileColorful)
        case "lightning":
            return icon(.ratingSpeedColorful)
        case "flower":
            return icon(.ratingFlowerColorful)
        case "number":
            return icon(.ratingNpsColorful)
        default:
            return icon(.ratingStarColorful)
        }
    }
    
    /// 评分字段的子view较多，增加配置缓存，降低卡顿
    func ratingIcon(symbol: String, value: Int?) -> BTRatingView.Icon {
        spaceAssertMainThread()
        let key: String
        if let value = value {
            key = "\(symbol):\(value)"
        } else {
            key = symbol
        }
        if let resource = ratingIconCache[key] {
            return resource
        }
        let resource: BTRatingView.Icon
        switch symbol {
        case "star":
            resource = BTRatingView.Icon(icon(.ratingStarColorful))
        case "heart":
            resource = BTRatingView.Icon(icon(.ratingLikeColorful))
        case "thumbsup":
            resource = BTRatingView.Icon(icon(.ratingThumbsupColorful))
        case "fire":
            resource = BTRatingView.Icon(icon(.ratingHotColorful))
        case "smile":
            resource = BTRatingView.Icon(icon(.ratingSmileColorful))
        case "lightning":
            resource = BTRatingView.Icon(icon(.ratingSpeedColorful))
        case "flower":
            resource = BTRatingView.Icon(icon(.ratingFlowerColorful))
        case "number":
            if let value = value {
                let background = BTRatingView.IconLayer(selectImage: icon(.ratingBgColorful), unselectImage: icon(.ratingBgColorful).withRenderingMode(.alwaysTemplate), unselectTint: UDColor.N300)
                let forgroundImage: UIImage?
                switch value {
                case 0:
                    forgroundImage = icon(.rating0Colorful)
                case 1:
                    forgroundImage = icon(.rating1Colorful)
                case 2:
                    forgroundImage = icon(.rating2Colorful)
                case 3:
                    forgroundImage = icon(.rating3Colorful)
                case 4:
                    forgroundImage = icon(.rating4Colorful)
                case 5:
                    forgroundImage = icon(.rating5Colorful)
                case 6:
                    forgroundImage = icon(.rating6Colorful)
                case 7:
                    forgroundImage = icon(.rating7Colorful)
                case 8:
                    forgroundImage = icon(.rating8Colorful)
                case 9:
                    forgroundImage = icon(.rating9Colorful)
                case 10:
                    forgroundImage = icon(.rating10Colorful)
                default:
                    forgroundImage = nil
                }
                if let forgroundImage = forgroundImage {
                    resource = BTRatingView.Icon(background: background, foreground: .init(selectImage: forgroundImage, unselectImage: forgroundImage))
                } else {
                    resource = BTRatingView.Icon(icon(.ratingNpsColorful))
                }
            } else {
                resource = BTRatingView.Icon(icon(.ratingNpsColorful))
            }
        default:
            resource = BTRatingView.Icon(icon(.ratingStarColorful))
        }
        
        ratingIconCache[key] = resource
        return resource
    }
    
    static func clear() {
        current = BitableCacheProvider()
    }
}

