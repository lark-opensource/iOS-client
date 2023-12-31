//
//  DriveCopyManager.swift
//  SKDrive
//
//  Created by ByteDance on 2022/9/21.
//

import Foundation
import SKCommon
import SKFoundation
import UniverseDesignToast
import SKResource
import RxSwift
import RxCocoa
import LarkSecurityComplianceInterface
import SpaceInterface

// MARK: static lib injection
@available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
protocol AdminManagerBridge {
    static func adminCanCopy(docType: DocsType?, token: String?) -> Bool
}
@available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
protocol DLPManagerBridge {
    static func status(with token: String, type: DocsType, action: DlpCheckAction) -> DlpCheckStatus
}
@available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
public protocol CACManagerBridge {
    static func syncValidate(entityOperate: LarkSecurityComplianceInterface.EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: DocsType, token: String?) -> CCMSecurityPolicyService.ValidateResult

    static func asyncValidate(entityOperate: EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: DocsType, token: String?, completion: @escaping (CCMSecurityPolicyService.ValidateResult) -> Void)

    static func showInterceptDialog(entityOperate: EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: DocsType, token: String?)
}
@available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
class CACManager: CACManagerBridge {
    static func syncValidate(entityOperate: LarkSecurityComplianceInterface.EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: DocsType, token: String?) -> CCMSecurityPolicyService.ValidateResult {
        return CCMSecurityPolicyService.syncValidate(entityOperate: entityOperate, fileBizDomain: fileBizDomain, docType: docType, token: token)
    }

    static func asyncValidate(entityOperate: EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: DocsType, token: String?, completion: @escaping (CCMSecurityPolicyService.ValidateResult) -> Void) {
        CCMSecurityPolicyService.asyncValidate(entityOperate: entityOperate,
                                               fileBizDomain: fileBizDomain,
                                               docType: docType,
                                               token: token,
                                               completion: completion)
    }
    
    static func showInterceptDialog(entityOperate: EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: DocsType, token: String?) {
        CCMSecurityPolicyService.showInterceptDialog(entityOperate: entityOperate, fileBizDomain: fileBizDomain, docType: docType, token: token)
    }
}
@available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
extension DlpManager: DLPManagerBridge {}
@available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
extension AdminPermissionManager: AdminManagerBridge {}

// MARK: copy manager logic
class DriveCopyMananger {
    typealias TipsType = DocsExtension<UDToast>.MsgType
    typealias InterceptCopyResult = (needInterceptCopy: Bool, reason: String?, type: TipsType?, iscacIntercept: Bool? )

    typealias DriveCopyResponse = (allow: Bool, completion: (UIViewController) -> Void)

    private var adminManagerType: AdminManagerBridge.Type
    private var dlpManagerType: DLPManagerBridge.Type
    private var previewFrom: DrivePreviewFrom?
    private let sameTenantRelay: BehaviorRelay<Bool>
    private var isSameTenant: Bool { sameTenantRelay.value }
    private let permissionService: UserPermissionService

    private var bizDomain: PermissionRequest.BizDomain {
        (previewFrom ?? .unknown).permissionBizDomain
    }

    init(adminManagerType: AdminManagerBridge.Type = AdminPermissionManager.self,
         dlpManagerType: DLPManagerBridge.Type = DlpManager.self,
         previewFrom: DrivePreviewFrom? = nil,
         sameTenantRelay: BehaviorRelay<Bool> = BehaviorRelay(value: true),
         permissionService: UserPermissionService) {
        self.adminManagerType = adminManagerType
        self.dlpManagerType = dlpManagerType
        self.previewFrom = previewFrom
        self.sameTenantRelay = sameTenantRelay
        self.permissionService = permissionService
    }
    
    // 是否需要启动copy保护，是否有copy权限
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    func needSecurityCopyAndCopyEnable(token: String?,
                                       canEdity: BehaviorRelay<Bool>,
                                       canCopy: BehaviorRelay<Bool>,
                                       enableSecurityCopy: Bool) -> Driver<(String?, Bool)> {
        return Observable.combineLatest(canEdity, canCopy)
            .map {[weak self] (canEdit, canCopy) in
                guard let self = self else { return (nil, false) }
                let result: CCMSecurityPolicyService.ValidateResult
                let previewFromBizDomain = self.previewFrom ?? .unknown
                if self.previewFrom == .im {
                    result = CCMSecurityPolicyService.syncValidate(entityOperate: .imFileCopy, fileBizDomain: previewFromBizDomain.transfromBizDomain, docType: .imMsgFile, token: nil)
                } else {
                    result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmCopy, fileBizDomain: previewFromBizDomain.transfromBizDomain, docType: .file, token: nil)
                }
                let dlpCopy = self.dlpCanCopyAndReason(token: token).canCopy
                if self.needSecurityCopy(canEdit: canEdit, canCopy: canCopy, enableSecurityCopy: enableSecurityCopy, cacCopy: result.allow, dlpCopy: dlpCopy) {
                    DocsLogger.driveInfo("enable copy security, can copy")
                    return (token, true)
                }
                let canCopy = dlpCopy && canCopy && result.allow
                DocsLogger.driveInfo("xxxx disable copy security, can copy \(canCopy)")
                return (nil, canCopy)
            }.asDriver(onErrorJustReturn: (nil, false))
    }
    
    // text view 是否需要接管copy动作
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    func interceptCopy(token: String?, canEdit: Bool, canCopy: Bool, enableSecurityCopy: Bool) -> InterceptCopyResult {
        let dlpCopy = dlpCanCopyAndReason(token: token)
        if dlpCopy.ttBlock {
            DocsLogger.driveInfo("DriveCopyMananger: tt block")
            PermissionStatistics.shared.reportDocsCopyClick(isSuccess: false)
            return InterceptCopyResult(needInterceptCopy: true,
                                       reason: dlpCopy.reason,
                                       type: dlpCopy.type, iscacIntercept: nil)
        }
        let cacResult: CCMSecurityPolicyService.ValidateResult
        let previewFromBizDomain = self.previewFrom ?? .unknown
        if self.previewFrom == .im {
            cacResult = CCMSecurityPolicyService.syncValidate(entityOperate: .imFileCopy, fileBizDomain: previewFromBizDomain.transfromBizDomain, docType: .imMsgFile, token: nil)
        } else {
            cacResult = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmCopy, fileBizDomain: previewFromBizDomain.transfromBizDomain, docType: .file, token: nil)
        }
        if dlpCanCopyAndReason(token: token).canCopy &&
            canCopy &&
            cacResult.allow {
            DocsLogger.driveInfo("DriveCopyMananger: can copy")
            PermissionStatistics.shared.reportDocsCopyClick(isSuccess: true)
            return  InterceptCopyResult(needInterceptCopy: false, reason: nil, type: nil, iscacIntercept: nil)
        }
        if needSecurityCopy(canEdit: canEdit, canCopy: canCopy, enableSecurityCopy: enableSecurityCopy, cacCopy: cacResult.allow, dlpCopy: dlpCopy.canCopy) {
            DocsLogger.driveInfo("DriveCopyMananger: need security copy")
            PermissionStatistics.shared.reportDocsCopyClick(isSuccess: true)
            return InterceptCopyResult(needInterceptCopy: false, reason: nil, type: nil, iscacIntercept: nil)
        }
        if !cacResult.allow && cacResult.validateSource == .fileStrategy {
            DocsLogger.driveInfo("DriveCopyMananger: cac can copy false")
            return InterceptCopyResult(needInterceptCopy: true,
                                       reason: nil,
                                       type: nil, iscacIntercept: true)
        } else if !cacResult.allow && cacResult.validateSource == .securityAudit {
            DocsLogger.driveInfo("DriveCopyMananger: admin can copy false")
            return InterceptCopyResult(needInterceptCopy: true,
                                       reason: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast,
                                       type: .failure, iscacIntercept: nil)
        }
        if !dlpCopy.canCopy {
            DocsLogger.driveInfo("DriveCopyMananger: dlp failed")
            PermissionStatistics.shared.reportDocsCopyClick(isSuccess: false)
            return InterceptCopyResult(needInterceptCopy: true,
                                       reason: dlpCopy.reason,
                                       type: dlpCopy.type, iscacIntercept: nil)

        }
        if !canCopy {
            DocsLogger.driveInfo("DriveCopyMananger: user has no export permission")
            PermissionStatistics.shared.reportDocsCopyClick(isSuccess: false)
            return InterceptCopyResult(needInterceptCopy: true,
                                       reason: BundleI18n.SKResource.Doc_Doc_CopyFailed,
                                       type: .failure, iscacIntercept: nil)
        }
        DocsLogger.driveInfo("DriveCopyMananger: default")
        PermissionStatistics.shared.reportDocsCopyClick(isSuccess: false)
        return InterceptCopyResult(needInterceptCopy: true,
                                   reason: BundleI18n.SKResource.Doc_Doc_CopyFailed,
                                   type: .failure, iscacIntercept: nil)
    }
    
    private func needSecurityCopy(canEdit: Bool, canCopy: Bool, enableSecurityCopy: Bool, cacCopy: Bool, dlpCopy: Bool) -> Bool {
        return canEdit && !canCopy && enableSecurityCopy && cacCopy && dlpCopy
    }
    
    private func dlpCanCopyAndReason(token: String?) -> (canCopy: Bool, reason: String?, type: TipsType?, ttBlock: Bool) {
        guard let token = token else {
            DocsLogger.driveError("token is nil")
            return (canCopy: true, reason: nil, type: nil, ttBlock: false)
        }
        let dlpStatus = dlpManagerType.status(with: token, type: DocsType.file, action: .COPY)
        guard dlpStatus == .Safe else {
            DocsLogger.driveInfo("dlp control, can not export. dlp \(dlpStatus.rawValue)")
            var text = dlpStatus.text(action: .COPY, isSameTenant: isSameTenant)
            let type: DocsExtension<UDToast>.MsgType = dlpStatus == .Detcting ? .tips : .failure
            PermissionStatistics.shared.reportDlpSecurityInterceptToastView(action: .COPY, status: dlpStatus, isSameTenant: isSameTenant)
            let ttBlock = dlpStatus == .Block
            if ttBlock {
                text = BundleI18n.SKResource.LarkCCM_Docs_DLP_CopyFailed_Toast
            }
            return (canCopy: false, reason: text, type: type, ttBlock: ttBlock)
        }
        return (canCopy: true, reason: nil, type: nil, ttBlock: false)
    }

    func checkCopyPermission(allowSecurityCopy: Bool) -> DriveCopyResponse {
        let copyResponse = permissionService.validate(operation: .copyContent, bizDomain: bizDomain)
        switch copyResponse.result {
        case .allow:
            return (true, { controller in
                copyResponse.didTriggerOperation(controller: controller)
            })
        case let .forbidden(denyType, _):
            if !allowSecurityCopy {
                return (false, { controller in
                    copyResponse.didTriggerOperation(controller: controller, BundleI18n.SKResource.Doc_Doc_CopyFailed)
                })
            }
            return checkCopyResponse(denyType: denyType, response: copyResponse)
        }
    }

    private func checkCopyResponse(denyType: PermissionResponse.DenyType,
                                   response: PermissionResponse) -> DriveCopyResponse {
        if checkAllowSecurityPageCopy(denyType: denyType) {
            return (true, { _ in
                DocsLogger.driveInfo("allow copy by security copy")
            })
        } else {
            return (false, { controller in
                response.didTriggerOperation(controller: controller, BundleI18n.SKResource.Doc_Doc_CopyFailed)
            })
        }
    }

    private func checkAllowSecurityPageCopy(denyType: PermissionResponse.DenyType) -> Bool {
        guard case let .blockByUserPermission(reason) = denyType else {
            return false
        }

        switch reason {
        case .blockByServer, .unknown, .userPermissionNotReady, .blockByAudit:
            return permissionService.validate(operation: .edit, bizDomain: bizDomain).allow
        case .blockByCAC, .cacheNotSupport:
            return false
        }
    }

    // 监听复制权限变化，返回 (单文档保护PointID, 是否允许复制)
    func monitorCopyPermission(token: String?, allowSecurityCopy: Bool) -> Driver<(String?, Bool)> {
        return permissionService.onPermissionUpdated.map { [weak self] _ in
            guard let self else { return (nil, false) }
            let previewFrom = self.previewFrom ?? .unknown
            let bizDomain = previewFrom.permissionBizDomain
            let response = self.permissionService.validate(operation: .copyContent, bizDomain: self.bizDomain)
            switch response.result {
            case .allow:
                return (nil, true)
            case let .forbidden(denyType, _):
                if allowSecurityCopy, self.checkAllowSecurityPageCopy(denyType: denyType) {
                    return (token, true)
                } else {
                    return (nil, false)
                }
            }
        }.asDriver(onErrorJustReturn: (nil, false))
    }
}
