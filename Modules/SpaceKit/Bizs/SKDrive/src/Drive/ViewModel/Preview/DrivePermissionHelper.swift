//
//  File.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/7/1.
//

import Foundation
import SKFoundation
import SKCommon
import SpaceInterface
import SKInfra

typealias PermissionChangedBlock = (DrivePermissionInfo) -> Void
protocol DrivePermissionHelperProtocol: AnyObject {

    var permissionService: UserPermissionService { get }
    @available(*, deprecated, message: "Use permissionService instead - PermissionSDK")
    func startMonitorPermission(startFetch: @escaping() -> Void,
                                permissionChanged: @escaping PermissionChangedBlock,
                                failed: @escaping (PermissionResponseModel) -> Void)
    func unRegister()
}

@available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
struct DrivePermissionInfo {
    let isReadable: Bool
    let isEditable: Bool
    let canComment: Bool
    let canExport: Bool
    let canCopy: Bool // 第三方附件权限区分copy和export，只有能copy才展示保存到云空间入口
    let canShowCollaboratorInfo: Bool
    let isCACBlock: Bool //是否被条件访问控制管控
    var permissionStatusCode: PermissionStatusCode?
    var userPermissions: UserPermissionAbility?

    var bizExtra: [String: Any]?

    static var noPermissionInfo: DrivePermissionInfo {
        return DrivePermissionInfo(isReadable: false,
                                   isEditable: false,
                                   canComment: false,
                                   canExport: false,
                                   canCopy: false,
                                   canShowCollaboratorInfo: true,
                                   isCACBlock: false,
                                   permissionStatusCode: nil,
                                   userPermissions: nil)
    }
}
@available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
class DrivePermissionHelper: DrivePermissionHelperProtocol {

    let fileToken: String
    let type: DocsType

    let permissionService: UserPermissionService

    var permissionObserver: PermissionObserver?
    var failedBlock: ((PermissionResponseModel) -> Void)?
    var permissionChangedBlock: PermissionChangedBlock?
    var startFetchBlock: (() -> Void)?
    var isReachable: Bool = DocsNetStateMonitor.shared.isReachable {
        didSet {
            if isReachable != oldValue && isReachable {
                fetchAllPermission()
            }
        }
    }

    /// 用户权限
    private(set) var userPermissions: UserPermissionAbility?
    /// 审核结果
    private(set) var permissionStatusCode: PermissionStatusCode?

    init(fileToken: String, type: DocsType, permissionService: UserPermissionService) {
        self.fileToken = fileToken
        self.type = type
        self.permissionService = permissionService
        setupNetworkMonitor()
    }
    deinit {
        DocsLogger.driveInfo("DrivePermissionHelper deInit")
        permissionObserver?.unRegister()
    }

    /// 监测网络连接变化
    private func setupNetworkMonitor() {
        DocsNetStateMonitor.shared.addObserver(self) { [weak self] (networkType, isReachable) in
            DocsLogger.debug("Current networkType is \(networkType)")
            self?.isReachable = isReachable
        }
    }

    /// 拉取user/public permission
    ///
    /// - Parameter completion: 拉取完成回调，缓存permission
    func fetchAllPermission(completion: @escaping (PermissionResponseModel) -> Void) {
        if permissionObserver == nil {
            permissionObserver = PermissionObserver(fileToken: fileToken, type: type.rawValue)
        }
        permissionObserver?.fetchAllPermission {[weak self] (response) -> Void in
            if response.error == nil {
                self?.userPermissions = response.userPermissions
                self?.permissionStatusCode = response.permissionStatusCode
            }
            completion(response)
        }
    }

    func startMonitorPermission(startFetch: @escaping() -> Void,
                                permissionChanged: @escaping PermissionChangedBlock,
                                failed: @escaping (PermissionResponseModel) -> Void) {
        permissionObserver = PermissionObserver(fileToken: fileToken, type: type.rawValue)
        permissionObserver?.addObserveForPermission(delegate: self, observeKey: .all)
        permissionChangedBlock = permissionChanged
        failedBlock = failed
        startFetchBlock = startFetch
        if isReachable {
            fetchAllPermission()
        }
    }
}



extension DrivePermissionHelper {

}

@available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
extension DrivePermissionHelper {
    var isReadable: Bool { return self.userPermissions?.canView() ?? false }

    var isEditable: Bool { return self.userPermissions?.canEdit() ?? false }

    var canComment: Bool { return self.userPermissions?.canComment() ?? false }

    var canExport: Bool { return self.userPermissions?.canExport() ?? false }

    var canCopy: Bool { return self.userPermissions?.canCopy() ?? false }

    var canShowCollaboratorInfo: Bool { return self.userPermissions?.canShowCollaboratorInfo() ?? false }

    func fetchUserPermission() {
        self.startFetchBlock?()
        if permissionObserver == nil {
            permissionObserver = PermissionObserver(fileToken: fileToken, type: type.rawValue)
        }
        permissionObserver?.fetchUserPermissions { [weak self] (permissionInfo, error) -> Void in
            guard let self = self else { return }
            self.userPermissions = permissionInfo?.0
            self.permissionStatusCode = permissionInfo?.1
            let permissionResponseModel = PermissionResponseModel(userPermissions: self.userPermissions,
                                                                  permissionStatusCode: self.permissionStatusCode,
                                                                  error: error)
            self.handlePermission(permissionResponseModel)
        }
    }

    private func fetchAllPermission() {
        self.startFetchBlock?()
        permissionObserver?.fetchAllPermission {[weak self] (response) -> Void in
            guard let self = self else { return }
            self.handlePermission(response)
        }
    }

    func handlePermission(_ response: PermissionResponseModel) {
        if response.error != nil {
            self.failedBlock?(response)
        } else if response.userPermissions?.adminBlocked() == true
                    || response.userPermissions?.shareControlByCAC() == true
                    || response.userPermissions?.previewControlByCAC() == true {
            response.error = NSError(domain: "Error: admin blocked or cac blocked", code: DocsNetworkError.Code.cacPermissonBlocked.rawValue)
            self.userPermissions = response.userPermissions
            self.permissionStatusCode = response.permissionStatusCode
            self.failedBlock?(response)
        } else {
            self.userPermissions = response.userPermissions
            self.permissionStatusCode = response.permissionStatusCode
            self.permissionChangedBlock?(self.currentPermissionInfo(response.userPermissions?.previewControlByCAC() ?? false))
        }
    }

    private func currentPermissionInfo(_ isCACBlock: Bool) -> DrivePermissionInfo {
        return DrivePermissionInfo(isReadable: isReadable,
                                   isEditable: isEditable,
                                   canComment: canComment,
                                   canExport: canExport,
                                   // canCopy 用于判断第三方附件是否展示保存到云空间入口
                                   // docs附件只通过判断canExport判断，所以这里canCopy的值
                                   // 和canExport相同
                                   canCopy: canCopy,
                                   canShowCollaboratorInfo: canShowCollaboratorInfo,
                                   isCACBlock: isCACBlock,
                                   permissionStatusCode: permissionStatusCode,
                                   userPermissions: userPermissions)
    }

    func unRegister() {
        permissionObserver?.unRegister()
        permissionObserver = nil
    }
}

@available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
extension DrivePermissionHelper: PermissionObserverDelegate {
    func didReceivePermissionData(response: PermissionResponseModel) {
        DocsLogger.driveInfo("did receive permission changed")
        handlePermission(response)
    }
}
