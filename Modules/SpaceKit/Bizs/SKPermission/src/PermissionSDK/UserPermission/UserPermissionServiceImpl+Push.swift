//
//  UserPermissionServiceImpl+Push.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/5/8.
//

import Foundation
import SpaceInterface
import RxSwift
// 依赖 Push 相关
import SKCommon

protocol PermissionCommonPushManager {
    func register(with delegate: CommonPushDataDelegate)
    func unRegister()
}

extension CommonPushDataManager: PermissionCommonPushManager {
    func register(with delegate: CommonPushDataDelegate) {
        self.delegate = delegate
        self.register()
    }
}

class UserPermissionServicePushWrapper {

    private static let pushTag = StablePushPrefix.permission.rawValue

    private let backing: UserPermissionService
    private let objToken: String
    private let objType: DocsType

    private let stablePushManager: StablePushManagerProtocol
    private let commonPushManager: PermissionCommonPushManager

    private let disposeBag = DisposeBag()

    convenience init(backing: UserPermissionService, objToken: String, objType: DocsType) {
        let pushInfo = SKPushInfo(tag: StablePushPrefix.permission.rawValue + objToken,
                                  resourceType: StablePushPrefix.permission.resourceType(),
                                  routeKey: objToken,
                                  routeType: .token)
        let stablePushManager = StablePushManager(pushInfo: pushInfo)
        let commonPushManager = CommonPushDataManager(fileToken: objToken,
                                                      type: objType,
                                                      operation: .groupChange)

        self.init(backing: backing,
                  objToken: objToken,
                  objType: objType,
                  stablePushManager: stablePushManager,
                  commonPushManager: commonPushManager)
    }

    init(backing: UserPermissionService,
         objToken: String,
         objType: DocsType,
         stablePushManager: StablePushManagerProtocol,
         commonPushManager: PermissionCommonPushManager) {
        self.backing = backing
        self.objToken = objToken
        self.objType = objType
        self.stablePushManager = stablePushManager
        self.commonPushManager = commonPushManager

        registerPush()
    }

    deinit {
        stablePushManager.unRegister()
        commonPushManager.unRegister()
    }

    private func registerPush() {
        Logger.info("UserPermission.Push - register push", extraInfo: ["sessionID": sessionID])
        stablePushManager.register(with: self)
        commonPushManager.register(with: self)
    }
}

extension UserPermissionServicePushWrapper: StablePushManagerDelegate {
    func stablePushManager(_ manager: StablePushManagerProtocol,
                           didReceivedData data: [String : Any],
                           forServiceType type: String,
                           andTag tag: String) {
        Logger.info("UserPermission.Push - receive stable push", extraInfo: ["sessionID": sessionID])
        updateUserPermission().subscribe().disposed(by: disposeBag)
    }
    var pushFileToken: String? { objToken }
    var pushFileType: Int? { objType.rawValue }
}

extension UserPermissionServicePushWrapper: CommonPushDataDelegate {
    func didReceiveData(response: [String : Any]) {
        Logger.info("UserPermission.Push - receive common push", extraInfo: ["sessionID": sessionID])
        updateUserPermission().subscribe().disposed(by: disposeBag)
    }
}

// 以下方法都透传给 backing
extension UserPermissionServicePushWrapper: UserPermissionService {
    var ready: Bool { backing.ready }
    var hasPermission: Bool { backing.hasPermission }
    var sessionID: String { backing.sessionID }
    var defaultBizDomain: PermissionRequest.BizDomain { backing.defaultBizDomain }

    var onPermissionUpdated: Observable<UserPermissionResponse> { backing.onPermissionUpdated }
    var offlinePermission: Observable<UserPermissionResponse> { backing.offlinePermission }
    var permissionResponse: UserPermissionResponse? { backing.permissionResponse }
    var containerResponse: PermissionContainerResponse? { backing.containerResponse }

    func updateUserPermission() -> Single<UserPermissionResponse> {
        backing.updateUserPermission()
    }

    func setUserPermission(data: Data) throws -> UserPermissionResponse {
        try backing.setUserPermission(data: data)
    }

    func parsePermissionContainer(data: Data) throws -> PermissionContainerResponse {
        try backing.parsePermissionContainer(data: data)
    }

    func validate(operation: PermissionRequest.Operation, bizDomain: PermissionRequest.BizDomain) -> PermissionResponse {
        backing.validate(operation: operation, bizDomain: bizDomain)
    }

    func validate(exemptScene: PermissionExemptScene) -> PermissionResponse {
        backing.validate(exemptScene: exemptScene)
    }

    func asyncValidate(operation: PermissionRequest.Operation,
                       bizDomain: PermissionRequest.BizDomain,
                       completion: @escaping (PermissionResponse) -> Void) {
        backing.asyncValidate(operation: operation,
                              bizDomain: bizDomain,
                              completion: completion)
    }

    func asyncValidate(exemptScene: PermissionExemptScene, completion: @escaping (PermissionResponse) -> Void) {
        backing.asyncValidate(exemptScene: exemptScene, completion: completion)
    }

    func update(tenantID: String) {
        backing.update(tenantID: tenantID)
    }

    /// 管控的资源可见时触发，对应 viewWillAppear
    func notifyResourceWillAppear() {
        backing.notifyResourceWillAppear()
    }
    /// 管控的资源不可见时触发，对应 viewDidDisappear
    func notifyResourceDidDisappear() {
        backing.notifyResourceDidDisappear()
    }
}
