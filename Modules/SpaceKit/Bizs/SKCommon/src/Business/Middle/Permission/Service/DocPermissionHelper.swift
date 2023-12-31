import Foundation
import SpaceInterface
import SKInfra
import SKFoundation
import LarkSecurityAudit
import LarkSecurityComplianceInterface
import LarkSecurityCompliance
import UniverseDesignToast

public typealias PermissionChangedBlock = (DocPermissionInfo) -> Void
protocol DocPermissionHelperProtocol: AnyObject {
    func startMonitorPermission(startFetch: @escaping() -> Void,
                                permissionChanged: @escaping PermissionChangedBlock,
                                failed: @escaping (PermissionResponseModel) -> Void)
    func unRegister()
}

public struct DocPermissionInfo {
    let isReadable: Bool
    let isEditable: Bool
    let canComment: Bool
    let canExport: Bool
    let canCopy: Bool
    let permissionStatusCode: PermissionStatusCode?
    public let userPermissions: UserPermissionAbility?

    static var noPermissionInfo: DocPermissionInfo {
        return DocPermissionInfo(isReadable: false,
                                   isEditable: false,
                                   canComment: false,
                                   canExport: false,
                                   canCopy: false,
                                   permissionStatusCode: nil,
                                 userPermissions: nil)
    }
}

public final class DocPermissionHelper: DocPermissionHelperProtocol {

    let fileToken: String
    let type: DocsType

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
    /// 公共权限
    private var publicPermissionMeta: PublicPermissionMeta?
    /// 审核结果
    private(set) var permissionStatusCode: PermissionStatusCode?

    public init(fileToken: String, type: DocsType) {
        self.fileToken = fileToken
        self.type = type
        setupNetworkMonitor()
    }
    deinit {
        DocsLogger.info("DocPermissionHelper deInit, file: \(DocsTracker.encrypt(id: fileToken))")
    }

    /// 监测网络连接变化
    private func setupNetworkMonitor() {
        DocsNetStateMonitor.shared.addObserver(self) { [weak self] (networkType, isReachable) in
            DocsLogger.debug("Current networkType is \(networkType)")
            self?.isReachable = isReachable
        }
    }
    private func currentPermissionInfo() -> DocPermissionInfo {
        return DocPermissionInfo(isReadable: isReadable,
                                   isEditable: isEditable,
                                   canComment: canComment,
                                   canExport: canExport,
                                   canCopy: canExport,
                                   permissionStatusCode: permissionStatusCode,
                                 userPermissions: userPermissions)
    }
    
    private func fetchAllPermission() {
        self.startFetchBlock?()
        permissionObserver?.fetchAllPermission {[weak self] (response) -> Void in
            guard let self = self else { return }
            self.handlePermission(response)
        }
    }

    private func handlePermission(_ response: PermissionResponseModel) {
        self.userPermissions = response.userPermissions
        self.publicPermissionMeta = response.publicPermissionMeta
        self.permissionStatusCode = response.permissionStatusCode
        self.permissionChangedBlock?(self.currentPermissionInfo())
    }

    public func startMonitorPermission(startFetch: @escaping() -> Void,
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
        DocsLogger.info("DocPermissionHelper startMonitorPermission, file: \(DocsTracker.encrypt(id: fileToken))")
    }
    
    public func unRegister() {
        DocsLogger.info("DocPermissionHelper unRegister, file: \(DocsTracker.encrypt(id: fileToken))")
        permissionObserver?.unRegister()
        permissionObserver = nil
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    public class func checkPermission(_ entityOperate: EntityOperate,
                                      docType: DocsType,
                                      token: String,
                                      fileBizDomain: CCMSecurityPolicyService.BizDomain = .ccm,
                                      showTips: Bool = false,
                                      securityAuditTips: String? = nil,
                                      hostView: UIView? = nil) -> Bool {
        let result = CCMSecurityPolicyService.syncValidate(entityOperate: entityOperate,
                                                           fileBizDomain: fileBizDomain,
                                                           docType: docType,
                                                           token: token)
        if !showTips {
            return result.allow
        }
        if !result.allow {
            switch result.validateSource {
            case .fileStrategy:
                CCMSecurityPolicyService.showInterceptDialog(entityOperate: entityOperate,
                                                             fileBizDomain: .ccm,
                                                             docType: docType,
                                                             token: token)
            case .securityAudit:
                if let securityAuditTips = securityAuditTips, let showView = hostView {
                    UDToast.showFailure(with: securityAuditTips, on: showView)
                }
            case .dlpDetecting, .dlpSensitive, .unknown, .ttBlock:
                DocsLogger.info("unknown type or dlp type")
            }
            return false
        }
        return true
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    public class func checkPermission(_ entityOperate: EntityOperate,
                                      docsInfo: DocsInfo,
                                      fileBizDomain: CCMSecurityPolicyService.BizDomain = .ccm,
                                      showTips: Bool = false,
                                      securityAuditTips: String? = nil,
                                      hostView: UIView? = nil) -> Bool {
        checkPermission(entityOperate,
                        docType: docsInfo.inherentType,
                        token: docsInfo.token,
                        showTips: showTips,
                        securityAuditTips: securityAuditTips,
                        hostView: hostView)
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    public class func checkPermission(_ entityOperate: EntityOperate,
                                      meta: SpaceMeta,
                                      fileBizDomain: CCMSecurityPolicyService.BizDomain = .ccm,
                                      showTips: Bool = false,
                                      securityAuditTips: String? = nil,
                                      hostView: UIView? = nil) -> Bool {
        checkPermission(entityOperate,
                        docType: meta.objType,
                        token: meta.objToken,
                        showTips: showTips,
                        securityAuditTips: securityAuditTips,
                        hostView: hostView)
    }

    public class func validate(objToken: String, objType: DocsType, operation: PermissionRequest.Operation, tenantID: String? = nil) -> PermissionResponse {
        let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
        let request = PermissionRequest(token: objToken, type: objType, operation: operation, bizDomain: .ccm, tenantID: tenantID)
        return permissionSDK.validate(request: request)
    }

    public class func validateForDownloadImageAttachmentV2(objToken: String, objType: DocsType, tenantID: String? = nil) -> PermissionResponse {
        let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
        let request = PermissionRequest(entity: .ccm(token: "", type: .file,
                                                     parentMeta: SpaceMeta(objToken: objToken,
                                                                           objType: objType)),
                                        operation: .downloadAttachment,
                                        bizDomain: .ccm)
        return permissionSDK.validate(request: request)
    }
}

extension DocPermissionHelper: PermissionObserverDelegate {
    public func didReceivePermissionData(response: PermissionResponseModel) {
        DocsLogger.info("did receive permission changed, file: \(DocsTracker.encrypt(id: fileToken))")
        handlePermission(response)
    }
}

extension DocPermissionHelper {
    var isReadable: Bool { return self.userPermissions?.canView() ?? false }

    var isEditable: Bool { return self.userPermissions?.canEdit() ?? false }

    var canComment: Bool { return self.userPermissions?.canComment() ?? false }

    var canExport: Bool { return self.userPermissions?.canExport() ?? false }
}
