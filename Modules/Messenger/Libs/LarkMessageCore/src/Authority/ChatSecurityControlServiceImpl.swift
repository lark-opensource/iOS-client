//
//  ChatSecurityControlServiceImpl.swift
//  LarkMessageCore
//
//  Created by 王元洵 on 2020/12/25.
//

import UIKit
import Foundation
import LarkAlertController
import EENavigator
import LarkMessengerInterface
import UniverseDesignToast
import LKCommonsLogging
import UniverseDesignDialog
import LarkModel
import LarkAccountInterface
import LarkSecurityComplianceInterface
import LarkContainer
import LarkUIKit
import ThreadSafeDataStructure
import LarkSetting

public final class ChatSecurityControlServiceImpl: NSObject, ChatSecurityControlService, UserResolverWrapper {
    public let userResolver: UserResolver

    private static let logger = Logger.log(ChatSecurityControlServiceImpl.self, category: "Module.chat.Security")
    private lazy var enablePreviewPermissionAuth: Bool = {
        return featureService?.staticFeatureGatingValue(with: "messenger.permission.preview") ?? false
    }()
    private let currentUserID: Int64
    private let currentTenantID: Int64
    private var asyncRequestList: SafeSet<DynamicAuthorityParams> = SafeSet<DynamicAuthorityParams>([], synchronization: .semaphore)
    private enum AlertType {
        case toast
        case window
    }
    public var messageHadAsync: SafeLRUDictionary<String, Bool>

    private var securityPolicyService: SecurityPolicyService?
    private var featureService: FeatureGatingService?

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.currentUserID = Int64(userResolver.userID) ?? 0
        self.currentTenantID = Int64((try? userResolver.resolve(assert: PassportUserService.self).userTenant.tenantID) ?? "") ?? 0
        self.securityPolicyService = try? userResolver.resolve(assert: SecurityPolicyService.self)
        self.featureService = try? userResolver.resolve(assert: FeatureGatingService.self)
        var cacheNum: Int = 10_000
        // 和安全缓存个数相同，目前配置1w条
        if let config: [String: Any] = try? self.userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "lark_security_compliance_config")),
           let maxCacheSize = config["dynamic_pointkey_max_cache_size"] as? [String: Any],
           let readCacheNum = maxCacheSize["PointKey_IM_MSG_FILE_READ"] as? Int {
            cacheNum = readCacheNum
        }
        messageHadAsync = SafeLRUDictionary<String, Bool>(capacity: cacheNum)
        ChatSecurityControlServiceImpl.logger.info("chatSecurity userid:\(currentUserID) \(self.currentUserID), tenantid: \(currentTenantID) \(self.currentTenantID)")
    }

    public static func getNoPermissionSummaryText(permissionPreview: Bool,
                                           dynamicAuthorityEnum: DynamicAuthorityEnum,
                                           sourceType: SecurityControlResourceType) -> String {
        switch dynamicAuthorityEnum {
        case .deny:
            return BundleI18n.LarkMessageCore.Lark_IM_NoReceivingPermission_Text
        case .loading:
            if sourceType == .file {
                //PM觉得文件消息loading态展示空文案有点怪，所以文件消息loading态要加上文案
                return BundleI18n.LarkMessageCore.Lark_IM_UnableToView_Empty
            } else {
                return "" //PM觉得图片/视频消息loading文案跳转到其他文案太突兀了，所以决定直接把loading文案改成空
            }
        case .allow:
            break
        }

        if !permissionPreview {
            switch sourceType {
            case .file:
                return BundleI18n.LarkMessageCore.Lark_IM_UnableToPreview_Button
            case .image:
                return BundleI18n.LarkMessageCore.Lark_IM_UnableToPreviewImage_Text
            case .video:
                return BundleI18n.LarkMessageCore.Lark_IM_UnableToPreviewVideo_Text
            }
        }
        assertionFailure("all permission allowed, should not getNoPermissionSummaryText")
        return ""
    }

    //anonymousId、message：判断消息是不是自己发的，如果是自己发的则不受权限管控。
    public func checkPermissionPreview(anonymousId: String, message: Message?) -> (Bool, ValidateResult?) {
        guard enablePreviewPermissionAuth else {
            ChatSecurityControlServiceImpl.logger.info("preview permission: FG = false, message_id: \(message?.id ?? "")")
            return (true, nil)
        }
        return self.checkPermissionFor(anonymousId: anonymousId,
                                       message: message,
                                       securityControlEvent: .localFilePreview,
                                       ignoreSecurityOperate: true)
    }

    public func checkPermissionFileCopy(anonymousId: String, message: Message?, ignoreSecurityOperate: Bool) -> (Bool, ValidateResult?) {
        return self.checkPermissionFor(anonymousId: anonymousId,
                                       message: message,
                                       securityControlEvent: .fileCopy,
                                       ignoreSecurityOperate: ignoreSecurityOperate)
    }

    private func checkPermissionFor(anonymousId: String,
                                    message: Message?,
                                    securityControlEvent: SecurityControlEvent,
                                    ignoreSecurityOperate: Bool) -> (Bool, ValidateResult?) {
        func checkAuth() -> (Bool, ValidateResult?) {
            let authority = self.checkAuthority(event: securityControlEvent, ignoreSecurityOperate: ignoreSecurityOperate)
            //ignoreSecurityOperate: 无视安全侧内部的弹窗。
            //现在预览权限的弹窗时机有些难以梳理（有些场景不期望在鉴权时直接弹窗，而是会把鉴权结果存下来，在另外的时机弹窗）
            //因此这里ignoreSecurityOperate一律传true，在需要弹窗的位置调用authorityErrorHandler(forceToAlert: true)来弹窗
            //authorityErrorHandler(forceToAlert: true)内部可能会调用安全sdk提供的弹窗接口。
            return (authority.authorityAllowed, authority)
        }

        let meId = self.userResolver.userID
        guard let message = message else { return checkAuth() }
        if !message.originalSenderID.isEmpty {
            if message.originalSenderID == meId {
                ChatSecurityControlServiceImpl.logger.info("preview permission: originalSenderID = meId, message_id: \(message.id)")
                return (true, nil)
            }
            if !anonymousId.isEmpty, anonymousId == message.originalSenderID {
                ChatSecurityControlServiceImpl.logger.info("preview permission: anonymousId = originalSenderID, message_id: \(message.id)")
                return (true, nil)
            }
            return checkAuth()
        }
        if message.fromId == meId {
            ChatSecurityControlServiceImpl.logger.info("preview permission: fromId = me, message_id: \(message.id)")
            return (true, nil)
        }
        if !anonymousId.isEmpty, anonymousId == message.fromId {
            ChatSecurityControlServiceImpl.logger.info("preview permission: anonymousId = fromId, message_id: \(message.id)")
            return (true, nil)
        }
        return checkAuth()
    }

    // 判断预览权限和接收权限
    public func checkPreviewAndReceiveAuthority(chat: Chat?, message: Message) -> PermissionDisplayState {
        guard chat?.isCrypto != true else { return .allow }
        // 判断接收权限
        let receiveResult = getDynamicAuthorityFromCache(event: .receive, message: message, anonymousId: chat?.anonymousId)
        switch receiveResult {
        case .deny:
            return .receiveDeny
        case .loading:
            return .receiveLoading
        case .allow:
            ChatSecurityControlServiceImpl.logger.info("check receive authority: \(message.id) \(receiveResult)")
            break
        }

        // 判断预览权限
        let anonymousId = chat?.anonymousId ?? ""
        if !checkPermissionPreview(anonymousId: anonymousId, message: message).0 {
            return .previewDeny
        }
        return .allow
    }

    // 安全同步接口，用于静态点位。目前「预览点位」、「视频保存到云盘」使用
    public func checkAuthority(event: SecurityControlEvent, ignoreSecurityOperate: Bool) -> ValidateResult {
        guard let securityPolicyService = self.securityPolicyService, let policyModel = event.generatePolicyModel(operatorTenantId: self.currentTenantID,
                                                          operatorUid: self.currentUserID) else {
            return .init(userResolver: userResolver, result: .unknown, extra: .init(resultSource: .fileStrategy, errorReason: nil))
        }
        let config = ValidateConfig(ignoreSecurityOperate: ignoreSecurityOperate, ignoreCache: false)
        return securityPolicyService.cacheValidate(policyModel: policyModel, authEntity: event.generateAuthEntity(), config: config)
    }

    // 安全异步接口，用于静态点位。目前只有「下载点位」使用
    public func downloadAsyncCheckAuthority(event: SecurityControlEvent,
                                            securityExtraInfo: SecurityExtraInfo?,
                                            ignoreSecurityOperate: Bool?,
                                            completion: @escaping (ValidateResult) -> Void) {
        guard let policyModel = event.generatePolicyModel(operatorTenantId: self.currentTenantID,
                                                          operatorUid: self.currentUserID,
                                                          securityExtraInfo: securityExtraInfo) else {
            Self.logger.info("policy model get failed \(event)")
            return
        }
        Self.logger.info("start check async authority \(policyModel.taskID)")
        var config = ValidateConfig()
        if let ignoreSecurityOperate = ignoreSecurityOperate {
            config.ignoreSecurityOperate = ignoreSecurityOperate
        }
        securityPolicyService?.asyncValidate(policyModel: policyModel, authEntity: event.generateAuthEntity(), config: config, complete: { arg in
            Self.logger.info("end check async authority \(arg)")
            completion(arg)
        })
    }

    // 安全异步接口，用于动态点位，先用缓存，没缓存发起鉴权
    public func checkDynamicAuthority(params: DynamicAuthorityParams) {
        guard let securityPolicyService = self.securityPolicyService, let policyModel = params.getPolicyModel(operatorTenantId: self.currentTenantID,
                                                      operatorUid: self.currentUserID) else {
            Self.logger.info("policy model get failed \(params)")
            return
        }
        let result = securityPolicyService.cacheValidate(policyModel: policyModel, authEntity: nil, config: .init(ignoreSecurityOperate: true))
        let securityDynamicResult = SecurityDynamicResult(validateResult: result, isFromAsync: false, isHadAsync: self.messageHadAsync[params.messageID] ?? false)
        params.onComplete(securityDynamicResult)
        if securityDynamicResult.isDowngradeResult {
            asyncRequestList.insert(params)

            DispatchQueue.main.async {
                //debounce 0.1秒后请求
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.asyncRequestDynamicAuthority), object: nil)
                self.perform(#selector(self.asyncRequestDynamicAuthority), with: nil, afterDelay: 0.1)
            }
        }
        Self.logger.info("checkDynamicAuthority", additionalData: ["messageID": params.messageID,
                                                                   "taskID": policyModel.taskID,
                                                                   "isDowngradeResult": securityDynamicResult.isDowngradeResult.description,
                                                                   "dynamicAuthorityEnum": securityDynamicResult.dynamicAuthorityEnum.rawValue])
    }

    // 安全同步接口，用于动态点位，根据message_id等信息取安全侧的缓存
    public func getDynamicAuthorityFromCache(event: SecurityControlEvent, message: Message, anonymousId: String?) -> DynamicAuthorityEnum {
        guard let senderUserId = Int64(message.fromId),
              let senderTenantId = Int64(message.fromChatter?.tenantId ?? "") else {
            Self.logger.error("getDynamicAuthorityFromCache trans ID fail", additionalData: ["messageID": message.id,
                                                                                             "channelID": message.channel.id,
                                                                                             "channelType": message.channel.type.rawValue.description,
                                                                                             "fromID": message.fromId,
                                                                                             "fromChatterIsNil": message.fromChatter == nil ? "true" : "false",
                                                                                             "fromTenantID": message.fromChatter?.tenantId ?? ""])
            return .allow
        }
        guard getIfMessageNeedDynamicAuthority(message, anonymousId: anonymousId),
            let policyModel = event.generatePolicyModel(operatorTenantId: self.currentTenantID,
                                                        operatorUid: self.currentUserID,
                                                        securityExtraInfo: SecurityExtraInfo(
                                                            senderUserId: senderUserId, senderTenantId: senderTenantId, msgId: message.id)) else {
            Self.logger.info("getDynamicAuthorityFromCache not need dynamic")
            return .allow
        }
        if let result = self.securityPolicyService?.cacheValidate(policyModel: policyModel, authEntity: nil, config: .init(ignoreSecurityOperate: true)) {
            return SecurityDynamicResult(validateResult: result, isFromAsync: false, isHadAsync: self.messageHadAsync[message.id] ?? false).dynamicAuthorityEnum
        }
        return .allow
    }

    // 是否需要「接收点位」的鉴权
    public func getIfMessageNeedDynamicAuthority(_ message: Message, anonymousId: String?) -> Bool {
        Self.logger.info("need check dynamic \(message.fromId) \(message.type)")
        guard self.featureService?.staticFeatureGatingValue(with: "messenger.permission.share") ?? false else { return false}
        if message.fromId == anonymousId || Int64(message.fromId) == currentUserID { return false }
        switch message.type {
        case.file, .image, .media, .folder:
            Self.logger.info("need check dynamic result true")
            return true
        case .post:
            guard let content = message.content as? PostContent else { return false }
            for element in content.richText.elements.values {
                if element.tag == .media || element.tag == .img {
                    Self.logger.info("need check dynamic result true")
                    return true
                }
            }
            return false
        default:
            return false
        }
    }

    // 安全批量异步接口，用于动态点位。发起异步请求 批量鉴权动态点位
    @objc
    private func asyncRequestDynamicAuthority() {
        let tempRequestList = Array(asyncRequestList.getImmutableCopy())
        asyncRequestList.removeAll()

        let policyModels = tempRequestList.compactMap {
            return $0.getPolicyModel(operatorTenantId: currentTenantID,
                                     operatorUid: currentUserID)
        }
        Self.logger.info("start check async Validate")
        securityPolicyService?.asyncValidate(policyModels: policyModels, config: .init(ignoreSecurityOperate: true, ignoreCache: true)) { [weak self] resultMap in
            Self.logger.info("end check async Validate \(resultMap)")
            guard let self = self else { return }
            for request in tempRequestList {
                let taskID = request.getTaskId(operatorTenantId: self.currentTenantID, operatorUid: self.currentUserID)
                if let result = resultMap[taskID] {
                    self.messageHadAsync[request.messageID] = true
                    request.onComplete(SecurityDynamicResult(validateResult: result, isFromAsync: true, isHadAsync: true))
                    Self.logger.info("asyncRequestDynamicAuthority", additionalData: ["taskID": taskID,
                                                                                      "messageID": request.messageID,
                                                                                      "result": result.result.rawValue.description,
                                                                                      "resultMethod": result.extra.resultMethod?.rawValue ?? "nil"])
                } else {
                    Self.logger.error("asyncValidate result not found", additionalData: ["taskID": taskID,
                                                                                         "currentTenantID": "\(self.currentTenantID)",
                                                                                         "currentUserID": "\(self.currentUserID)",
                                                                                         "event": request.event.rawValue,
                                                                                         "messageID": request.messageID])
                }
            }
        }
    }

    private func getActionText(event: SecurityControlEvent) -> String {
        switch event {
        case .openInAnotherApp:
            return BundleI18n.LarkMessageCore.Lark_Audit_BlockedActionOpenInAnotherApp
        case .saveFile:
            return BundleI18n.LarkMessageCore.Lark_Audit_BlockedActionDownloadFile
        case .saveImage:
            return BundleI18n.LarkMessageCore.Lark_Audit_BlockedActionDownloadFullImage
        case .saveToDrive:
            return BundleI18n.LarkMessageCore.Lark_Legacy_SaveFileToDrive
        case .saveVideo:
            return BundleI18n.LarkMessageCore.Lark_Audit_BlockedActionDownloadVideo
        case .sendFile:
            return BundleI18n.LarkMessageCore.Lark_Audit_BlockedActionSendFile
        case .sendImage:
            return BundleI18n.LarkMessageCore.Lark_Audit_BlockedActionSendImage
        case .sendVideo:
            return BundleI18n.LarkMessageCore.Lark_Audit_BlockedActionSendVideo
        case .addSticker:
            return BundleI18n.LarkMessageCore.Lark_Audit_BlockedActionAddToStickers
        case .receive, .localFilePreview, .localImagePreview, .localVideoPreview, .fileCopy:
            assertionFailure("has no config about actionText")
            return ""
        }
    }

    private func getAlertType(_ event: SecurityControlEvent) -> AlertType {
        switch event {
        case .openInAnotherApp, .saveToDrive:
            return .toast
        case .addSticker, .saveFile, .saveImage, .saveVideo, .sendFile, .sendImage, .sendVideo:
            return .window
        case .localFilePreview, .localImagePreview, .localVideoPreview:
            return .window
        case .receive, .fileCopy:
            assertionFailure("receive has no config about alertType")
            return .window
        }
    }

    private func getAlertTitle(_ event: SecurityControlEvent) -> String {
        switch event {
        case .localFilePreview, .localImagePreview, .localVideoPreview:
            return BundleI18n.LarkMessageCore.Lark_IM_UnableToPreview_PopUpTitle
        default:
            return BundleI18n.LarkMessageCore.Lark_Audit_BlockedActionDialogTitle
        }
    }

    public func authorityErrorHandler(event: SecurityControlEvent,
                                      authResult: ValidateResult?,
                                      from: NavigatorFrom?,
                                      errorMessage: String?,
                                      forceToAlert: Bool) {
        guard let from = from else {
            assertionFailure("from can not be nil")
            Self.logger.error("authorityErrorHandlerfrom is nil", additionalData: ["event": event.rawValue, "errorMessage": errorMessage ?? ""])
            return
        }

        //在 后端管控权限而非LarkSecurityAudit管控权限 的场景中，authResult会传nil，这种情况都按照authResult = .deny来处理（即后端管控不存在authResult = .error的情况）
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            //文件策略
            if authResult?.extra.resultSource == .fileStrategy || authResult?.extra.resultSource == .unknown {
                Self.logger.info("authorityErrorHandler by SDK", additionalData: ["event": event.rawValue,
                                                                                  "result": authResult?.result.rawValue.description ?? "",
                                                                                  "errorMessage": errorMessage ?? "",
                                                                                  "forceToAlert": forceToAlert.description])
                // 默认安全SDK内部弹窗，forceToAlert表示需要业务方弹窗
                if forceToAlert, let policyModel = event.generatePolicyModel(operatorTenantId: self.currentTenantID, operatorUid: self.currentUserID) {
                    self.securityPolicyService?.showInterceptDialog(policyModel: policyModel)
                }
                return
            }
            Self.logger.info("authorityErrorHandler by IM", additionalData: ["event": event.rawValue,
                                                                             "result": authResult?.result.rawValue.description ?? "",
                                                                             "errorMessage": errorMessage ?? "",
                                                                             "forceToAlert": forceToAlert.description])
            // DLP检测
            if authResult?.extra.resultSource == .dlpSensitive || authResult?.extra.resultSource == .dlpDetecting {
                var dlpMessage = self.getDLPErrorMessage(event: event, authResult: authResult)
                if let errorMessage = errorMessage, !errorMessage.isEmpty {
                    dlpMessage = errorMessage + "\n" + dlpMessage
                }
                if let view = self.transNavigatorFromToView(from) {
                    UDToast.showTips(with: dlpMessage, on: view)
                }
                return
            }
            // 旧权限管理
            let errorMessage = errorMessage ?? self.getDefaultErrorMessage(event: event, authResult: authResult)
            if authResult?.result == .error {
                let dialog = UDDialog()
                dialog.setContent(text: errorMessage)
                dialog.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Chat_StickerPackKnow)
                self.navigator.present(dialog, from: from)
                return
            }
            let alertType = self.getAlertType(event)
            switch alertType {
            case .toast:
                if let view = self.transNavigatorFromToView(from) {
                    UDToast.showTips(with: errorMessage, on: view)
                }
            case .window:
                let alert = LarkAlertController()
                alert.setTitle(text: self.getAlertTitle(event))
                alert.setContent(text: errorMessage)
                alert.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Chat_StickerPackKnow)
                self.navigator.present(alert, from: from)
            }
        }
    }

    private func getDefaultErrorMessage(event: SecurityControlEvent,
                                        authResult: ValidateResult?) -> String {
        switch event {
        case .localFilePreview:
            return BundleI18n.LarkMessageCore.Lark_IM_UnableToPreviewFile_PopUpDesc
        case .localImagePreview:
            return BundleI18n.LarkMessageCore.Lark_IM_UnableToPreviewImage_PopUpDesc
        case .localVideoPreview:
            return BundleI18n.LarkMessageCore.Lark_IM_UnableToPreviewVideo_PopUpDesc
        default:
            break
        }
        switch authResult?.result {
        case .error:
            return BundleI18n.LarkMessageCore.Lark_IM_IPChangedPermissionChangedTryLater_AlertText
        default:
            return BundleI18n.LarkMessageCore.Lark_Audit_BlockedActionsDueToPermissionSettings(self.getActionText(event: event))
        }
    }

    /// 获取DLP错误弹窗内容，目前只把saveImage点位迁移到了安全SDK
    private func getDLPErrorMessage(event: SecurityControlEvent, authResult: ValidateResult?) -> String {
        guard let source = authResult?.extra.resultSource else { return "" }

        // 检测不通过
        if source == .dlpSensitive {
            switch event {
            case .saveImage:
                return BundleI18n.LarkMessageCore.Lark_IM_DLP_ImageSensitiveNoDownload_Toast
            default:
                break
            }
        }
        // 正在检测中
        if source == .dlpDetecting {
            switch event {
            case .saveImage:
                return BundleI18n.LarkMessageCore.Lark_IM_DLP_UnableToDownload_Toast
            default:
                break
            }
        }
        // 其他情况不处理
        return ""
    }

    public func alertForDynamicAuthority(event: SecurityControlEvent,
                                         result: DynamicAuthorityEnum,
                                         from: NavigatorFrom?) {
        Self.logger.info("alertForDynamicAuthority", additionalData: ["event": event.rawValue,
                                                                      "result": result.rawValue])
        guard event == .receive else {
            //当前只有receive点位是动态点位，考虑到未来可能有其他动态点位才留了这个参数。 6.1版本 @贾潇
            assertionFailure("unexpected event")
            return
        }
        DispatchQueue.main.async { [weak from, weak self] in
            guard let self = self,
                  let from = from ?? self.navigator.mainSceneWindow else {
                return
            }
            switch result {
            case .loading:
                if let view = self.transNavigatorFromToView(from) {
                    UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_UnableToViewTryAgainLater_Toast,
                                     on: view)
                }
            case .deny:
                if let policyModel = event.generatePolicyModel(operatorTenantId: self.currentTenantID, operatorUid: self.currentUserID) {
                    self.securityPolicyService?.showInterceptDialog(policyModel: policyModel)
                }
            case .allow:
                assertionFailure("authority allow, should not alert")
            }
        }
    }

    private func transNavigatorFromToView(_ from: NavigatorFrom) -> UIView? {
        var view: UIView?
        if let fromVC = from.fromViewController {
            view = fromVC.view
        } else if let fromView = from as? UIView {
            view = fromView
        }
        return view
    }
}

extension DynamicAuthorityParams: Hashable {
    public static func == (lhs: DynamicAuthorityParams, rhs: DynamicAuthorityParams) -> Bool {
        guard lhs.event == rhs.event else { return false }
        guard lhs.messageID == rhs.messageID else { return false }
        guard lhs.senderUserId == rhs.senderUserId else { return false }
        guard lhs.senderTenantId == rhs.senderTenantId else { return false }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.event)
        hasher.combine(self.messageID)
    }
}
