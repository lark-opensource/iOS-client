//
//  ContactSelect.swift
//  LarkContact
//
//  Created by SuPeng on 5/14/19.
//

import UIKit
import Foundation
import LarkMessengerInterface
import LarkSearchCore

// 选中的来源
enum SelectChannel: String {
    case search // 搜索
    case organization // 组织架构
    case collaboration // 关联组织
    case external // 外部联系人
    case group // 我的群组
    case mail // 邮箱联系人
    case sharedEmail // 公共邮箱
    case userGroup // 用户组
    case unkonwn
}

protocol HasSelectChannel {
    var selectChannel: SelectChannel { get }
}

protocol ContactSelect: UIViewController, HasSelectChannel {
    var contactPicker: LKContactPickerViewController { get }
    var dataSource: LKContactViewControllerDataSource { get }
    var configuration: LarkContactConfiguration { get }
    var style: NewDepartmentViewControllerStyle { get }
    var singleMultiChangeableStatus: SingleMultiChangeableStatus { get }
    var isSingleStatus: Bool { get }
}

extension ContactSelect {
    var contactPicker: LKContactPickerViewController {
        // 这里之前是强取navigation，转成LKContactPickerViewController
        // 但是有的时候会崩溃，原因未知。先保护一下，返回一个空的navi。
        // https://fabric.io/bytedance-ee-ios/ios/apps/com.bytedance.ee.inhouse.larkone/issues/5ce24348f8b88c29636456ba/sessions/b1891928dd6f43dfbb1d2d7949888efc_DNE_0_v2?
        if let picker = (navigationController as? LKContactPickerViewController) {
            return picker
        } else {
            let tracker = PickerAppReciable(pageName: "LKContactPickerViewController", fromType: .addGroupMember)
            tracker.initViewStart()
            let config = LarkContactConfiguration(
                style: .single(style: .defaultRoute),
                needSearchOuterTenant: true,
                checkInvitePermission: true
            )
            return LKContactPickerViewController(
                configuration: config,
                currentTenantId: "",
                rootViewController: UIViewController(),
                tracker: tracker
            )
        }
    }

    var dataSource: LKContactViewControllerDataSource {
        return contactPicker.dataSource
    }

    var configuration: LarkContactConfiguration {
        return contactPicker.configuration
    }

    var style: NewDepartmentViewControllerStyle {
        return configuration.style
    }

    var singleMultiChangeableStatus: SingleMultiChangeableStatus {
        get {
            return configuration.singleMultiChangeableStatus
        }
        set {
            configuration.singleMultiChangeableStatus = newValue
        }
    }

    var isSingleStatus: Bool {
        switch style {
        case .multi:
            return false
        case .single:
            return true
        case .singleMultiChangeable:
            switch singleMultiChangeableStatus {
            case .multi:
                return false
            case .single:
                return true
            }
        }
    }

    var selectChannel: SelectChannel {
        return .unkonwn
    }
}

extension Picker: HasSelectChannel {
    var selectChannel: SelectChannel {
        return .search
    }
}
