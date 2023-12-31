//
//  BaseContext.swift
//  SKBitable
//
//  Created by yinyuan on 2023/8/2.
//

import Foundation
import SKCommon
import SpaceInterface
import SKFoundation
import RxSwift

/// 所有的非 Base 自身的上下文信息，都通过 service 提供。
/// BaseContext 可能会运行在 HomePage 环境下，我们只需要通过 service 就能注入依赖的能力
public protocol BaseContextService: AnyObject {
    var model: BrowserModelConfig? { get }
}

/**
  从 base@docx 之后，一个文档可以同时出现多个 Base，这里用于承载一些广泛场景被感知的 Base 上下文，用于实现多 Base 的隔离。
  注意1：BaseContext 会被广泛持有，因此 BaseContext 内部新增的属性都需要严格检查，注意不可强引用持有大对象。
  注意2：BaseContext 是 base 级别的上下文，不可携带 table/view 级别的信息。
 */
public class BaseContextImpl: BaseContext {
    
    private let disposeBag = DisposeBag()
    
    /// 请使用 baseToken 属性
    private let _baseToken: String
    
    /// 所有的非 Base 自身的上下文信息，都通过 service 提供。
    /// BaseContext 可能会运行在 HomePage 环境下，我们只需要通过 service 就能注入依赖的能力
    /// 注意：这个属性不要直接对外暴露
    private weak var service: BaseContextService?
    
    /// 请使用 permissionObj 属性
    /// 注意：base@docx 中，inline base 使用的是宿主的信息，而关联base使用的是自己的信息，因此 permissionObj.objToken 不一定等于 baseToken
    private let _permissionObj: BasePermissionObj?
    
    /// 记录来源，用于日志。不要用于业务逻辑判断。
    /// from 为什么不用枚举：后续还要接收从前端传过来的动态 from，不适合枚举
    private let from: String
    
    public init(baseToken: String, service: BaseContextService?, permissionObj: BasePermissionObj?, from: String) {
        self._baseToken = baseToken
        self.service = service
        self.from = from
        if UserScopeNoChangeFG.YY.bitableReferPermission {
            self._permissionObj = permissionObj
            DocsLogger.info("BaseContext init \(self.description)")
        } else {
            self._permissionObj = nil
        }
    }
}

extension BaseContextImpl: CustomStringConvertible {
    public var description: String {
        "BaseContext:{from:\(from),baseToken:\(_baseToken.encryptToShort),hostToken:\(hostDocsInfo?.token.encryptToShort ?? "nil"),permissionObj:\(_permissionObj?.description ?? "nil")}"
    }
}

extension BaseContextImpl {
    
    /// 注意：在某些场景下，可能为空，表示前端没有明确是哪个 base，也不需要适配多 base（例如部分 showPanle 调用无法获得 bitable 上下文因此没有传入这个参数）。
    /// 因此在使用这个属性之前，你需要自己确保你的上下文 BaseContext.init 时指定了有效的不为空的 baseToken。
    public var baseToken: String {
        get {
            if _baseToken.isEmpty, let token = service?.model?.hostBrowserInfo.docsInfo?.token, service?.model?.hostBrowserInfo.docsInfo?.inherentType == .bitable {
                return token  // 独立 Bitable 场景下，如果出现 baseToken 传 nil, 则降级为从 docsInfo 中读取
            } else {
                return _baseToken
            }
        }
    }
    
    /// 宿主文档信息（这里 base@docx 情况下，这里指的是 docx 的信息，独立 base 情况下这里指的是 base 文档的信息）
    public var hostDocsInfo: DocsInfo? {
        service?.model?.hostBrowserInfo.docsInfo
    }
}

extension BaseContextImpl {
    /// 是否是 Base 外记录详情场景
    public var isIndRecord: Bool {
        guard let url = service?.model?.hostBrowserInfo.currentURL else {
            return false
        }
        return DocsUrlUtil.isBaseRecordUrl(url)
    }
    
    /// 是否是 Base 外记录新建场景
    public var isAddRecord: Bool {
        guard let url = service?.model?.hostBrowserInfo.currentURL else {
            return false
        }
        return DocsUrlUtil.isBaseAddUrl(url)
    }
}


/// 权限通用
extension BaseContextImpl {
    /// 宿主权限配置（这里 base@docx 情况下，这里指的是 docx 的信息，独立 base 情况下这里指的是 base 文档的信息）
    private var browserPermissionConfig: BrowserPermissionConfig? {
        service?.model?.permissionConfig
    }
    
    /// 经过计算后的最终的 permissionObj
    /// 规则1: 如果指定了明确的 _permissionObj，则返回 _permissionObj
    /// 规则2: 如果没有指定明确的 _permissionObj，则返回宿主的 hostDocsInfo token 和 inherentType（base@docx 情况下是 docx 的）
    /// 兜底：一般不会发生这种情况，兜底到 base 避免越权
    public var permissionObj: BasePermissionObj {
        if let permissionObj = _permissionObj {
            return permissionObj    // 优先使用外部指定的明确的 permissionObj
        } else if let hostDocsInfo = hostDocsInfo {
            return BasePermissionObj(objToken: hostDocsInfo.token, objType: hostDocsInfo.inherentType)
        }
        return BasePermissionObj(objToken: baseToken, objType: .bitable)
    }
    
    /// 经过计算后的最终的权限 BrowserDocumentType
    /// 规则1：如果指定了明确的 _permissionObj，就返回 referenceDocument
    /// 规则2：这里如果发现 permissionObj 就是宿主，那么就直接返回 hostDocument
    /// 规则3：其他情况返回 hostDocument
    public var permissionDocumentType: BrowserDocumentType {
        if let permissionObj = _permissionObj {
            if permissionObj.objToken == hostDocsInfo?.token {
                return .hostDocument
            }
            return .referenceDocument(objToken: permissionObj.objToken)
        }
        return .hostDocument
    }
}

/// 复制权限
extension BaseContextImpl {
    
    /// 用于检查复制/剪切权限
    /// 注意：在开启单文档保护的情况下，这里返回的是 true，也就是单文档允许复制（限制粘贴范围仅在相同文档内）
    /// 参考文档 https://bytedance.feishu.cn/docx/ISiDdBTSSowbNixnvaGcGzBQnqg
    public var copyOrCutAvailability: BTCopyPermission {
        get {
            let permissionObj = self.permissionObj
            DocsLogger.error("[BasePermission] checkCopyOrCutAvailability permissionObj:\(permissionObj.objToken.encryptToShort):\(permissionObj.objType.rawValue)")
            if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                return checkCopyPermission()
            } else {
                return legacyCheckCopyPermission(permissionObj: permissionObj)
            }
        }
    }

    private func checkCopyPermission() -> BTCopyPermission {
        guard let service = permissionService else {
            return .refuseByUser
        }
        let response = service.validate(operation: .copyContent)
        guard case let .forbidden(denyType, _) = response.result,
              case let .blockByUserPermission(reason) = denyType else {
            return .fromPermissionSDK(response: response)
        }
        switch reason {
        case .blockByServer, .unknown, .userPermissionNotReady, .blockByAudit:
            if let encryptId = ClipboardManager.shared.getEncryptId(token: permissionObj.objToken), !encryptId.isEmpty {
                return .allowBySingleDocumentProtect
            }
            return .fromPermissionSDK(response: response)
        case .blockByCAC, .cacheNotSupport:
            return .fromPermissionSDK(response: response)
        }
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func legacyCheckCopyPermission(permissionObj: BasePermissionObj) -> BTCopyPermission {
        let validation = CCMSecurityPolicyService.syncValidate(
            entityOperate: .ccmCopy,
            fileBizDomain: .ccm,
            docType: permissionObj.objType,
            token: permissionObj.objToken
        )
        guard validation.allow else {
            switch validation.validateSource {
            case .fileStrategy:
                DocsLogger.info("[BasePermission] checkCopyOrCutAvailability: fileStrategy")
                return .refuseByFileStrategy
            case .securityAudit:
                DocsLogger.info("[BasePermission] checkCopyOrCutAvailability: securityAudit")
                return .refuseBySecurityAudit
            case .dlpDetecting:
                DocsLogger.info("[BasePermission] checkCopyOrCutAvailability: dlpDetecting")
                return .allow
            case .dlpSensitive:
                DocsLogger.info("[BasePermission] checkCopyOrCutAvailability: dlpSensitive")
                return .allow
            case .unknown:
                DocsLogger.info("[BasePermission] checkCopyOrCutAvailability: unknown")
                return .allow
            @unknown default:
                DocsLogger.info("[BasePermission] checkCopyOrCutAvailability: default unknown")
                return .allow
            }
        }
        if browserPermissionConfig?.checkCanCopy(for: permissionDocumentType) ?? false {
            DocsLogger.info("[BasePermission] checkCopyOrCutAvailability: allow")
            return .allow
        } else if !AdminPermissionManager.adminCanCopy(docType: permissionObj.objType, token: permissionObj.objToken) {
            DocsLogger.info("[BasePermission] checkCopyOrCutAvailability: refuseByAdmin")
            return .refuseByAdmin
        } else if let status = DlpManager.status(with: permissionObj.objToken, type: permissionObj.objType, action: .COPY) as? DlpCheckStatus, status != DlpCheckStatus.Safe {
            DocsLogger.info("[BasePermission] checkCopyOrCutAvailability: refuseByDlp(\(status.rawValue)")
            return .refuseByDlp(status)
        } else if let encryptId = ClipboardManager.shared.getEncryptId(token: permissionObj.objToken), !encryptId.isEmpty {
            DocsLogger.info("[BasePermission] checkCopyOrCutAvailability: allowBySingleDocumentProtect")
            return .allowBySingleDocumentProtect
        } else {
            DocsLogger.info("[BasePermission] checkCopyOrCutAvailability: refuseByUser (else)")
            return .refuseByUser
        }
    }
    
    /// 用于检查复制/剪切权限（自带 toast 提示）
    public func checkCopyOrCutAvailabilityWithToast(view: UIView) -> Bool {
        let copyOrCutAvailability = self.copyOrCutAvailability
        switch copyOrCutAvailability {
        case .allow, .allowBySingleDocumentProtect:
            return true
        default: break
        }
        showToastWhenCopyProhibited(copyPermisson: copyOrCutAvailability, on: view)
        // 来自 permissionSDK 的 response 都需要先 showToastIfNeed 再 return allow
        if case let .fromPermissionSDK(response) = copyOrCutAvailability {
            return response.allow
        }
        return false
    }
    
    /// 监听权限变化
    public var permissionEventNotifier: DocsPermissionEventNotifier? {
        get {
            browserPermissionConfig?.getPermissionEventNotifier(for: permissionDocumentType)
        }
    }

    public var permissionService: UserPermissionService? {
        if shouldCreatePermissionServiceOnDemand() {
            // 走新逻辑，目前(7.7版本)这个方法在获取不到是会主动创建 service
            return browserPermissionConfig?.getPermissionService(
                for: permissionObj.objType,
                objToken: permissionObj.objToken
            )
        }
        // 走线上旧逻辑，目前(7.7版本)这个方法在 referDoc 时，获取不到不会创建 service
        return browserPermissionConfig?.getPermissionService(for: permissionDocumentType)
    }

    public var hostPermissionService: UserPermissionService? {
        browserPermissionConfig?.getPermissionService(for: .hostDocument)
    }
    
    /// 权限信息默认是前端拉取后，更新到端上；部分场景（记录分享、记录新建）需要端上手动更新
    public func manualUpdatePermissionData() {
        if UserScopeNoChangeFG.ZYS.recordCopySupportRevert {
            return
        }
        DocsLogger.info("[BasePermission] manualUpdatePermissionData start")
        permissionService?.updateUserPermission()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] _ in
                    DocsLogger.info("[BasePermission] manualUpdatePermissionData success")
                    self?.onManualUpdatePermissionSuccess()
                }, onError: { error in
                    DocsLogger.error("[BasePermission] manualUpdatePermissionData failed", error: error)
                })
            .disposed(
                by: disposeBag
            )
    }
    
    /// 这个方法不应该开放给外部，但是目前时序问题需要在 onUpdated 里面调用，先 public 出去
    public func notifyPermissionSDKToSyncPermission() {
        service?.model?.permissionConfig.notifyDidUpdate(permisisonResponse: nil, for: permissionDocumentType, objType: permissionObj.objType)
    }
    
    private func onManualUpdatePermissionSuccess() {
        guard getIfSingleDocProtectEncryptIdNeedUpdateByClient() else {
            return
        }
        // 需要调用这个方法，把权限更新到 permissionManager 中，否则读取权限时可能不生效
        notifyPermissionSDKToSyncPermission()
        
        let token = permissionObj.objToken
        if getIsSingleFileCopyProtect() {
            // 命中单文档保护
            ClipboardManager.shared.updateEncryptId(token: token, encryptId: token)
        } else {
            ClipboardManager.shared.updateEncryptId(token: token, encryptId: nil)
        }
    }
    
    private func shouldCreatePermissionServiceOnDemand() -> Bool {
        if UserScopeNoChangeFG.ZYS.recordCopySupportRevert {
            return false
        }
        return getIfSingleDocProtectEncryptIdNeedUpdateByClient()
    }
    
    /// 是否需要在端上设置单文档保护 EncryptId
    private func getIfSingleDocProtectEncryptIdNeedUpdateByClient() -> Bool {
        if UserScopeNoChangeFG.ZYS.recordCopySupportRevert {
            return false
        }
        return isAddRecord || isIndRecord
    }
    
    /// 是否命中单文档保护
    private func getIsSingleFileCopyProtect() -> Bool {
        guard let service = permissionService else {
            return false
        }
        let response = service.validate(operation: .copyContent)
        guard case let .forbidden(denyType, _) = response.result,
              case let .blockByUserPermission(reason) = denyType else {
            return false
        }
        switch reason {
        case .blockByServer, .unknown, .userPermissionNotReady:
            // 有编辑权限但是无法复制
            return service.validate(operation: .edit).allow
        case .blockByCAC, .cacheNotSupport:
            return false
        @unknown default:
            spaceAssertionFailure("unknown reason, check!")
            return false
        }
    }
    
    private func showToastWhenCopyProhibited(copyPermisson: BTCopyPermission?, on targetView: UIView) {
        guard let hostDocsInfo = hostDocsInfo else {
            return
        }
        let permissionObj = permissionObj
        let isSameTenant = hostDocsInfo.isSameTenantWithOwner(for: permissionObj.objToken)
        BTUtil.showToastWhenCopyProhibited(copyPermisson: copyPermisson, isSameTenant: isSameTenant, on: targetView, token: permissionObj.objToken)
    }
}

/// 截屏权限
/// 解释截屏权限跟复制权限的关系：截屏权限就是复制权限的一种表现方式，只是在单文档保护的情况下有一些差异
/// https://bytedance.feishu.cn/wiki/wikcnFhPKZzrkAi8DcXZKJsWNDc#AHoXNv
extension BaseContextImpl {
    
    /// 用于检查截屏权限（这里只能获得静态值，建议使用 BasePermissionHelper 进行动态监听）
    /// 注意：在开启单文档保护的情况下，这里返回的是 false，也就是单文档不允许截屏
    public var hasCapturePermission: Bool {
        get {
            return browserPermissionConfig?.checkCanCopy(for: permissionDocumentType) ?? false
        }
    }
}

// 水印
extension BaseContextImpl {
    
    /// 是否应当显示水印（这里只能获得静态值，建议使用 BasePermissionHelper 进行动态监听）
    public var shouldShowWatermark: Bool {
        get {
            if case let .referenceDocument(objToken) = permissionDocumentType, let docsInfo = hostDocsInfo {
                return docsInfo.shouldShowWatermark(watermarkKey: .init(objToken: objToken, type: DocsType.bitable.rawValue))
            }
            return hostDocsInfo?.shouldShowWatermark ?? true
        }
    }
    
}
