//
//  WATitleNaviBarItem.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/17.
//

import Foundation
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignBadge



public struct WATitleBarConfig: Codable {
    public let titleType: WebAppTitleStyle?
    public let leftItems: [WATitleBarNaviItem]?
    public let rightItems: [WATitleBarNaviItem]?
}

enum WABarNaviItemID: String {
    case back
    case more
    case refresh
}


public struct WATitleBarNaviItem: Codable {
    public let itemId: String
    public let text: String?
    public let udIconKey: String?
    public let imageBase64: String?
    public let badgeStyle: String?
    public let badgeText: String?
    
    public enum BadgeStyle: String {
        case noBadge = "none"
        case dot
        case num
        case text
    }
    
    func toBarButtonItem(target: AnyObject,selector: Selector) -> SKBarButtonItem? {
        var image: UIImage?
        var barItemId: SKNavigationBar.ButtonIdentifier?
        if itemId == WABarNaviItemID.back.rawValue {
            image =  UDIcon.leftOutlined
            barItemId = .back
        } else if itemId == WABarNaviItemID.more.rawValue {
            image =  UDIcon.moreOutlined
            barItemId = .more
        } else if let udIconKey = self.udIconKey,
                  let realKey = getRealUDKey(udIconKey),
                  let iconType = UDIcon.getIconTypeByName(realKey)  {
            image = UDIcon.getIconByKey(iconType)
        } else if let imageBase64 = self.imageBase64 {
            image = UIImage.docs.image(base64: imageBase64)
        }
        guard let image else {
            return nil
        }
        
        var buttonItem = SKBarButtonItem(image: image,
                                         style: .plain,
                                         target: target,
                                         action: selector)
        buttonItem.id = barItemId ?? .unknown(itemId)
        
        //badge
        let badgeConfig = setUDBadgeConfig(style: badgeStyle ?? BadgeStyle.noBadge.rawValue, text: badgeText)
        buttonItem.badgeStyle = badgeConfig
        
        return buttonItem
    }
    
    private func setUDBadgeConfig(style: String, text: String?) -> UDBadgeConfig? {
        guard let styleType = BadgeStyle(rawValue: style) else {
            return nil
        }
        
        switch styleType {
        case .noBadge:
            return nil
        case .dot:
            let config = UDBadgeConfig(type: .dot)
            return config
        case .num:
            let maxNumber = 999
            var number = 0
            if let text, let bageNumber = Int(text) {
                number = bageNumber
            }
            let config = UDBadgeConfig(type: .number, number: number, maxNumber: maxNumber)
            return config
        case .text:
            let config = UDBadgeConfig(type: .text, text: text ?? "")
            return config
        }
    }
}

public struct WebAppTitleStyle: Codable {
    public enum TitleSize: Int, Codable  {
        case small = 0
        case normal = 1
        case big = 2
    }
    public enum TitlePosition: Int, Codable {
        case left = 0
        case center = 1
    }
    
    public let size: TitleSize?
    public let position: TitlePosition?
    
    enum CodingKeys: String, CodingKey {
        case size
        case position
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        size = try container.decodeIfPresent(TitleSize.self, forKey: .size) ?? .normal
        position = try container.decodeIfPresent(TitlePosition.self, forKey: .position) ?? .center
    }
}
