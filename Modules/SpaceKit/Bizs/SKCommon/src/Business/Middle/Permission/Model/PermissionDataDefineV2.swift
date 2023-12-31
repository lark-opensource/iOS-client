//  Created by Da Lei on 2018/3/28.

import Foundation

public enum PublicPermissionCellModelType {
    case crossTenant   //分享到组织外
    case externalCollaborator //谁可对外分享
    case partnerTenant  // 分享到关联组织
    case partnerTenantCollaborator // 谁可对关联组织分享
    case manageCollaborator //分享设置/谁可以管理协作者-权限维度
    case security  //安全设置
    case comment  //评论设置
    case showCollaboratorInfo  //显示协作者头像和点赞头像
    case copy  //复制设置

    var isSwitchType: Bool {
        switch self {
        case .crossTenant, .externalCollaborator,
                .partnerTenant, .partnerTenantCollaborator:
            return true
        default:
            return false
        }
    }
}

struct PublicPermissionCellModel {

    struct AccessoryItem {
        let image: UIImage
        let handler: () -> Void
    }

    let title: String
    let type: PublicPermissionCellModelType
    let accessSwitch: Bool
    var gray: Bool
    var tip: String
    // 展示在标题后的 额外 tips
    let accessoryItem: AccessoryItem?

    var canShowSinglePageTag: Bool {
        switch type {
        case .crossTenant, .partnerTenant:
            // 开关打开且是对外的两种开关之一，才可展示单容器 tag
            return accessSwitch
        default:
            return false
        }
    }

    init(title: String, type: PublicPermissionCellModelType, accessSwitch: Bool = false, gray: Bool, tip: String, accessoryItem: AccessoryItem? = nil) {
        self.title = title
        self.type = type
        self.accessSwitch = accessSwitch
        self.gray = gray
        self.tip = tip
        self.accessoryItem = accessoryItem
    }
}

public enum PublicPermissionSectionModelType: Int {
    case crossTenant   //分享到组织外
    case partnerTenant   //分享到关联组织
    case manageCollaborator //分享设置/谁可以管理协作者-权限维度
    case security  //安全设置
    case comment  //评论设置

    public init(_ value: Int) {
        self = PublicPermissionSectionModelType(rawValue: value) ?? .crossTenant
    }
}

//public class PublicPermissionSectionModel {
//    var type: PublicPermissionSectionModelType
//    var title: String
//    var models: [PublicPermissionCellModel]
//
//    init(type: PublicPermissionSectionModelType,
//        title: String,
//         models: [PublicPermissionCellModel]) {
//        self.type = type
//        self.title = title
//        self.models = models
//    }
//}
