//
//  SecurityPolicyConverter+DLP.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/9/7.
//

import Foundation
import SpaceInterface
import LarkSecurityComplianceInterface
import SKFoundation
import SKResource
import LarkContainer

extension SecurityPolicyConverter {

    static func convertDLPResponse(result: ValidateResult,
                                   request: PermissionRequest,
                                   maxCostTime: TimeInterval,
                                   isSameTenant: Bool) -> PermissionValidatorResponse {
        let source = result.extra.resultSource
        Logger.warning("SecurityPolicy.Converter - return forbidden response for DLP \(source) status",
                       traceID: request.traceID)
        let message = errorMessage(source: source,
                                   operation: request.operation,
                                   maxCostTime: maxCostTime,
                                   isSameTenant: isSameTenant)
        switch source {
        case .dlpDetecting:
            return .forbidden(denyType: .blockByDLPDetecting,
                              defaultUIBehaviorType: .info(text: message, allowOverrideMessage: false) {
                Logger.info("SecurityPolicy - default behavior called for DLP detecting",
                            traceID: request.traceID)
                result.report()
                result.handleAction()
            })
        case .dlpSensitive, .ttBlock:
            return .forbidden(denyType: .blockByDLPSensitive,
                              defaultUIBehaviorType: .error(text: message, allowOverrideMessage: false) {
                Logger.info("SecurityPolicy - default behavior called for DLP \(source)",
                            traceID: request.traceID)
                result.report()
                result.handleAction()
            })
        case .unknown, .fileStrategy, .securityAudit:
            spaceAssertionFailure("no DLP source should not be used here")
            return .forbidden(denyType: .blockByDLPSensitive,
                              defaultUIBehaviorType: .error(text: message, allowOverrideMessage: false) {
                Logger.warning("SecurityPolicy - default behavior called for DLP invalid source: \(source)",
                            traceID: request.traceID)
                result.report()
                result.handleAction()
            })
        }
    }

    static func errorMessage(source: ValidateSource,
                             operation: PermissionRequest.Operation,
                             maxCostTime: TimeInterval,
                             isSameTenant: Bool) -> String {
        switch source {
        case .dlpDetecting:
            // nolint-next-line: magic number
            let maxCostTimeMinutes = Int(maxCostTime / 60)
            return BundleI18n.SKResource.LarkCCM_Docs_DLP_SystemChecking_Mob(maxCostTimeMinutes)
        case .ttBlock where operation == .copyContent:
            return BundleI18n.SKResource.LarkCCM_Docs_DLP_CopyFailed_Toast
        case .dlpSensitive, .ttBlock:
            return isSameTenant ?
            BundleI18n.SKResource.LarkCCM_Docs_DLP_SensitiveInfo_ActionFailed :
            BundleI18n.SKResource.LarkCCM_Docs_DLP_Toast_ActionFailed
        case .unknown, .fileStrategy, .securityAudit:
            spaceAssertionFailure("no DLP source should not be used here")
            return isSameTenant ?
            BundleI18n.SKResource.LarkCCM_Docs_DLP_SensitiveInfo_ActionFailed :
            BundleI18n.SKResource.LarkCCM_Docs_DLP_Toast_ActionFailed
        }
    }

    // DLP 相关的操作会向安全 SDK 注入 token 和 tokenEntityType 信息
    static var dlpRelevantOperations: [EntityOperate] {
        [
            .ccmCopy,
            .ccmExport,
            .ccmFileDownload,
            .ccmAttachmentDownload,
            .ccmCreateCopy,
            .openExternalAccess
        ]
    }
}

extension DLPSceneContext {
    static var dlpPointKeysForFile: [(PointKey, EntityOperate)] {
        [
            (.ccmCopy, .ccmCopy),
            (.ccmFileDownload, .ccmFileDownload),
            (.ccmCreateCopy, .ccmCreateCopy),
            (.ccmOpenExternalAccess, .openExternalAccess)
        ]
    }

    static var dlpPointKeysForAttachmentFile: [(PointKey, EntityOperate)] {
        [
            (.ccmCopy, .ccmCopy),
            (.ccmAttachmentDownload, .ccmAttachmentDownload)
        ]
    }

    static var dlpPointKeysForDocument: [(PointKey, EntityOperate)] {
        [
            (.ccmCopy, .ccmCopy),
            (.ccmExport, .ccmExport),
            (.ccmCreateCopy, .ccmCreateCopy),
            (.ccmAttachmentDownload, .ccmAttachmentDownload),
            (.ccmOpenExternalAccess, .openExternalAccess)
        ]
    }
}

class DLPSceneContext {

    private let sceneContext: SecurityPolicy.SceneContext
    private let sessionID: String
    var onDLPUpdated: (() -> Void)? {
        get {
            sceneContext.onEventUpdate
        }
        set {
            sceneContext.onEventUpdate = newValue
        }
    }

    #if DEBUG
    let pointKeys: [(PointKey, EntityOperate)]
    #endif

    init(token: String,
         type: DocsType,
         operatorUserID: Int64,
         operatorTenantID: Int64,
         pointKeys: [(PointKey, EntityOperate)],
         sessionID: String) {
        self.sessionID = sessionID
        let resolver = Container.shared.getCurrentUserResolver()
        let entityType = SecurityPolicyConverter.convertEntityType(docsType: type)
        #if DEBUG
        self.pointKeys = pointKeys
        #endif
        let models = pointKeys.map { (pointKey, entityOperate) in
            let entity = CCMEntity(entityType: entityType,
                                   entityDomain: .ccm,
                                   entityOperate: entityOperate,
                                   operatorTenantId: operatorTenantID,
                                   operatorUid: operatorUserID,
                                   fileBizDomain: .ccm,
                                   token: token,
                                   tokenEntityType: entityType)
            return PolicyModel(pointKey, entity)
        }
        sceneContext = SecurityPolicy.SceneContext(userResolver: resolver, scene: .ccmFile(models))
    }

    func update(ownerUserID: String, ownerTenantID: String) {
        guard case let .ccmFile(models) = sceneContext.scene else {
            return
        }
        let updateModels = models.compactMap { model -> PolicyModel? in
            guard let entity = model.entity as? CCMEntity else { return nil }
            entity.ownerUserId = Int64(ownerUserID)
            entity.ownerTenantId = Int64(ownerTenantID)
            return PolicyModel(model.pointKey, entity)
        }
        sceneContext.updateTrigger(.ccmFile(updateModels))
    }

    func willAppear() {
        PermissionSDKLogger.info("notify dlp scene context will appear", extraInfo: [
            "sessionID": sessionID,
            "sceneID": sceneContext.identifier
        ])
        sceneContext.beginTrigger()
    }

    func didDisappear() {
        PermissionSDKLogger.info("notify dlp scene context did disappear", extraInfo: [
            "sessionID": sessionID,
            "sceneID": sceneContext.identifier
        ])
        sceneContext.endTrigger()
    }

    deinit {
        sceneContext.endTrigger()
    }
}
