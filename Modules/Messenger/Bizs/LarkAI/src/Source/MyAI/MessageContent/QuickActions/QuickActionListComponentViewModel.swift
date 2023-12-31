//
//  QuickActionListComponentViewModel.swift
//  LarkAI
//
//  Created by Hayden on 22/8/2023.
//

import RxSwift
import Foundation
import LarkMessageBase
import LarkSDKInterface
import LarkMessengerInterface
import RustPB
import ServerPB
import LarkRustClient
import LarkAIInfra
import LarkContainer
import LKCommonsLogging

protocol QuickActionViewModelContext: ViewModelContext {
    var myAIPageService: MyAIPageService? { get }
    var myAIService: MyAIService? { get }
    var rustSDKService: SDKRustService? { get }
    var pushCenter: PushNotificationCenter? { get }
}

class QuickActionComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: QuickActionViewModelContext>: NewMessageSubViewModel<M, D, C> {

    private let logger = Logger.log(QuickActionComponentViewModel.self, category: "Module.LarkAI")

    private enum Config {
        /// 是否延迟展示 loading
        static var shouldDelayLoading: Bool { false }
        /// 延迟 loading 的时长，如果接口在该时间内返回，则不显示 loading，单位：毫秒
        static var delayLoadingTimeMS: Int { 200 }
        /// 请求过快时，是否展示假 loading
        static var shouldMockLoading: Bool { true }
        /// 假 loading 时长，如果接口在该时间内返回，则显示假 loading，直到到达该时长，单位：毫秒
        static var minimumLoadingTimeMS: Int { 1000 }
        /// 是否丢弃 loading 时间过长的请求
        static var shouldDiscardLoading: Bool { false }
        /// 最大 loading 时长，如果接口超出该时间仍未返回，则丢弃快捷指令，单位：毫秒
        static var maximumLoadingTimeMS: Int { 5000 }
    }

    /// 快捷指令的展示状态
    enum ActionStatus: Int, Equatable {
        /// 消息下方不显示快捷指令区域
        case hidden
        /// 消息下方显示 loading 气泡
        case loading
        /// 消息下方显示快捷指令列表
        case shown
    }

    /// 记录是否 actionStatus 被由 .shown 改为 .hidden。
    /// - NOTE: 这种情况说明在快捷指令请求结果返回之前，该消息已经过期（不是最后一条了），此时再返回的快捷指令不应该再展示
    private var hasChangedToHidden: Bool = false

    /// 当前快捷指令的状态（隐藏、加载、展示）存在一个大概率复现的问题：进群时follow up没有完全展示出来；原因：
    /// 1.首屏ChatMessagesViewController.refreshForMessages调用，UITableView会先确定当前屏幕内Cell的总高度
    /// 2.此行代码触发重新布局，把loading/follow up高度计算了出来，实际当前屏幕内Cell的总高度新增了x
    /// 3.接着上面的1，UITableView首屏渲染完成，此时loading/follow up的内容就显示在了屏幕下方
    /// 解决办法1：如果当前要展示loading/follow up，则需要在initialize中同步计算出来；需要SDK新增一个local接口给端上同步调用，推荐
    /// 解决办法2：首屏渲染后才开始监听aiRoundInfo，之后才触发重新布局；但是界面会再跳动一下，不推荐
    private(set) var actionStatus: ActionStatus = .hidden {
        didSet {
            guard actionStatus != oldValue else { return }
            // 通过 PageService 获得首屏渲染状态，避免在首屏渲染前刷新 UI，导致 Cell 高度异常
            if let pageService = context.myAIPageService as? MyAIPageServiceImpl {
                if pageService.isFirstRendered {
                    // 如果首屏渲染已完成，立即更新 UI
                    updateQuickActionUIIfNeeded()
                } else {
                    // 如果首屏渲染未完成，延后到首屏渲染后更新 UI
                    pageService.onFirstRendered = { [weak self] in
                        self?.updateQuickActionUIIfNeeded()
                    }
                }
            } else {
                updateQuickActionUIIfNeeded()
            }
        }
    }

    /// 当前应该展示的 QuickAction 列表
    private(set) var currentQuickActions: [AIQuickActionModel] = []

    private let disposeBag = DisposeBag()

    override func initialize() {
        super.initialize()
        guard let myAIPageService = self.context.myAIPageService, myAIPageService.isFollowUpEnabled,
              let myAIService = self.context.myAIService else { return }
        /// 监听 AIRoundInfo
        myAIPageService.aiRoundInfo
            .filter({ $0.chatId != AIRoundInfo.default.chatId })
            .subscribe(onNext: { [weak self] (currentRoundInfo) in
                guard let `self` = self else { return }
                let showQuickAction = self.judgeCurrShowStatus(forRound: currentRoundInfo)
                if showQuickAction {
                    let quickActions = myAIService.getAuickActions(chatID: myAIPageService.chatId,
                                                                   aiChatModeID: myAIPageService.chatModeConfig.aiChatModeId,
                                                                   messagePosition: myAIPageService.aiRoundInfo.value.roundLastPosition)
                    if !quickActions.isEmpty {
                        self.currentQuickActions = quickActions
                        self.actionStatus = .shown
                    } else {
                        self.fetchQuickActions(forRound: currentRoundInfo, onLoading: { [weak self] in
                            self?.actionStatus = .loading
                        }, onError: { [weak self] in
                            self?.actionStatus = .hidden
                        }, onSucceed: { [weak self] quickActions in
                            guard let self = self else { return }
                            myAIService.putAuickActions(chatID: myAIPageService.chatId,
                                                        aiChatModeID: myAIPageService.chatModeConfig.aiChatModeId,
                                                        messagePosition: myAIPageService.aiRoundInfo.value.roundLastPosition,
                                                        quickActions: quickActions)

                            // 判断返回结果是否已经过期
                            if !self.hasChangedToHidden, self.judgeCurrShowStatus(forRound: currentRoundInfo) {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                                    if self.currentQuickActions.isEmpty {
                                        self.actionStatus = .hidden
                                    } else {
                                        self.actionStatus = .shown
                                    }
                                })

                            } else {
                                self.logger.warn("[MyAI.QuickAction][Fetch][\(#function)] discard follow-up quick actions because of deprecation")
                            }
                        })
                    }

                } else {
                    self.actionStatus = .hidden
                }
            }).disposed(by: self.disposeBag)
        /// 监听假消息上屏，立刻清除之前的快捷指令
        myAIPageService.onQuasiMessageShown.observeOn(MainScheduler.instance)
            .skip(1)
            .subscribe(onNext: { [weak self] in
                self?.actionStatus = .hidden
            }).disposed(by: disposeBag)
    }

    private func fetchQuickActions(forRound round: AIRoundInfo,
                                   onLoading: @escaping () -> Void,
                                   onError: @escaping () -> Void,
                                   onSucceed: @escaping (_ quickActions: [AIQuickActionModel]) -> Void) {

        guard let rustService = context.rustSDKService else { return }
        guard let pageService = context.myAIPageService else { return }
        // 记录请求结果是否已返回
        var hasCompleted: Bool = false
        // 延迟 loading 的时间，用来避免请求返回过快，UI 上的跳动
        if Config.shouldDelayLoading {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Config.minimumLoadingTimeMS), execute: {
                // 如果经过延时后，结果还未返回，则展示 loading
                if !hasCompleted {
                    onLoading()
                } else {
                    self.logger.info("[MyAI.QuickAction][Fetch][\(#function)] api returns before \(Config.minimumLoadingTimeMS)")
                }
            })
        } else {
            onLoading()
        }
        // 设置最长 loading 事件，用来避免快捷指令 loading 时间过长
        if Config.shouldDiscardLoading {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Config.maximumLoadingTimeMS), execute: {
                // 如果经过延时后，结果还未返回，则不再显示快捷指令，作为接口 error 来处理
                if !hasCompleted {
                    onError()
                    self.logger.info("[MyAI.QuickAction][Fetch][\(#function)] api not returns after \(Config.maximumLoadingTimeMS)")
                }
            })
        }
        let request = pageService.createSdkQuickActionRequest(withType: .all)
        self.logger.info("[MyAI.QuickAction][Fetch][\(#function)] sending quick action request (type: follow-up): \(request)")
        let startTime = DispatchTime.now()
        rustService.sendAsyncRequest(request)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response: Im_V1_GetAIRoundQuickActionResponse) in
                guard let self = self else { return }
                self.logger.info("[MyAI.QuickAction][Fetch][\(#function)] fetch follow-up quick actions succeed (count: \(response.quickActions.count)): \(response.quickActions)")
                let endTime = DispatchTime.now()
                let requestTimeMS = Int(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds / 1_000_000)
                // 如果请求时长过快，则展示假 loading，避免 UI 跳动
                if Config.shouldMockLoading, requestTimeMS < Config.minimumLoadingTimeMS {
                    let remainingTimeMS = Config.minimumLoadingTimeMS - requestTimeMS
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(remainingTimeMS), execute: { [weak self] in
                        guard let self = self else { return }
                        self.currentQuickActions = response.quickActions
                        hasCompleted = true
                        onSucceed(response.quickActions)
                    })
                } else {
                    self.currentQuickActions = response.quickActions
                    hasCompleted = true
                    onSucceed(response.quickActions)
                }
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.logger.error("[MyAI.QuickAction][Fetch][\(#function)] fetch follow-up quick actions failed: \(error)")
                self.currentQuickActions = []
                hasCompleted = true
                onError()
            }).disposed(by: self.disposeBag)
    }

    private func updateQuickActionUIIfNeeded() {
        self.binderAbility?.syncToBinder()
        self.binderAbility?.updateComponentAndRoloadTable()
        // 记录快捷指令已隐藏的状态，如果已隐藏，之后就不再展示
        if actionStatus == .hidden {
            hasChangedToHidden = true
        }
        // 上报快捷指令展示埋点
        if actionStatus == .shown, !currentQuickActions.isEmpty {
            reportQuickActionShownEvent(currentQuickActions)
        }
    }

    /// 判断当前是否应该展示、隐藏；此时传入的AIRoundInfo一定是当前主分会场对应的，MyAIPageService中已经过滤了
    ///
    /// 消息下方展示 Follow up 快捷指令的条件：
    /// - isP2PAIChat == true（已在 `QuickActionComponentFactory` 中前置判断）
    /// - message.isFromAI == true（已在 `QuickActionComponentFactory` 中前置判断）
    /// - AIRoundInfo 的 Status 为 done
    /// - AIRoundInfo.last_msg_position == message.position
    /// - AIMessageType == STREAM_ANSWER  || AIMessageType == NOT_STREAM_ANSWER
    private func judgeCurrShowStatus(forRound round: AIRoundInfo) -> Bool {
        guard let myAIPageService = self.context.myAIPageService else { return false }
        // 1. 判断 Follow up FG
        guard myAIPageService.isFollowUpEnabled else { return false }
        // 2. 判断是否是最后一轮的最后一条消息
        //   - 主会场用 message.position 和 roundLastPosition 对比
        //   - 分会场用 message.threadPosition 和 roundLastPosition 对比
        if !myAIPageService.chatMode, metaModel.message.position != round.roundLastPosition { return false }
        if myAIPageService.chatMode, metaModel.message.threadPosition != round.roundLastPosition { return false }
        // 3. 是否已经回复完成
        guard round.status == .done else { return false }
        // 4. 判断消息类型属于 streamAnswer 或 notStreamAnswer
        return metaModel.message.aiMessageType == .notStreamAnswer || metaModel.message.aiMessageType == .streamAnswer
    }

    /// 上报快捷指令展示埋点
    private func reportQuickActionShownEvent(_ quickActions: [AIQuickActionModel]) {
        guard let pageService = context.myAIPageService as? MyAIPageServiceImpl else { return }
        pageService.quickActionTracker.reportQuickActionShownEvent(
            quickActions,
            roundId: String(pageService.aiRoundInfo.value.roundId),
            location: .followMessage,
            fromChat: metaModel.getChat(),
            extraParams: ["message_id": "\(self.metaModel.message.id)", "session_id": pageService.aiRoundInfo.value.sessionID ?? ""]
        )
    }
}
