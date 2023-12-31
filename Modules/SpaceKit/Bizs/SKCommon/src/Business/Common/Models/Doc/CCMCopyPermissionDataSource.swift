//
//  CCMCopyPermissionDataSource.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/8/3.
//  


import Foundation
import SpaceInterface

/// doc & drive中，评论 & Feed的文字可复制权限数据源
public protocol CCMCopyPermissionDataSource: AnyObject {
    /// doc & drive 的owner是否允许复制
    @available(*, deprecated, message: "Use permissionService instead - PermissionSDK")
    func ownerAllowCopy() -> Bool

    /// 是否有文档预览权限
    func canPreview() -> Bool

    @available(*, deprecated, message: "Use permissionService instead - PermissionSDK")
    func adminAllowCopyFG() -> Bool

    func getCopyPermissionService() -> UserPermissionService?
}

public extension CCMCopyPermissionDataSource {
    @available(*, deprecated, message: "Use permissionService instead - PermissionSDK")
    func adminAllowCopyFG() -> Bool {
        return AdminPermissionManager.adminCanCopy()
    }

    @available(*, deprecated, message: "Use permissionService instead - PermissionSDK")
    func ownerAllowCopyFG() -> Bool {
        return ownerAllowCopy()
    }
}

//public extension CCMCopyPermissionDataSource where Self: BaseJSService {
//
//    func ownerAllowCopy() -> Bool {
//        return model?.permissionConfig.canCopy ?? false
//    }
//
//    func canPreview() -> Bool {
//        return model?.permissionConfig.userPermissions?.canPreview() ?? false
//    }
//}
