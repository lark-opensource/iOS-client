//
//  DriveThirdPartyAttachmentPermissionValidator.swift
//  SKDrive
//
//  Created by Weston Wu on 2023/8/23.
//

import Foundation
import SpaceInterface
import SKFoundation
import SKResource

struct DriveThirdPartyAttachmentPermissionValidator: UserPermissionValidator {
    var name: String { "DriveThirdPartyAttachmentPermissionValidator" }
    typealias UserPermissionModel = DriveThirdPartyAttachmentPermission

    let userPermission: DriveThirdPartyAttachmentPermission?
    let isFromCache: Bool

    init(model: DriveThirdPartyAttachmentPermission?, isFromCache: Bool) {
        self.userPermission = model
        self.isFromCache = isFromCache
    }

    func validate(request: PermissionRequest) -> PermissionValidatorResponse {
        DocsLogger.info("UserPermission.Drive3rdAttachment - start validate request",
                        component: LogComponents.permissionSDK,
                        traceId: request.traceID)
        guard let action = Self.convertAction(operation: request.operation) else {
            DocsLogger.info("UserPermission.Drive3rdAttachment - skipped, irrelevant operation for drive 3rd attachment permission",
                            extraInfo: ["operation": request.operation],
                            component: LogComponents.permissionSDK,
                            traceId: request.traceID)
            return .allow {}
        }
        DocsLogger.info("UserPermission.Drive3rdAttachment - validate action: \(action)",
                        component: LogComponents.permissionSDK,
                        traceId: request.traceID)
        return validate(request: request, action: action)
    }

    func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionValidatorResponse) -> Void) {
        DocsLogger.info("UserPermission.Drive3rdAttachment - async validate not impl, fallback to sync validate request",
                        component: LogComponents.permissionSDK,
                        traceId: request.traceID)
        // 用户权限检查没有所谓的异步鉴权逻辑，与同步鉴权相同
        let response = validate(request: request)
        completion(response)
    }

    private func validate(request: PermissionRequest, action: DriveThirdPartyAttachmentPermission.Action) -> PermissionValidatorResponse {
        guard let userPermission else {
            DocsLogger.warning("UserPermission.Drive3rdAttachment - return forbidden response when validate action without attachment permission",
                            extraInfo: ["operation": request.operation],
                            component: LogComponents.permissionSDK,
                            traceId: request.traceID)
            return .forbidden(denyType: .blockByUserPermission(reason: .userPermissionNotReady),
                              preferUIStyle: .disabled,
                              defaultUIBehaviorType: .error(text: BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission,
                                                            allowOverrideMessage: true))
        }

        guard !isFromCache || request.operation.isOfflineEnabled else {
            DocsLogger.warning("UserPermission.Drive3rdAttachment - return forbidden response when validate action not support cache",
                            extraInfo: ["operation": request.operation],
                            component: LogComponents.permissionSDK,
                            traceId: request.traceID)
            return .forbidden(denyType: .blockByUserPermission(reason: .cacheNotSupport),
                              preferUIStyle: .disabled,
                              defaultUIBehaviorType: .error(text: BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission,
                                                            allowOverrideMessage: true))
        }

        if userPermission.check(action: action) {
            DocsLogger.info("UserPermission.Drive3rdAttachment - attachment permission pass, return allow response",
                            component: LogComponents.permissionSDK,
                            traceId: request.traceID)
            return .allow {}
        }

        let reason = userPermission.denyReason(for: action) ?? .unknown
        DocsLogger.warning("UserPermission.Drive3rdAttachment - attachment permission failed, return forbidden response",
                           extraInfo: [
                            "action": action,
                            "reason": reason
                           ],
                           component: LogComponents.permissionSDK,
                           traceId: request.traceID)
        return .forbidden(denyType: .blockByUserPermission(reason: reason),
                          preferUIStyle: .disabled,
                          defaultUIBehaviorType: .error(text: BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission,
                                                        allowOverrideMessage: true))
    }

    // TODO: 补充第三方附件权限管控的操作和点位映射
    static func convertAction(operation: PermissionRequest.Operation) -> DriveThirdPartyAttachmentPermission.Action? {
        switch operation {
        case .view:
            return .view
        case .edit:
            return .edit
        case .copyContent:
            return .copy
        case .export, .openWithOtherApp, .downloadAttachment:
            return .export
        case .importToOnlineDocument:
            return .export
        default:
            DocsLogger.warning("UserPermission.Drive3rdAttachment - undefined operation \(operation) found")
            spaceAssertionFailure("un-define operation \(operation) for drive 3rd permisssion")
            return nil
        }
    }
}
