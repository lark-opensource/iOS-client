//
//  CommonProviderConfig.swift
//  SKSpace
//
//  Created by Weston Wu on 2023/5/10.
//

import Foundation
import SKCommon
import SpaceInterface
import RxSwift
import RxRelay
import SKInfra

// 传递 class 类型参数
class CommonMoreProviderContext {
    let entry: SpaceEntry
    let sourceView: UIView

    init(entry: SpaceEntry, sourceView: UIView) {
        self.entry = entry
        self.sourceView = sourceView
    }
}

// 传递值类型参数
struct CommonMoreProviderConfig {
    let forbiddenItems: [MoreItemType]
    // nil 表示默认都展示
    let allowItems: [MoreItemType]?
    let listType: SpaceMoreAPI.ListType
}

class CommonMoreProviderPermissionContext {
    // 实体自身权限
    let permissionService: UserPermissionService
    let permissionRelay: BehaviorRelay<UserPermissionAbility?>
    // 父容器权限
    let parentPermissionService: UserPermissionService
    let parentPermissionUpdated: Observable<UserPermissionAbility?>

    init(permissionService: UserPermissionService,
         permissionRelay: BehaviorRelay<UserPermissionAbility?>,
         parentPermissionService: UserPermissionService,
         parentPermissionUpdated: Observable<UserPermissionAbility?>) {
        self.permissionService = permissionService
        self.permissionRelay = permissionRelay
        self.parentPermissionService = parentPermissionService
        self.parentPermissionUpdated = parentPermissionUpdated
    }

    /// 不考虑父文件夹权限的可以省略
    init(permissionService: UserPermissionService,
         permissionRelay: BehaviorRelay<UserPermissionAbility?>) {
        self.permissionService = permissionService
        self.permissionRelay = permissionRelay
        let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
        self.parentPermissionService = permissionSDK.userPermissionService(for: .personalRootFolder)
        self.parentPermissionUpdated = BehaviorRelay<UserPermissionAbility?>(value: UserPermissionMask.mockPermisson()).asObservable()
    }
}
