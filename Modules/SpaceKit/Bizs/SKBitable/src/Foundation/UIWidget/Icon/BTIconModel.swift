//
//  BTIcon.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/11.
//

import UIKit
import SKFoundation
import HandyJSON
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignEmpty
import SKInfra
import SKBrowser
import ByteWebImage

enum BTIconAndTextStyle: Int, HandyJSONEnum, Codable, SKFastDecodableEnum {
    case `default` = 0
    case normal = 1
    case desc = 2
    case select = 3
    case waring = 4
    case disable = 5
    
    func getColor() -> (iconColor: UIColor?, textColor: UIColor) {
        switch self {
        case .default:
            return (nil, UDColor.textTitle)
        case .normal:
            return (UDColor.iconN1, UDColor.textTitle)
        case .desc:
            return (UDColor.iconN2, UDColor.textCaption)
        case .select:
            return (UDColor.primaryContentDefault, UDColor.primaryContentDefault)
        case .waring:
            return (UDColor.functionDangerContentDefault, UDColor.functionDangerContentDefault)
        case .disable:
            return (UDColor.iconDisabled, UDColor.textDisabled)
        }
    }
}

enum BTIconEmptyStyle: Int, HandyJSONEnum, Codable, SKFastDecodableEnum {
    case noContent = 0
    
    func getEmptyType() -> UniverseDesignEmpty.UDEmptyType? {
        switch self {
        case .noContent:
            return .noContent
        }
    }
}

enum BTGifIconStyle: Int, HandyJSONEnum, Codable, SKFastDecodableEnum {
    case loading = 1
}

struct BTIcon: HandyJSON, SKFastDecodable, Codable, Equatable {
    var udKey: String? // 前端传入udKey，客户端转换后使用
    var udRes: Int? // 客户端ud资源
    var url: String? // 网络资源
    var id: String? // 兼容之前id
    var gif: BTGifIconStyle? // 图标动画样式
    var isSync: Bool?
    var style: BTIconAndTextStyle?
    var clickAction: String? // 前端传入Id， 点击回传前端
    var iconRadius: CGFloat? // 圆角
    var iconTintColor: String? // 染色
    var enumIcon: BTIconEmptyStyle? // 空资源
    
    static func deserialized(with dictionary: [String : Any]) -> BTIcon {
        var model = BTIcon()
        model.udKey <~ (dictionary, "udKey")
        model.udRes <~ (dictionary, "udRes")
        model.url <~ (dictionary, "url")
        model.id <~ (dictionary, "id")
        model.gif <~ (dictionary, "gif")
        model.isSync <~ (dictionary, "isSync")
        model.style <~ (dictionary, "style")
        model.enumIcon <~ (dictionary, "enumIcon")
        model.clickAction <~ (dictionary, "clickAction")
        model.iconTintColor <~ (dictionary, "iconTintColor")
        return model
    }
    
    var image: UIImage? {
        let realKey = bitableRealUDKey(udKey) ?? udKey ?? ""
        var img = UDIcon.getIconByString(realKey)
        if let style = style, let tintColor = style.getColor().iconColor {
            img = img?.ud.withTintColor(tintColor)
        }
        return img
    }
}

extension BTIcon {
    func apply(to imageView: UIImageView, tintColor: UIColor? = nil, callback: (() -> Void)? = nil) {
        if let image = BTUtil.getImage(icon: self) {
            if let tintColor = tintColor {
                imageView.image = image.ud.withTintColor(tintColor)
            } else {
                imageView.image = image
            }
            callback?()
        } else if let urlStr = self.url, let url = URL(string: urlStr)  {
            imageView.bt.setImage(url, completionHandler:  { _ in
                callback?()
            })
        }
    }
}
