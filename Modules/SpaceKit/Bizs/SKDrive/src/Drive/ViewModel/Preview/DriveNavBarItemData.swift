//
//  DriveNavBarItem.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/7/13.
//

import Foundation
import SKCommon
import SKResource
import SpaceInterface
import SKUIKit
import UniverseDesignIcon

enum DriveMoreActionType {
    case moreVC // 点击后展示MoreViewController
    case alertVC([DriveAlertVCAction]) // 展示AlertViewController，带外部配置的数据源
}
enum DriveNavBarItemType {
    case share
    case more(DriveMoreActionType)
    case notify
    case switchPresentationMode
    case bookmark

    var image: UIImage? {
        switch self {
        case .share:
            return UDIcon.shareOutlined
        case .more:
            return UDIcon.moreOutlined
        case .notify:
            return UDIcon.bellOutlined
        case .switchPresentationMode:
            return UDIcon.presentationOutlined
        case .bookmark:
            return UDIcon.tableGroupOutlined
        }
    }
    
    /// 用于 SKNavigationBar 标识 item
    var imageID: String {
        switch self {
        case .share:
            return "icon_global_innershare_nor"
        case .more:
            return "icon_global_more_nor"
        case .notify:
            return "icon_global_notice_nor"
        case .switchPresentationMode:
            return "icon_global_presentation_nor"
        case .bookmark:
            return ""
        }
    }

    var skNaviBarButtonID: SKNavigationBar.ButtonIdentifier {
        switch self {
        case .share:
            return .share
        case .more:
            return .more
        case .notify:
            return .feed
        case .switchPresentationMode:
            return .switchPresentationMode
        case .bookmark:
            return .bookmark
        }
    }
}

struct DriveNavBarItemData {
    let type: DriveNavBarItemType
    let enable: Bool
    weak var target: NSObject?
    var action: Selector?
    var isHighLighted: Bool = false
    func update(_ enable: Bool, _ isHighLighted: Bool = false) -> DriveNavBarItemData {
        let item = DriveNavBarItemData(type: type,
                                       enable: enable,
                                       target: target,
                                       action: action,
                                       isHighLighted: isHighLighted)
        return item
    }
    
    init(type: DriveNavBarItemType, enable: Bool, target: NSObject?, action: Selector?, isHighLighted: Bool = false) {
        self.type = type
        self.enable = enable
        self.target = target
        self.action = action
        self.isHighLighted = isHighLighted
    }
}
