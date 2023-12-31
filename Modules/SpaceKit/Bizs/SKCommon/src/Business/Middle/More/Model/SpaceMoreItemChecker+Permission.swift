//
//  SpaceMoreItemChecker+Permission.swift
//  SKCommon
//
//  Created by Weston Wu on 2023/5/9.
//

import Foundation
import RxSwift
import RxRelay
import SpaceInterface
import SKFoundation
import SKResource
import LarkSecurityComplianceInterface

extension UserPermissionAbility {
    // swiftlint:disable cyclomatic_complexity
    // nolint: cyclomatic complexity
    public func have(permissionType: UserPermissionEnum) -> Bool {
        switch permissionType {
        case .view:
            return canView()
        case .edit:
            return canEdit()
        case .manageCollaborator:
            return canManageCollaborator()
        case .manageMeta:
            return canManageMeta()
        case .createSubNode:
            return canCreateSubNode()
        case .download:
            return canDownload()
        case .collect:
            return canCollect()
        case .operateFromDusbin:
            return canOperateFromDusbin()
        case .operateEntity:
            return canOperateEntity()
        case .inviteFullAccess:
            return canInviteFullAccess()
        case .inviteCanEdit:
            return canInviteCanEdit()
        case .inviteCanView:
            return canInviteCanView()
        case .beMoved:
            return canBeMoved()
        case .moveFrom:
            return canMoveFrom()
        case .moveTo:
            return canMoveTo()
        case .singlePageManageMeta:
            return canSinglePageManageMeta()
        case .singlePageManageCollaborator:
            return canSinglePageManageCollaborator()
        case .singlePageInviteFullAccess:
            return canSinglePageInviteFullAccess()
        case .singlePageInviteCanEdit:
            return canSinglePageInviteCanEdit()
        case .singlePageInviteCanView:
            return canSinglePageInviteCanView()
        case .comment:
            return canComment()
        case .copy:
            return canCopy()
        case .manageHistoryRecord:
            return canManageHistoryRecord()
        case .print:
            return canPrint()
        case .export:
            return canExport()
        case .visitSecretLevel:
            return canVisitSecretLevel()
        case .modifySecretLevel:
            return canModifySecretLevel()
        case .preview:
            return canPreview()
        case .perceive:
            return canPreview()
        case .duplicate:
            return canDuplicate()
        case .applyEmbed, .showCollaboratorInfo, .manageVersion:
            return false // FIXME: use unknown default setting to fix warning
        case .shareExternal:
            return canShareExternal()
        case .sharePartnerTenant:
            return canSharePartnerTenant()
        @unknown default:
            return false
        }
    }
    // enable-lint: cyclomatic complexity
}

/// 安全策略管控
@available(*, deprecated, message: "Use UserPermissionServiceChecker instead - PermissionSDK")
public final class SecurityPolicyChecker: HiddenChecker, EnableChecker {
    public enum PermissionType {
        case download
        case openWithOtherApp
        case createCopy
        case export
    }

    private static func check(permissionType: PermissionType, docsType: DocsType, token: String) -> CCMSecurityPolicyService.ValidateResult {
        var operate = EntityOperate.ccmFileDownload
        switch permissionType {
        case .download, .openWithOtherApp:
            operate = EntityOperate.ccmFileDownload
        case .createCopy:
            operate = EntityOperate.ccmCreateCopy
        case .export:
            operate = EntityOperate.ccmExport
        }
        return CCMSecurityPolicyService.syncValidate(entityOperate: operate, fileBizDomain: .ccm, docType: docsType, token: token)
    }

    private static func showInterceptDialog(permissionType: PermissionType, docsType: DocsType, token: String) {
        var operate = EntityOperate.ccmFileDownload
        switch permissionType {
        case .download, .openWithOtherApp:
            operate = EntityOperate.ccmFileDownload
        case .createCopy:
            operate = EntityOperate.ccmCreateCopy
        case .export:
            operate = EntityOperate.ccmExport
        }
        CCMSecurityPolicyService.showInterceptDialog(entityOperate: operate,
                                                     fileBizDomain: .ccm, docType: docsType, token: token)
    }

    public var isHidden: Bool {
        !isEnabled
    }

    public lazy var isEnabled: Bool = {
        let validateResult = Self.check(permissionType: permissionType, docsType: docsType, token: token)
        self.validateResult = validateResult
        return validateResult.allow
    }()

    public var disableReason: String {
        return BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast
    }

    public var ignoreAlert: Bool {
        return validateResult?.allow == false && validateResult?.validateSource == .fileStrategy
    }

    public var customHandler: ((UIViewController?) -> Void)? {
        guard shouldShowInterceptDialog else {
            return nil
        }
        return { [weak self] _ in
            guard let self = self else { return }
            self.showInterceptDialog()
        }
    }

    /// 安全侧弹框,业务方无需弹框
    public var shouldShowInterceptDialog: Bool {
        return validateResult?.allow == false && validateResult?.validateSource == .fileStrategy
    }
    /// 安全侧弹框
    public func showInterceptDialog() {
        Self.showInterceptDialog(permissionType: permissionType, docsType: docsType, token: token)
    }

    private let permissionType: PermissionType
    private let docsType: DocsType
    private let token: String

    private var validateResult: CCMSecurityPolicyService.ValidateResult?

    public init(permissionType: PermissionType, docsType: DocsType, token: String) {
        self.permissionType = permissionType
        self.docsType = docsType
        self.token = token
    }
}

public final class PermissionSDKChecker: HiddenChecker, EnableChecker {
    public var isHidden: Bool
    public var isEnabled: Bool
    public var forceEnableStyle: Bool = false
    public var disableReason: String = BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission
    public var customHandler: ((UIViewController?) -> Bool)?

    private let permissionSDK: PermissionSDK
    private let request: PermissionRequest

    public init(permissionSDK: PermissionSDK,
                request: PermissionRequest) {
        self.permissionSDK = permissionSDK
        self.request = request
        self.isHidden = true
        self.isEnabled = false

        let response = permissionSDK.validate(request: request)
        handle(response: response)
    }

    private func handle(response: PermissionResponse) {
        forceEnableStyle = false
        switch response.result {
        case .allow:
            isHidden = false
            isEnabled = true
            customHandler = { controller in
                guard let controller else { return true }
                response.didTriggerOperation(controller: controller)
                return true
            }
        case let .forbidden(_, style):
            isEnabled = false
            switch style {
            case .default:
                isHidden = false
                // 保持 enable 状态，但是仍不可执行操作
                forceEnableStyle = true
            case .hidden:
                isHidden = true
            /// 置灰相关操作入口
            case .disabled:
                isHidden = false
            }
            customHandler = { [weak self] controller in
                guard let controller else {
                    spaceAssertionFailure("controller found nil when perform permission UI behavior")
                    return false
                }
                response.didTriggerOperation(controller: controller, self?.disableReason)
                return false
            }
        }
    }

    public func custom(reason: String) -> Self {
        disableReason = reason
        return self
    }
}

public final class UserPermissionServiceChecker: HiddenChecker, EnableChecker {
    public var isHidden: Bool

    public var isEnabled: Bool

    public var forceEnableStyle: Bool = false

    public var disableReason: String = BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission

    public var customHandler: ((UIViewController?) -> Bool)?

    private let service: UserPermissionService
    private let operation: PermissionRequest.Operation
    private let bizDomain: PermissionRequest.BizDomain
    private let disposeBag = DisposeBag()

    public init(service: UserPermissionService,
                operation: PermissionRequest.Operation,
                bizDomain: PermissionRequest.BizDomain = .ccm) {
        self.service = service
        self.operation = operation
        self.bizDomain = bizDomain
        self.isHidden = true
        self.isEnabled = false

        service.onPermissionUpdated
            .subscribe(onNext: { [weak self] _ in
                self?.update()
            })
            .disposed(by: disposeBag)
    }

    private func update() {
        let response = service.validate(operation: operation, bizDomain: bizDomain)
        forceEnableStyle = false
        switch response.result {
        case .allow:
            isHidden = false
            isEnabled = true
            customHandler = { controller in
                guard let controller else { return true }
                response.didTriggerOperation(controller: controller)
                return true
            }
        case let .forbidden(_, style):
            isEnabled = false
            switch style {
            case .default:
                isHidden = false
                // 保持 enable 状态，但是仍不可执行操作
                forceEnableStyle = true
            case .hidden:
                isHidden = true
            /// 置灰相关操作入口
            case .disabled:
                isHidden = false
            }
            customHandler = { [weak self] controller in
                guard let controller else {
                    spaceAssertionFailure("controller found nil when perform permission UI behavior")
                    return false
                }
                response.didTriggerOperation(controller: controller, self?.disableReason)
                return false
            }
        }
    }
    public func custom(reason: String) -> Self {
        disableReason = reason
        return self
    }
}

@available(*, deprecated, message: "Use UserPermissionServiceChecker instead - PermissionSDK")
public final class V2FolderPermissionChecker: RxChecker {
    public typealias PermissionType = UserPermissionEnum
    private let disposeBag = DisposeBag()
    public let inputRelay = BehaviorRelay<UserPermissionAbility?>(value: nil)
    public let checkedValue: PermissionType

    public var disableReason: String {
        // 通常使用具体操作无权限的文案
        BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission
    }

    public init(input: Observable<UserPermissionAbility?>, permissionType: PermissionType) {
        checkedValue = permissionType
        input.bind(to: inputRelay).disposed(by: disposeBag)
    }

    public func verify(input: UserPermissionAbility?, checkedValue: PermissionType) -> Bool {
        guard let currentPermission = input else { return false }
        return currentPermission.have(permissionType: checkedValue)
    }
}

@available(*, deprecated, message: "Use UserPermissionServiceChecker instead - PermissionSDK")
public final class UserPermissionTypeChecker: RxChecker {
    public typealias PermissionType = UserPermissionEnum
    private let disposeBag = DisposeBag()
    public let inputRelay = BehaviorRelay<UserPermissionAbility?>(value: nil)
    public let checkedValue: PermissionType

    public var disableReason: String {
        // 通常使用具体操作无权限的文案
        BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission
    }

    public init(input: Observable<UserPermissionAbility?>, permissionType: PermissionType) {
        self.checkedValue = permissionType
        input.bind(to: inputRelay).disposed(by: disposeBag)
    }

    public func verify(input: UserPermissionAbility?, checkedValue: UserPermissionEnum) -> Bool {
        guard let currentPermission = input else { return false }
        return currentPermission.have(permissionType: checkedValue)
    }
}

@available(*, deprecated, message: "Use UserPermissionServiceChecker instead - PermissionSDK")
public final class UserPermissionRoleChecker: RxChecker {
    public typealias RoleType = UserPermissionRoleType
    private let disposeBag = DisposeBag()
    public let inputRelay = BehaviorRelay<UserPermissionAbility?>(value: nil)
    public let checkedValue: RoleType

    public var disableReason: String {
        // 通常使用具体操作无权限的文案
        BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission
    }

    public init(input: Observable<UserPermissionAbility?>, roleType: RoleType) {
        self.checkedValue = roleType
        input.bind(to: inputRelay).disposed(by: disposeBag)
    }

    public func verify(input: UserPermissionAbility?, checkedValue: RoleType) -> Bool {
        guard let currentPermission = input else { return false }
        return currentPermission.permRoleType == checkedValue
    }
}
