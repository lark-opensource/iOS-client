//
//  BTCatalogueContextualAction.swift
//  SKSheet
//
//  Created by huayufan on 2021/3/24.
//  


import UIKit
import SKResource
import HandyJSON
import SKUIKit
import UniverseDesignIcon
import UniverseDesignColor

final class BTCatalogueContextualAction: UIContextualAction {
    
    struct Config {
        var color: UIColor
        var image: UIImage
        var style: UIContextualAction.Style
    }
    
    enum ActionType: String, HandyJSONEnum {
        case more
        case add = "add_view"
        
        var config: Config {
            switch self {
            case .more:
                let image = UDIcon.moreOutlined.ud.withTintColor(UDColor.primaryOnPrimaryFill)
                return Config(color: UDColor.N500, // 设计要求这里不用 token
                              image: image,
                              style: .normal)
            case .add:
                let image = UDIcon.addOutlined
                return Config(color: UDColor.colorfulBlue,
                              image: image,
                              style: .normal)
            }
        }
    }

    var type: ActionType = .add

//    static func action(_ type: ActionType, handler: @escaping UIContextualAction.Handler) -> UIContextualAction {
//        let config = type.config
//        let action = UIContextualAction(style: config.style, title: nil, handler: handler)
//        action.image = config.image
//        action.backgroundColor = config.color
//        return action
//    }

    static func slideItem(_ type: ActionType, handler: @escaping SKSlidableTableViewCellItem.Handler) -> SKSlidableTableViewCellItem {
        let config = type.config
        let item = SKSlidableTableViewCellItem(icon: config.image, backgroundColor: config.color, handler: handler)
        return item
    }
}
