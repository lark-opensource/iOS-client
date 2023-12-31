//
//  RenderRouterCardActionService.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/8/22.
//

import Foundation
import RustPB
import RxSwift
import LarkUIKit
import LarkModel
import LarkCore
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import UniverseDesignToast
import UniversalCardInterface
import UniversalCard
import LarkSDKInterface
import RoundedHUD
import EENavigator
import RenderRouterInterface
import LarkMessengerInterface
import EEMicroAppSDK
import LarkAppLinkSDK

class UniversalCardDependencyImpl: UniversalCardDependencyProtocol {
    let userResolver: LarkContainer.UserResolver?
    // 复制用值,目前是随便定的, 没使用的地方
    let copyableKeyPrefix: String = "UniversalCard"
    var actionService: UniversalCardActionServiceProtocol?

    init(userResolver: UserResolver?, actionDependency: EngineComponentDependency?, bizID: String, version: String) {
        self.userResolver = userResolver
        self.actionService = UniversalCardActionService(dependency: actionDependency, bizID: bizID, version: version)
    }
}

class UniversalCardActionService: UniversalCardActionServiceProtocol {
    
    private static let logger = Logger.log(UniversalCardActionService.self, category: "UniversalCardActionService")

    private var rustService: RustService?
    private var cardModuleDependency: UniversalCardModuleDependencyProtocol?
    private var actionFinished: Bool = true
    private weak var dependency: EngineComponentDependency?
    private lazy var serviceImpl: UniversalCardActionServiceImpl = {
       return UniversalCardActionServiceImpl(userResolver: dependency?.userResolver, dependency: dependency, monitor: self, logger: Self.logger)
    }()
    
    // 埋点数据
    let bizID: String
    let version: String
    var templateVersion: String? { cardModuleDependency?.templateVersion }

    init(dependency: EngineComponentDependency?, bizID: String, version: String) {
        self.dependency = dependency
        self.bizID = bizID
        self.version = version
        rustService = try? dependency?.userResolver.resolve(assert: RustService.self)
        cardModuleDependency = try? dependency?.userResolver.resolve(assert: UniversalCardModuleDependencyProtocol.self)
    }

    private let disposeBag = DisposeBag()

    // 打开链接
    func openUrl(
        context: UniversalCardActionContext,
        cardID: String?,
        urlStr: String?,
        from vc: UIViewController,
        callback: ((Error?) -> Void)?
    ) {
        serviceImpl.openUrl(context: context, id: cardID, urlStr: urlStr, from: vc, callback: callback)
    }

    // 发送请求
    func sendRequest(
        context: UniversalCardActionContext,
        cardSource: UniversalCardDataActionSourceInfo,
        actionID: String,
        params: [String: String]?,
        callback:((Error?, UniversalCardRequestResultType?) -> Void)?
    ) {
        Self.logger.info("SendRequest with actionID: \(actionID)", additionalData: ["traceID": context.trace.traceId])
        guard self.actionFinished else {
            Self.logger.info(
                "SendAction fail: last action not finished, skip send action",
                additionalData: ["traceID": context.trace.traceId, "actionID": actionID]
            )
            createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_request_not_allow,
                          trace: context.trace,
                          cardID: cardSource.cardID,
                          componentTag: context.elementTag)
                .setError(CardActionError.lastActionNotFinished)
                .flush()
            callback?(CardActionError.internalError("last action not finished"), nil)
            return
        }

        guard !actionID.isEmpty else {
            Self.logger.info("SendRequest fail: actionID is nil", additionalData: ["traceID": context.trace.traceId, "actionID": actionID])
            createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_request_data_error, 
                          trace: context.trace,
                          cardID: cardSource.cardID,
                          componentTag: context.elementTag)
                .setError(CardActionError.actionIDNil)
                .flush()
            callback?(CardActionError.internalError("ActionID is nil"), nil)
            return
        }

        let startTime = Date()
        Self.logger.info("SendRequest will send rust request", additionalData: ["traceID": context.trace.traceId])
        actionFinished = false

        var request = RustPB.Openplatform_V1_PutUniversalCardActionRequest()
        let cardID = cardSource.cardID
        request.cardID = cardID
        request.version = cardSource.version
        request.bizID = cardSource.bizID
        request.bizType = Int32(cardSource.bizType)
        request.actionID = actionID
        if let params = params { request.params = params }
        
        let actionService = self
        rustService?.async(RequestPacket(message: request)) { (responsePacket: ResponsePacket<Openplatform_V1_PutUniversalCardActionResponse>) in
            switch responsePacket.result {
            case .success(let res):
                actionService.dealWithActionResponseToast(context: context, res: res)
                actionService.serviceImpl.dealWithActionResponseLink(context: context, res: res, cardID: cardSource.cardID) { error in
                    guard let error = error else { return }
                    Self.logger.error("sendRequest response open link fail \(error.localizedDescription)", additionalData: ["traceID": context.trace.traceId])
                }
                actionService.actionFinished = true
                Self.logger.info("SendRequest success", additionalData: ["traceID": context.trace.traceId, "actionID": actionID])
                actionService.createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_request_success,
                                            trace: context.trace,
                                            cardID: cardSource.cardID,
                                            startTime: startTime,
                                            componentTag: context.elementTag)
                .addCategoryValue(MonitorField.ActionID, [actionID])
                .flush()
                actionService.trackUniversalCardClick(actionType: .interaction, elementTag: context.elementTag, cardID: cardID)
                callback?(nil, .RequestFinished)
            case .failure(let error):
                var errorInfo: BusinessErrorInfo?
                if case let .businessFailure(info) = error as? RCError {
                    errorInfo = info
                }
                Self.logger.error(
                    "SendRequest received send action callback errorInfo: \(String(describing: errorInfo))",
                    additionalData: ["traceID": context.trace.traceId, "actionID": actionID],
                    error: error
                )
                actionService.showToast(context: context, type: .error, text: BundleI18n.LarkOpenPlatform.Lark_Legacy_MsgCardFail)
                actionService.actionFinished = true
                actionService.createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_request_network_error,
                                            trace: context.trace,
                                            cardID: cardSource.cardID,
                                            startTime: startTime,
                                            componentTag: context.elementTag)
                .setErrorCode(String(errorInfo?.errorCode ?? 0))
                .setErrorMessage(errorInfo?.debugMessage ?? error.localizedDescription)
                .addCategoryValue(MonitorField.ActionID, [actionID])
                .addCategoryValue(MonitorField.ErrorStatus, errorInfo?.errorStatus)
                .addCategoryValue(MonitorField.TTLogId, errorInfo?.ttLogId)
                .flush()
                callback?(error, nil)
            }
        }
    }

    // 打开用户 profile 页面
    func openProfile(
        context: UniversalCardActionContext,
        id: String,
        from: UIViewController
    ) {
        serviceImpl.openProfile(context: context, id: id, from: from)
    }

    // 存储本地数据
    func updateLocalData(
        context: UniversalCardActionContext,
        bizID: String,
        cardID: String,
        version: String,
        data: String,
        callback: @escaping (Error?, CardVersion?, CardStatus?) -> Void
    ) {
        Self.logger.info("updateLocalData with cardID: \(cardID) version: \(version)", additionalData: ["traceID": context.trace.traceId])
        var request = Openplatform_V1_UpdateUniversalCardLocalDataRequest()
        request.cardID = cardID
        request.version = version
        request.bizID = bizID
        request.jsonDeltaData = data
        rustService?.sendAsyncRequest(request).subscribe(
            onNext: { (res: Openplatform_V1_UpdateUniversalCardLocalDataResponse) in
                Self.logger.info("UpdateLocalData success cardVersion:\(res.version), jsonData: \(res.jsonData)", additionalData: ["traceID": context.trace.traceId])
                callback(nil, res.version, res.jsonData)
            },
            onError: { error in
                var errorInfo: BusinessErrorInfo?
                if case let .businessFailure( info) = error as? RCError { errorInfo = info }
                Self.logger.info("UpdateLocalData fail error code:\(errorInfo?.errorCode ?? 0) debugMessage: \(String(describing: errorInfo?.debugMessage))", additionalData: ["traceID": context.trace.traceId])
                callback(error, nil, nil)
            }).disposed(by: self.disposeBag)
    }
    
    func getChatID() -> String? {
        return dependency?.getChatID()
    }

    // 弹出提示
    func showToast(
        context: UniversalCardActionContext,
        type: UDToastType,
        text: String,
        on view: UIView? = nil
    ) {
        serviceImpl.showToast(context: context, type: type, text: text, on: view)
    }

    // 批量获取用户信息
    func fetchUsers(
        context: UniversalCardActionContext,
        ids: [String],
        callback: @escaping (Error?, [String: UniversalCardPersonInfo]?) -> Void
    ) {
        serviceImpl.fetchUsers(context: context, ids: ids, callback: callback)
    }

    // 预览图片, 给的是当前卡片的图片资源数组和序号
    func showImagePreview(
        context: UniversalCardActionContext,
        properties: [RustPB.Basic_V1_RichTextElement.ImageProperty],
        index: Int,
        from: UIViewController
    ) {
        serviceImpl.showImagePreview(context: context, properties: properties, index: index, from: from)
    }
    
    func openCodeBlockDetail(
        context: UniversalCardActionContext,
        property: Basic_V1_RichTextElement.CodeBlockV2Property,
        from: UIViewController
    ) {
        serviceImpl.openCodeBlockDetail(context: context, property: property, from: from)
    }

    func updateSummary(context: UniversalCardInterface.UniversalCardActionContext, original: String, translation: String) {}
    
    func getTranslateConfig() -> UniversalCardInterface.UniversalCardConfig.TranslateConfig? {
        return nil
    }
}

extension UniversalCardActionService {
    fileprivate func dealWithActionResponseToast(context: UniversalCardActionContext, res: Openplatform_V1_PutUniversalCardActionResponse) {
        guard res.hasToast, res.toast.hasContent, !res.toast.content.isEmpty else { return }
        Self.logger.info("dealWithActionResponseToast", additionalData: ["traceID": context.trace.traceId])
        var toastType = UDToastType.info
        switch res.toast.code {
            case .success: toastType = .success
            case .error: toastType = .error
            case .info: toastType = .info
            case .warning: toastType = .warning
        @unknown default: break
        }
        showToast(context: context, type: toastType, text: res.toast.content)
    }
}
