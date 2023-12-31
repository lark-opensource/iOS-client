//
//  MyAIPageServiceImpl+QuickAction.swift
//  LarkAI
//
//  Created by 李勇 on 2023/10/13.
//

import Foundation
import LarkAIInfra
import ServerPB
import RxSwift
import Darwin
import CryptoKit
import CommonCrypto
import LarkRustClient
import RustPB
import LarkCore
import LarkFoundation
import LarkMessengerInterface
import UniverseDesignToast
import LarkSDKInterface

/// 快捷指令相关逻辑放这里
public extension MyAIPageServiceImpl {
    /// 强制更新 QuickAction（业务主动调用、开启 NewTopic 时调用）
    ///
    /// 调用时机:
    ///   - 业务主动调用
    func updateQuickActions() {
        if isFollowUpEnabled { return }
        // 因为是业务强制刷新，因此要把 lastQuickActionResult 恢复为初始值，避免新的数据被丢弃
        lastQuickActionResult = .initial
        Self.logger.info("[MyAI.QuickAction][Fetch][\(#function)] will manually update quickactions for round: \(lastAIRoundInfo)")
        // 7.2 改为单次请求
        // fetchQuickActions(withType: .preConfig, round: lastAIRoundInfo, isFirstStart: false)
        fetchQuickActions(withType: .all, round: lastAIRoundInfo, isFirstStart: false)
    }

    /// 根据 RoundInfo 状态，拉取 QuickAction
    /// - Parameters:
    ///   - currentRound: 当前的 RoundInfo，用于过滤重复请求
    ///   - isFirstStart: 是否首次进入 MyAI 会话
    ///
    /// 调用时机:
    ///   - 初次进入会话（本端 ）: lastQuickActionResult == .initial
    ///   - 一轮消息发送完毕（本端 & 其他端）:  status == .responding
    ///   - 点击了 New Topic（本端 & 其他端）: status == .unknown
    ///   - 选择、切换了工具（本端 & 其他端）: status == .unknown
    func updateQuickActionsIfNeeded(fromRound currentRound: AIRoundInfo, isFirstStart: Bool) {
        if isFollowUpEnabled { return }
        // 新一轮会话开启后，清空上一轮的快捷指令
        if currentRound.status == .responding || currentRound.status.isFinished, !aiQuickActions.value.isEmpty {
            aiQuickActions.accept([])
        }
        // 一轮会话结束回调 .done，开启新话题后、选择工具后回调 .unknown
        if lastQuickActionResult == .initial
            || currentRound.status.isFinished
            || currentRound.status == .unknown {
            Self.logger.info("[MyAI.QuickAction][Fetch][\(#function)] will automatically update quickactions for round: \(currentRound), is first start: \(isFirstStart)")
            // 7.2 改为单次请求
            // fetchQuickActions(withType: .preConfig, round: currentRound, isFirstStart: isFirstStart)
            fetchQuickActions(withType: .all, round: currentRound, isFirstStart: isFirstStart)
        }
    }

    /// 获取最新的快捷指令，并通知 AI 会话展示在视图上
    func fetchQuickActions(withType fetchType: ServerPB_Office_ai_FetchActionType,
                                   round: AIRoundInfo,
                                   isFirstStart: Bool) {
        // 构建 ServerPB 透传请求
        // 构建 Request 需要获取业务方传入的 Params，这个过程可能比较耗时，因此在子线程处理
        DispatchQueue.global(qos: .background).async {
            var quickActionRequest = self.createServerQuickActionRequest(withType: fetchType)
            // 添加流量特征（首次进入 MyAI 对话）
            quickActionRequest.triggerParamsMap["SYS_IS_USER_FIRST_CALL"] = isFirstStart ? "YES" : "NO"
            Self.logger.info("[MyAI.QuickAction][Fetch][\(#function)] sending quick action request (type: \(fetchType.name)): \(quickActionRequest)")
            // 发送 ServerPB 透传请求
            self.rustClient?.sendPassThroughAsyncRequest(quickActionRequest, serCommand: .larkOfficeAiFetchQuickAction)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (response: ServerPB_Office_ai_FetchQuickActionsResponse) in
                    guard let self = self else { return }
                    if round.updateTime < self.lastQuickActionResult.updateTime {
                        // response 是过期请求，直接丢弃
                        Self.logger.warn("[MyAI.QuickAction][Fetch][\(#function)] fetch quick actions succeed, discard because of old-update-time (type: \(fetchType.name), count: \(response.quickActions.count)): \(response.quickActions)") // swiftlint:disable:this line_length
                    } else if round.updateTime == self.lastQuickActionResult.updateTime {
                        if fetchType.priority > self.lastQuickActionResult.resultType.priority {
                            Self.logger.info("[MyAI.QuickAction][Fetch][\(#function)] fetch quick actions succeed, accept because of high-priority (type: \(fetchType.name), count: \(response.quickActions.count)): \(response.quickActions)") // swiftlint:disable:this line_length
                            self.lastQuickActionResult = QuickActionResult(updateTime: round.updateTime, resultType: fetchType)
                            self.aiQuickActions.accept(response.quickActions)
                        } else {
                            Self.logger.warn("[MyAI.QuickAction][Fetch][\(#function)] fetch quick actions succeed, discard because of low-priority (type: \(fetchType.name), count: \(response.quickActions.count)): \(response.quickActions)") // swiftlint:disable:this line_length
                        }
                    } else {
                        Self.logger.info("[MyAI.QuickAction][Fetch][\(#function)] fetch quick actions succeed, accept because of new-update-time (type: \(fetchType.name), count: \(response.quickActions.count)): \(response.quickActions)") // swiftlint:disable:this line_length
                        self.lastQuickActionResult = QuickActionResult(updateTime: round.updateTime, resultType: fetchType)
                        self.aiQuickActions.accept(response.quickActions)
                    }
                }, onError: { error in
                    Self.logger.error("[MyAI.QuickAction][Fetch][\(#function)] fetch quick actions failed (type: \(fetchType.name)): \(error)")
                }).disposed(by: self.disposeBag)
        }
    }

    /// 构建快捷指令请求
    func createServerQuickActionRequest(withType fetchType: ServerPB_Office_ai_FetchActionType = .all) -> ServerPB_Office_ai_FetchQuickActionsRequest {
        var quickActionRequest = ServerPB_Office_ai_FetchQuickActionsRequest()
        quickActionRequest.fetchActionType = fetchType
        if self.chatMode {
            // MyAI 分会场（会话模式）获取快捷指令
            quickActionRequest.chatID = String(self.chatId)
            quickActionRequest.aiChatModeID = String(self.chatModeConfig.aiChatModeId)
            // ChatContext 中需要获取流量特征，此回调为耗时操作，应在子线程执行
            quickActionRequest.chatContext = self.chatModeConfig.getQuickActionChatContext()
        } else {
            // MyAI 主会场（单聊）获取快捷指令
            // quickActionRequest.scenario = .im
            quickActionRequest.chatID = String(self.chatId)
        }
        return quickActionRequest
    }

    /// 构建 Follow-up 快捷指令请求，和上面的不同，这个请求走 RustPB
    func createSdkQuickActionRequest(withType fetchType: Im_V1_FetchQuickActionsRequest.FetchActionType = .all) -> Im_V1_GetAIRoundQuickActionRequest {
        var quickActionRequest = Im_V1_FetchQuickActionsRequest()
        quickActionRequest.fetchActionType = fetchType
        if self.chatMode {
            // MyAI 分会场（会话模式）获取快捷指令
            quickActionRequest.chatID = String(self.chatId)
            quickActionRequest.aiChatModeID = String(self.chatModeConfig.aiChatModeId)
            // ChatContext 中需要获取流量特征，此回调为耗时操作，应在子线程执行
            quickActionRequest.chatContext = self.chatModeConfig.getQuickActionChatContext()
        } else {
            // MyAI 主会场（单聊）获取快捷指令
            // quickActionRequest.scenario = .im
            quickActionRequest.chatID = String(self.chatId)
        }
        var wrapperRequest = Im_V1_GetAIRoundQuickActionRequest()
        wrapperRequest.fetchRequest = quickActionRequest
        wrapperRequest.chatID = String(self.chatId)
        if self.chatMode { wrapperRequest.chatID = String(self.chatModeConfig.aiChatModeId) }
        wrapperRequest.roundIDPosition = self.aiRoundInfo.value.roundLastPosition
        return wrapperRequest
    }

    /// 通过 ID 获取快捷指令详细信息并执行
    /// - Parameters:
    ///   - applink: 快捷指令的 AppLink
    ///   - service: 处理快捷指令的 Service，由调用方解析并传过来，MyAIPageService 本身不持有
    ///   - onChat: 当前所在的 Chat 页面，由调用方解析并传过来，MyAIPageService 本身不持有
    /// - NOTE: 技术方案：[分对话引导和插件选择优化](https://bytedance.feishu.cn/wiki/M5VawO9kqitbhWk28Kuch7knnvg)
    func handleQuickActionByApplinkURL(_ applink: URL, service: MyAIQuickActionSendService, onChat: UIViewController) {
        // 解析快捷指令的 checkID
        // 判断快捷指令的时效性：checkID 是 sessionID 的 MD5 编码
        if let checkID = applink.queryParameters["check_id"], let currentCheckID = lastAIRoundInfo.sessionID?.encodeMD5() {
            if currentCheckID != checkID {
                Self.logger.error("[MyAI.QuickAction][AppLink] Checking validity failed: sessionID not matched, \(applink)")
                UDToast.showFailure(with: BundleI18n.LarkAI.MyAI_IM_PromptSuspendedTryOther_Toast, on: onChat.view)
                return
            }
        } else {
            Self.logger.warn("[MyAI.QuickAction][AppLink] Checking validity skipped: no sessionID currently")
        }
        // 解析快捷指令的类型
        guard let type = applink.queryParameters["action_type"],
              let typeRawValue = Int(type),
              let actionType = ServerPB_Office_ai_QuickActionType(rawValue: typeRawValue) else {
            Self.logger.error("[MyAI.QuickAction][AppLink] Parsing action type failed: \(applink)")
            UDToast.showFailure(with: BundleI18n.LarkAI.MyAI_IM_FailLoadPrompts_Toast, on: onChat.view)
            return
        }
        // Query 类型直接执行，其他类型请求详细信息后再执行
        Self.logger.info("[MyAI.QuickAction][AppLink] Ready to execute quickAction from applink: \(applink)")
        switch actionType {
        case .query:
            handleQueryQuickAction(applink, service: service, onChat: onChat)
        default:
            handlePromptQuickAction(applink, service: service, onChat: onChat)
        }
    }

    /// 对于 AppLink 中 Query 类型的快捷指令，直接解析名称并作为普通消息发送，不需要拉取详细信息
    func handleQueryQuickAction(_ applink: URL, service: MyAIQuickActionSendService, onChat: UIViewController) {
        // AppLink URL 中的 base64 编码要使用 urlSafe 模式解析，否则会乱码或解析失败
        guard let base64Name = applink.queryParameters["name"],
              let data = try? Base64.decode(base64Name, coding: .urlSafe),
              let name = String(data: data, encoding: .utf8) else {
            Self.logger.error("[MyAI.QuickAction][AppLink] Parsing or decoding query name failed: \(applink)")
            UDToast.showFailure(with: BundleI18n.LarkAI.MyAI_IM_FailLoadPrompts_Toast, on: onChat.view)
            return
        }
        // 本地构建 Query 类型的快捷指令
        var quickAction = ServerPB_Office_ai_QuickAction()
        quickAction.actionType = .query
        quickAction.name = name
        quickAction.displayName = name
        // 上报点击埋点
        self.quickActionTracker.reportQuickActionClickEvent(
            quickAction,
            roundId: String(self.lastAIRoundInfo.roundId),
            location: .onboardingCard,
            extraParams: ["session_id": self.aiRoundInfo.value.sessionID ?? ""]
        )
        service.handleAIQuickAction(quickAction, sendTracker: QuickActionSendTracker(sendCallback: { [weak self] isEdited, chat in
            guard let self = self else { return }
            // 上报发送埋点
            self.quickActionTracker.reportQuickActionSendEvent(
                quickAction,
                roundId: String(self.lastAIRoundInfo.roundId),
                location: .onboardingCard,
                isEdited: isEdited,
                extraParams: ["session_id": self.aiRoundInfo.value.sessionID ?? ""]
            )
            // 上报卡片中点击埋点，判断是否是「创建插件时填写的引导问题」
            let sceneCustom = applink.queryParameters["scene_custom"] == "1"; let sceneId = applink.queryParameters["scene_id"] ?? ""
            IMTracker.Scene.Click.card(chat, params: ["click": "question", "action_id": "", "action_name": name, "action_type": sceneCustom ? "scene_custom" : "query", "scene_id": "[\(sceneId)]"])
        }))
    }

    /// 对于 AppLink 中 Prompt / API 类型的快捷指令，需要根据 actionID 拉取详细信息后再执行
    func handlePromptQuickAction(_ applink: URL, service: MyAIQuickActionSendService, onChat: UIViewController) {
        guard let actionID = applink.queryParameters["action_id"],
              let queryMetadata = applink.queryParameters["query_metadata"],
              let checkID = applink.queryParameters["check_id"] else {
            Self.logger.info("[MyAI.QuickAction][AppLink] Parsing applink parameter failed: \(applink).")
            UDToast.showFailure(with: BundleI18n.LarkAI.MyAI_IM_FailLoadPrompts_Toast, on: onChat.view)
            return
        }
        var loadingToast: UDToast?
        var isFetchFinished = false
        // 延迟展示 loading，避免接口返回快的情况下 toast 闪现
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200), execute: {
            guard !isFetchFinished else { return }
            loadingToast = UDToast.showLoading(with: BundleI18n.LarkAI.MyAI_IM_LoadingPrompts_Toast, on: onChat.view)
        })
        var quickActionRequest = ServerPB_Office_ai_FetchQuickActionByIDRequest()
        quickActionRequest.actionID = actionID
        quickActionRequest.checkID = checkID
        quickActionRequest.systemMetaData = queryMetadata
        if self.chatMode {
            // MyAI 分会场（会话模式）获取快捷指令
            quickActionRequest.chatID = String(self.chatId)
            quickActionRequest.aiChatModeID = String(self.chatModeConfig.aiChatModeId)
            // ChatContext 中需要获取流量特征，此回调为耗时操作，应在子线程执行
            quickActionRequest.chatContext = self.chatModeConfig.getQuickActionChatContext()
        } else {
            // MyAI 主会场（单聊）获取快捷指令
            // quickActionRequest.scenario = .im
            quickActionRequest.chatID = String(self.chatId)
        }
        Self.logger.info("[MyAI.QuickAction][Fetch][\(#function)] sending quick action request (type: byID): \(quickActionRequest)")
        rustClient?.sendPassThroughAsyncRequest(quickActionRequest, serCommand: .larkOfficeAiFetchQuickActionByID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response: ServerPB_Office_ai_FetchQuickActionByIDResponse) in
                guard let self = self else { return }
                Self.logger.error("[MyAI.QuickAction][Fetch][\(#function)] fetch single quick actions success: \(response)")
                isFetchFinished = true
                loadingToast?.remove()
                let quickAction = response.quickAction
                // 上报点击埋点
                self.quickActionTracker.reportQuickActionClickEvent(
                    quickAction,
                    roundId: String(self.lastAIRoundInfo.roundId),
                    location: .onboardingCard,
                    extraParams: ["session_id": self.aiRoundInfo.value.sessionID ?? ""]
                )
                service.handleAIQuickAction(quickAction, sendTracker: QuickActionSendTracker(sendCallback: { [weak self] isEdited, chat in
                    Self.logger.info("[MyAI.QuickAction][Send][\(#function)] send quick actions. edited: \(isEdited)")
                    guard let self = self else { return }
                    // 上报发送埋点
                    self.quickActionTracker.reportQuickActionSendEvent(
                        quickAction,
                        roundId: String(self.lastAIRoundInfo.roundId),
                        location: .onboardingCard,
                        isEdited: isEdited,
                        extraParams: ["session_id": self.aiRoundInfo.value.sessionID ?? ""]
                    )
                    // 上报卡片中点击埋点，判断是否是「创建插件时填写的引导问题」
                    let sceneCustom = applink.queryParameters["scene_custom"] == "1"
                    let actionType = sceneCustom ? "scene_custom" : (quickAction.actionType == .promptTask ? "promptTask" : "api"); let sceneId = applink.queryParameters["scene_id"] ?? ""
                    IMTracker.Scene.Click.card(chat, params: ["click": "question", "action_id": actionID, "action_name": quickAction.name, "action_type": actionType, "scene_id": "[\(sceneId)]"])
                }))
            }, onError: { [weak onChat] error in
                Self.logger.error("[MyAI.QuickAction][Fetch][\(#function)] fetch single quick actions failed: \(error)")
                isFetchFinished = true
                loadingToast?.remove()
                if let currentChatVC = onChat, let rcError = error.underlyingError as? LarkRustClient.RCError {
                    if case .businessFailure(let errorInfo) = rcError, errorInfo.errorCode == 500_102 {
                        // 快捷指令过期失效
                        UDToast.showFailure(with: BundleI18n.LarkAI.MyAI_IM_PromptSuspendedTryOther_Toast, on: currentChatVC.view, error: error)
                    } else {
                        // 其他错误类型，提示“指令加载失败，请稍后重试”
                        UDToast.showFailure(with: BundleI18n.LarkAI.MyAI_IM_FailLoadPrompts_Toast, on: currentChatVC.view, error: error)
                    }
                }
            }).disposed(by: self.disposeBag)
    }

    /// 业务方主动触发的quickAction的接口
    func sendQuickAction(_ quickAction: AIQuickAction, trackParmas: [String: Any]) {
        //先把要执行的快捷指令缓存下来。以免相关服务没有初始化完 执行失败。
        //如果连续赋值，旧的值会被丢弃。但这种case通常不会发生（除非业务方在快捷指令服务没有初始化完时连续触发发送快捷指令）
        self.cacheQuickAction = (quickAction, trackParmas)
        performCacheQuickAction()
    }

    /// 执行缓存的快捷指令。
    func performCacheQuickAction() {
        //当快捷指令服务初始化好、thread创建好后，这个方法才会执行成功。否则会等到首屏渲染后再次触发。
        guard chatModeThreadMessage != nil else { return }
        if let myAIQuickActionSendService = self.myAIQuickActionSendService,
           let cacheQuickAction = self.cacheQuickAction {
            myAIQuickActionSendService.handleAIQuickAction(cacheQuickAction.quickAction,
                                                       sendTracker: QuickActionSendTracker(sendCallback: { [weak self] _, _ in
                guard let self = self else { return }
                // 上报发送埋点
                self.quickActionTracker.reportQuickActionClickEvent(cacheQuickAction.quickAction,
                                                                    roundId: String(self.lastAIRoundInfo.roundId),
                                                                    location: .unknown,
                                                                    extraParams: cacheQuickAction.trackParams)
            }))
            self.cacheQuickAction = nil
        }
    }
}

/// 记录 QuickAction 的更新结果，用来排除 QuickAction 请求的失效返回值
struct QuickActionResult: Equatable {
    /// 当前 QuickAction 结果所对应的 round 更新时间
    var updateTime: Int64 = Int64.min
    /// 当前 QuickAction 结果所对应的请求类型（preConfig / all）
    var resultType: ServerPB_Office_ai_FetchActionType = .preConfig

    /// 初始值
    static var initial: QuickActionResult {
        QuickActionResult()
    }
}

private extension ServerPB_Office_ai_FetchActionType {
    /// 日志里打印的名称，用来区分请求
    var name: String {
        switch self {
        case .preConfig:        return "preConfig"
        case .queryGeneration:  return "queryGeneration"
        case .all:              return "all"
        @unknown default:       return ""
        }
    }

    /// 优先级，高优先级的返回结果能够覆盖低优先级的
    var priority: UInt8 {
        switch self {
        case .preConfig:        return 1
        case .queryGeneration:  return 2
        case .all:              return 3
        @unknown default:       return 0
        }
    }
}

extension String {
    func encodeMD5() -> String? {
        guard let data = self.data(using: .utf8) else { return nil }
        let md5Formatter = "%02hhx"
        if #available(iOS 13.0, *) {
            let digest = Insecure.MD5.hash(data: data)
            return digest.map { String(format: md5Formatter, $0) }.joined()
        } else {
            var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
            _ = digest.withUnsafeMutableBytes { digestBytes -> UInt8 in
                data.withUnsafeBytes { messageBytes -> UInt8 in
                    if let messageBytesBaseAddress = messageBytes.baseAddress,
                       let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                        let messageLength = CC_LONG(data.count)
                        CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                    }
                    return 0
                }
            }
            return digest.map { String(format: md5Formatter, $0) }.joined()
        }
    }
}
