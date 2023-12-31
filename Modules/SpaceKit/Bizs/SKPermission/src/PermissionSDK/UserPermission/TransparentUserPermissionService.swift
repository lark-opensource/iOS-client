//
//  TransparentUserPermissionService.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/8/22.
//

import Foundation
import SpaceInterface
import SKFoundation
import RxSwift
import RxRelay

// 无实际用户权限逻辑，仅用于代持有 PermissionSDK 所需的大部分鉴权上下文信息，用于 DriveSDK 场景使用
class TransparentUserPermissionService: UserPermissionService {

    let ready: Bool = true
    let hasPermission: Bool = true
    let onPermissionUpdated: Observable<UserPermissionResponse> = .just(.success)
    let offlinePermission: Observable<UserPermissionResponse> = .just(.success)
    let permissionResponse: UserPermissionResponse? = .success
    let containerResponse: PermissionContainerResponse? = nil

    private let entity: PermissionRequest.Entity
    let defaultBizDomain: PermissionRequest.BizDomain
    private var extraInfo: PermissionExtraInfo
    private let permissionSDK: PermissionSDK
    let sessionID: String

    init(entity: PermissionRequest.Entity,
         bizDomain: PermissionRequest.BizDomain,
         permissionSDK: PermissionSDK,
         extraInfo: PermissionExtraInfo = PermissionExtraInfo(),
         sessionID: String) {
        self.entity = entity
        self.defaultBizDomain = bizDomain
        self.permissionSDK = permissionSDK
        self.extraInfo = extraInfo
        self.sessionID = sessionID
    }

    func updateUserPermission() -> Single<UserPermissionResponse> {
        .just(.success)
    }

    func setUserPermission(data: Data) throws -> UserPermissionResponse {
        return .success
    }

    func parsePermissionContainer(data: Data) throws -> PermissionContainerResponse {
        throw PermissionSDKError.invalidOperation(reason: "TransparentUserPermissionService cannot parse permission")
    }

    func update(tenantID: String) {
        Logger.info("TransparentUserPermission - updating extraInfo.entityTenantID",
                    extraInfo: ["sessionID": sessionID])
        extraInfo.entityTenantID = tenantID
    }

    func validate(operation: PermissionRequest.Operation, bizDomain: PermissionRequest.BizDomain) -> PermissionResponse {
        let request = PermissionRequest(entity: entity,
                                        operation: operation,
                                        bizDomain: bizDomain,
                                        extraInfo: extraInfo)
        return validate(request: request)
    }

    func validate(exemptScene: PermissionExemptScene) -> PermissionResponse {
        let request = permissionSDK.getExemptRequest(entity: entity, exemptScene: exemptScene, extraInfo: extraInfo)
        return validate(request: request)
    }

    private func validate(request: PermissionRequest) -> PermissionResponse {
        Logger.info("TransparentUserPermission - start validate request",
                    extraInfo: [
                        "sessionID": sessionID,
                    ],
                    traceID: request.traceID)
        return permissionSDK.validate(request: request)
    }

    func asyncValidate(operation: PermissionRequest.Operation, bizDomain: PermissionRequest.BizDomain, completion: @escaping (PermissionResponse) -> Void) {
        let request = PermissionRequest(entity: entity,
                                        operation: operation,
                                        bizDomain: bizDomain,
                                        extraInfo: extraInfo)
        asyncValidate(request: request, completion: completion)
    }

    func asyncValidate(exemptScene: PermissionExemptScene, completion: @escaping (PermissionResponse) -> Void) {
        let request = permissionSDK.getExemptRequest(entity: entity,
                                                     exemptScene: exemptScene,
                                                     extraInfo: extraInfo)
        asyncValidate(request: request, completion: completion)
    }

    private func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionResponse) -> Void) {
        Logger.info("TransparentUserPermission - start async validate request",
                    extraInfo: [
                        "sessionID": sessionID,
                    ],
                    traceID: request.traceID)
        permissionSDK.asyncValidate(request: request, completion: completion)
    }

    func notifyResourceWillAppear() {}

    func notifyResourceDidDisappear() {}
}
