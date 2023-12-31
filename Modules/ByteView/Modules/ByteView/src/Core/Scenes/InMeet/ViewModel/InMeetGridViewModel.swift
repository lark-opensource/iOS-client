//
//  InMeetGridViewModel.swift
//  ByteView
//
//  Created by kiri on 2021/5/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import ByteViewCommon
import ByteViewTracker
import ByteViewNetwork
import ByteViewSetting

// 首页单流操作视图相关的info
class GridViewManipulatorInfo {
    weak var manipulatorVC: ParticipantActionViewController?
    var sourcePoint: CGPoint = .zero
    var targetID: String = ""

    var isShowing: Bool {
        return manipulatorVC != nil
    }

    func dismiss() {
        guard isShowing else { return }
        if AlignPopoverManager.shared.showingVC == manipulatorVC {
            AlignPopoverManager.shared.dismiss(animated: false)
        } else {
            manipulatorVC?.dismiss(animated: false)
        }
    }
}

final class InMeetGridViewModel: InMeetMeetingProvider {
    static let logger = Logger.grid
    enum ContentDisplayMode: Equatable {
        case gridVideo
        case singleRowVideo
        case singleAudio
    }

    let meeting: InMeetMeeting
    let context: InMeetViewContext
    private let remainLimitListCount: Int = 50
    private let activeSpeakerViewModel: InMeetActiveSpeakerViewModel
    private lazy var logDescription = metadataDescription(of: self)
    private let gridDataSource: InMeetGridDataSource
    @RwAtomic
    var sortedGridViewModels: [InMeetGridCellViewModel] = [] {
        didSet { sortedVMsRelay.accept(sortedGridViewModels) }
    }

    // 自定义顺序相关
    let shouldGoToFirstPage: PublishSubject<Void> = PublishSubject<Void>()
    let shouldHideSingleVideo: PublishSubject<Void> = PublishSubject<Void>()
    let shouldCancelDragging: PublishSubject<Void> = PublishSubject<Void>()
    var alreadyShowOrderGuide = false
    let showReorderTagRelay = BehaviorRelay<Bool>(value: false)

    private let customOrderQueue = DispatchQueue(label: "lark.byteview.customOrder")
    private(set) var isGridDragging = false
    private(set) var isGridOrderSyncing = false {
        didSet {
            postGridUpdateEvent(.isGridOrderSyncing, context: isGridOrderSyncing)
        }
    }
    private var orderInfoFromServer: VideoChatDisplayOrderInfo?
    // 顺序同步状态下，主持人一次新的顺序变更操作后，点击撤销排序时，是否需要重新打开“隐藏自己”开关
    private var resetHideSelfOnUndoReorder = false
    // 参会人滑动列表到接近尾部时，发送一次拉去全量顺序的请求，使用该变量保证一次会议仅通过这种方式拉取一次
    private var hasFetchedAllOrderInfo = false

    var multiResolutionConfig: MultiResolutionConfig {
        meeting.setting.multiResolutionConfig
    }

    // 首页单流操作视图相关的info
    var gridViewManipulatorInfo: GridViewManipulatorInfo = GridViewManipulatorInfo()

    var httpClient: HttpClient { meeting.httpClient }
    var fullScreenDetector: InMeetFullScreenDetector? { context.fullScreenDetector }

    private lazy var selfIsHostRelay = BehaviorRelay<Bool>(value: meeting.myself.isHost)
    private lazy var isSelfSharingRelay = BehaviorRelay<Bool>(value: meeting.shareData.isSelfSharingContent)
    private let asSdkUidRelay = BehaviorRelay<RtcUID?>(value: nil)
    private let lastAsSdkUidRelay = BehaviorRelay<RtcUID?>(value: nil)

    let actionService: ParticipantActionService

    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.context = resolver.viewContext
        let activeSpeaker = resolver.resolve(InMeetActiveSpeakerViewModel.self)!
        self.activeSpeakerViewModel = activeSpeaker
        self.gridDataSource = InMeetGridDataSource(meeting: self.meeting,
                                                   context: self.context,
                                                   activeSpeakerViewModel: activeSpeaker, batteryManager: resolver.resolve()!)
        self.actionService = ParticipantActionService(meeting: meeting, context: context)
        Logger.ui.info("init \(logDescription)")

        activeSpeaker.addListener(self)
        gridDataSource.delegate = self
        gridDataSource.dataStore.addListener(self)
        meeting.data.addListener(self)
        meeting.shareData.addListener(self)
        meeting.participant.addListener(self)
        context.addListener(self, for: [.hideSelf, .hideNonVideoParticipants])
        meeting.push.inMeetingChange.addObserver(self)
        meeting.addMyselfListener(self)
    }

    deinit {
        Logger.ui.info("deinit \(logDescription)")
    }

    var meetingId: String { meeting.meetingId }
    var browserUserProfileEnable: Bool { meeting.setting.isBrowseUserProfileEnabled }

    // 本地为主持人，且正在同步顺序
    var isSyncingOthers: Bool {
        isGridOrderSyncing && meeting.myself.isHost
    }

    // 正在被主持人同步顺序
    var isSyncedByHost: Bool {
        isGridOrderSyncing && !meeting.myself.isHost
    }

    func postGridUpdateEvent(_ event: GridSortTrigger, context: Any) {
        gridDataSource.apply(event, with: context)
    }

    func endUsingCustomOrder(function: String = #function) {
        if isGridOrderSyncing {
            endSyncingGridOrder(function: function)
        }
        gridDataSource.endUsingCustomOrder(function: function)
        dismissResetOrderGuide()
    }

    // 获取全量顺序数据
    func fetchFullGridOrderIfNeeded(visibleIndex: Int) {
        customOrderQueue.async { [weak self] in
            // 剩余50以内开始拉全量
            guard let self = self, self.isSyncedByHost && !self.hasFetchedAllOrderInfo,
                    let orderInfo = self.orderInfoFromServer,
                  orderInfo.hasMore_p && orderInfo.orderList.count - visibleIndex < self.remainLimitListCount else { return }
            self.httpClient.send(GetVideoChatOrderRequest(meetingID: self.meeting.meetingId, needFullData: true))
            self.orderInfoFromServer = orderInfo
            Self.logger.info("fetch full custom order, visibleIndex: \(visibleIndex), currentOrderCount: \(orderInfo.orderList.count)")
        }
    }

    func beginDragging() {
        self.isGridDragging = true
        gridDataSource.beginUsingCustomOrder { [weak self] in
            self?.gridDataSource.apply(.isGridDragging, with: true)
        }
        Self.logger.info("Begin dragging")
    }

    func endDragging() {
        self.isGridDragging = false
        gridDataSource.apply(.isGridDragging, with: false)
        if !gridDataSource.isUsingCustomOrder {
            gridDataSource.forceRefresh()
        }
        Self.logger.info("End dragging")
    }

    var isUsingCustomOrder: Bool {
        gridDataSource.isUsingCustomOrder
    }

    func swapGridOrderAt(_ i: Int, _ j: Int) {
        gridDataSource.beginUsingCustomOrder { [weak self] in
            guard let self = self else { return }
            self.gridDataSource.apply(.reorder, with: GridReorderAction.swap(i: i, j: j))
            self.showResetOrderGuide()
        }
    }

    func moveGrid(from: Int, to: Int) {
        gridDataSource.apply(.reorder, with: GridReorderAction.move(from: from, to: to))
    }

    func beginSyncingGridOrder(syncToServer: Bool,
                               resetFirstPage: Bool,
                               becomeHost: Bool,
                               function: String = #function) {
        Self.logger.info("Begin syncing grid order from function \(function)")
        isGridOrderSyncing = true

        var waitSortResultBeforeSyncToServer = false
        if resetFirstPage {
            shouldGoToFirstPage.onNext(())
        }
        if meeting.myself.isHost {
            // 主持人同步顺序时，需要关闭隐藏本人、隐藏非视频开关
            waitSortResultBeforeSyncToServer = context.isSettingHideSelf || context.isSettingHideNonVideoParticipants
            Util.runInMainThread {
                if let text = self.tipForSyncingBegin(becomeHost: becomeHost) {
                    Toast.show(text)
                }
                self.context.isSettingHideSelf = false
                self.context.isSettingHideNonVideoParticipants = false
                // 隐藏自己或隐藏非视频开关被重置时，本端先将被隐藏的人按自定义顺序的规则排序，之后同步到服务端
                if waitSortResultBeforeSyncToServer && syncToServer {
                    DispatchQueue.global().async {
                        self.gridDataSource.refreshAndWait(forced: true)
                        self.syncOrderToServer()
                    }
                }
            }
        }

        if !waitSortResultBeforeSyncToServer && syncToServer {
            syncOrderToServer()
        }
    }

    func endSyncingGridOrder(function: String = #function) {
        if isSyncingOthers {
            unsyncOrderToServer()
        }
        isGridOrderSyncing = false
        showReorderTagRelay.accept(false)
        Self.logger.info("End syncing grid order from function \(function)")
    }

    func syncReorder() {
        resetHideSelfOnUndoReorder = false
        syncOrderToServer()
        shouldGoToFirstPage.onNext(())
        showReorderTagRelay.accept(false)
        Self.logger.info("Sync reorder")
    }

    func undoReorder() {
        customOrderQueue.async { [weak self] in
            guard let self = self, let orderInfo = self.orderInfoFromServer else { return }
            // 隐藏自己开关也要恢复
            if self.resetHideSelfOnUndoReorder {
                self.context.isSettingHideSelf = false
                self.resetHideSelfOnUndoReorder = false
            }
            self.useGridOrderFromServer(orderInfo.orderList, sharePosition: Int(orderInfo.shareStreamInsertPosition))
            self.showReorderTagRelay.accept(false)
            Self.logger.info("Undo reorder")
        }
    }

    func showReorderTagOnSyncing() {
        if isSyncingOthers {
            showReorderTagRelay.accept(true)
        }
    }

    func showCustomOrderGuide() {
        guard Display.pad
                && service.shouldShowGuide(.customOrder)
                && self.meeting.participant.activePanel.count > 1 else {
            return
        }
        let guide = GuideDescriptor(type: .customOrder,
                                    title: I18n.View_G_RearrangeVideoOrderOnboard,
                                    desc: I18n.View_G_RearrangeVideoOrderOnboardExplain)
        guide.animationName = "onboarding_customorder"
        guide.style = .alertWithAnimation
        guide.sureAction = { [weak self] in
            self?.service.didShowGuide(.customOrder)
            VCTracker.post(name: .vc_meeting_popup_click, params: ["click": "onboarding_ok",
                                                                   "content": "onboarding_set_video_order"])
        }
        GuideManager.shared.request(guide: guide)
        VCTracker.post(name: .vc_meeting_popup_view, params: ["content": "onboarding_set_video_order"])
    }

    func showResetOrderGuide() {
        guard Display.pad else { return }
        if service.shouldShowGuide(.resetOrder) {
            alreadyShowOrderGuide = true
            let guide = GuideDescriptor(type: .resetOrder, title: nil, desc: I18n.View_G_RevertToDefaultAndSyncHere)
            guide.style = .plain
            guide.sureAction = { [weak self] in
                self?.service.didShowGuide(.resetOrder)
            }
            GuideManager.shared.request(guide: guide)
            VCTracker.post(name: .vc_meeting_popup_view, params: ["content": "onboarding_reset_video_order"])
        } else if !alreadyShowOrderGuide {
            alreadyShowOrderGuide = true
            let guide = GuideDescriptor(type: .resetOrder, title: nil, desc: I18n.View_G_VideoOrderAdjusted)
            guide.style = .darkPlain
            GuideManager.shared.request(guide: guide)
        }
    }

    private func dismissResetOrderGuide() {
        guard Display.pad else { return }
        GuideManager.shared.dismissGuide(with: .resetOrder)
    }

    private func useGridOrderFromServer(_ order: [ByteviewUser], sharePosition: Int, refresh: Bool = true) {
        shouldCancelDragging.onNext(())
        gridDataSource.beginUsingCustomOrder { [weak self] in
            self?.gridDataSource.useGridOrderFromServer(order, sharePosition: sharePosition, refresh: refresh)
        }
    }

    private func asCellViewModel(for rtcUid: RtcUID?) -> InMeetGridCellViewModel? {
        guard let rtcUid = rtcUid else { return nil }
        let user = meeting.participant.find(rtcUid: rtcUid, in: .activePanels)?.user
        if let user = user {
            return gridDataSource.allGridViewModels[user]
        } else {
            return nil
        }
    }

    private func canAsVMShow(_ asVM: InMeetGridCellViewModel) -> Bool {
        guard context.isHideNonVideoParticipants else { return true }
        let participant = asVM.participant.value
        let isWebinarAttendeeMuted = participant.settings.isMicrophoneMutedOrUnavailable && participant.meetingRole == .webinarAttendee
        return !isWebinarAttendeeMuted
    }

    private func handleOrderInfo(_ orderInfo: VideoChatDisplayOrderInfo, oldValue: VideoChatDisplayOrderInfo?) {
        // Webinar 不同步联席主持人、嘉宾的顺序
        if meeting.subType == .webinar && (meeting.myself.isCoHost || meeting.myself.meetingRole == .participant) {
            return
        }

        let isHost = meeting.myself.isHost

        switch orderInfo.action {
        case .videoChatOrderSync:
            Self.logger.info("Received synced order, isHost = \(isHost), " +
                             "oldValue.hasMore = \(oldValue?.hasMore_p), " +
                             "newValue.hasMore = \(orderInfo.hasMore_p), " +
                             "isGridOrderSyncing = \(isGridOrderSyncing)")
            if isHost {
                if let oldValue = oldValue, oldValue.hasMore_p && !orderInfo.hasMore_p {
                    // 主持人响应全量 sync
                    useGridOrderFromServer(orderInfo.orderList, sharePosition: Int(orderInfo.shareStreamInsertPosition))
                } else if !isGridOrderSyncing {
                    // 收到服务端 sync 推送时，不管是否全量，只要主持人本端还没在 sync 状态，就应用服务端推送
                    useGridOrderFromServer(orderInfo.orderList, sharePosition: Int(orderInfo.shareStreamInsertPosition))
                }
            } else {
                if !isGridOrderSyncing {
                    // 未被同步 -> 被同步
                    if !self.isWebinar {
                        Toast.show(I18n.View_G_HostSyncedOrderToast)
                    }
                    self.shouldGoToFirstPage.onNext(())
                    self.shouldHideSingleVideo.onNext(())
                } else if let oldValue = oldValue, oldValue.hostSyncSeqID < orderInfo.hostSyncSeqID {
                    // 主持人更新同步。hostSyncSeqID 增加说明主持人又点了一次同步，参会人才需要回到首屏
                    self.shouldGoToFirstPage.onNext(())
                    self.shouldHideSingleVideo.onNext(())
                }
                useGridOrderFromServer(orderInfo.orderList, sharePosition: Int(orderInfo.shareStreamInsertPosition))
            }
            isGridOrderSyncing = true
        case .videoChatOrderUnsync:
            guard isGridOrderSyncing else { return }
            if isHost {
                isGridOrderSyncing = false
                showReorderTagRelay.accept(false)
            } else {
                if !isWebinar {
                    Toast.show(I18n.View_G_StoppedSyncingRevertToast)
                }
                endUsingCustomOrder()
            }
        default:
            break
        }
    }

    private func syncOrderToServer() {
        let shareIndex = sortedGridViewModels.firstIndex(where: { $0.type == .share }) ?? 1
        let participants = sortedGridViewModels.filter({ $0.type == .participant }).map { $0.pid }
        let orderInfo = VideoChatDisplayOrderInfo(action: .videoChatOrderSync, orderList: participants, shareStreamInsertPosition: Int32(shareIndex))
        var request = HostManageRequest(action: .adjustVideochatOrder, meetingId: meeting.meetingId)
        request.videoChatDisplayOrderInfo = orderInfo
        httpClient.send(request)
    }

    private func unsyncOrderToServer() {
        let orderInfo = VideoChatDisplayOrderInfo(action: .videoChatOrderUnsync, orderList: [], shareStreamInsertPosition: 1)
        var request = HostManageRequest(action: .adjustVideochatOrder, meetingId: meeting.meetingId)
        request.videoChatDisplayOrderInfo = orderInfo
        httpClient.send(request)
    }

    private func handleMeetingRoleChanged(newRole: Participant.MeetingRole, oldRole: Participant.MeetingRole) {
        customOrderQueue.async { [weak self] in
            guard let self = self, newRole != oldRole else { return }
            switch (oldRole, newRole) {
            case (_, .host): self.becomeHost()
            case (.host, _): self.withdrawHost()
            default: break
            }
        }
    }

    private func becomeHost() {
        guard let orderInfo = orderInfoFromServer, orderInfo.action == .videoChatOrderSync else { return }
        // FG关闭的参会人或手机用户成为主持人并且当时正在同步，主动结束同步
        guard !Display.phone else {
            Self.logger.info("Become host but do not support custom order. End syncing and custom ordering. orderInfoFromServer.action = \(orderInfoFromServer?.action)")
            endUsingCustomOrder()
            return
        }

        if isWebinar {
            useGridOrderFromServer(orderInfo.orderList, sharePosition: Int(orderInfo.shareStreamInsertPosition))
        }

        // 主动拉取一次全量
        httpClient.send(GetVideoChatOrderRequest(meetingID: meeting.meetingId, needFullData: true))
        beginSyncingGridOrder(syncToServer: false, resetFirstPage: false, becomeHost: true)
    }

    private func withdrawHost() {
        if isGridOrderSyncing {
            if isWebinar && !isWebinarAttendee {
                // webinar会议 主持人->嘉宾，仅取消本地同步状态，顺序不变
                isGridOrderSyncing = false
                Self.logger.info("Withdraw host, set isGridOrderSyncing to false")
            } else if let orderInfo = orderInfoFromServer, orderInfo.action == .videoChatOrderSync {
                // 普通会议，如果当前在同步，则用最新的服务端顺序来覆盖本地顺序
                useGridOrderFromServer(orderInfo.orderList, sharePosition: Int(orderInfo.shareStreamInsertPosition))
                Self.logger.info("Withdraw host, use the latest order from server")
            }
        }
        showReorderTagRelay.accept(false)
    }

    /// 开始同步顺序时，如果自己是主持人，且开启了隐藏非视频/隐藏本人，则根据情况返回提示给用户的 toast 文案
    /// becomeHost: 是否是因为自己被转移为主持人而开始的同步，上一个主持人正在同步顺序且自己被转为主持人时为 true
    private func tipForSyncingBegin(becomeHost: Bool) -> String? {
        switch (context.isSettingHideSelf, context.isSettingHideNonVideoParticipants) {
        case (true, true):
            return isWebinar ? I18n.View_G_SyncedOrderCancelHideViewsWeb : I18n.View_G_SyncedOrderCancelHideViews
        case (true, false):
            return isWebinar ? I18n.View_G_SyncedOrderCancelHideOwnWeb : I18n.View_G_SyncedOrderCancelHideOwn
        case (false, true):
            return isWebinar ? I18n.View_G_SyncedOrderCancelHideWeb : I18n.View_G_SyncedOrderCancelHide
        case (false, false):
            if becomeHost {
                return isWebinar ? I18n.View_G_HostSyncingForAllAttend : nil
            } else {
                return isWebinar ? I18n.View_G_SyncOrderAttendeeToast : I18n.View_G_YouHaveSyncedToast
            }
        }
    }

    private func updateServerOrdersWhenParticipantsLeave(_ output: InMeetParticipantOutput) {
        guard gridDataSource.isUsingCustomOrder, var orderInfo = orderInfoFromServer else { return }
        let nonRingingRemoves = output.modify.nonRinging.removes
        let ringingRemoves = output.modify.ringing.removes
        orderInfo.orderList.removeAll(where: { nonRingingRemoves[$0] != nil || ringingRemoves[$0] != nil })
        orderInfoFromServer = orderInfo
        useGridOrderFromServer(orderInfo.orderList, sharePosition: Int(orderInfo.shareStreamInsertPosition), refresh: false)
    }

    // MARK: - Output

    // 从参会人列表中搜索as，因此无论是否隐藏自己、都能找到自己
    var asParticipantViewModel: Observable<InMeetGridCellViewModel?> {
        asSdkUidRelay.asObservable().map { [weak self] in self?.asCellViewModel(for: $0) }
    }

    func newSingleVideoViewModel(pid: ByteviewUser) -> SingleVideoViewModel? {
        guard let gridVM = self.gridDataSource.allGridViewModels[pid] else { return nil }
        let vm = SingleVideoViewModel(meeting: meeting, context: context, gridVM: gridVM)
        return vm
    }

    var shrinkViewSpeakingUser: Observable<(speakingUserName: String?, showFocusPrefix: Bool)> {
        let meetingId = self.meetingId
        let participantService = meeting.httpClient.participantService
        return Observable.combineLatest(asParticipantViewModel,
                                        focusingPidRelay.asObservable(),
                                        selfIsHostRelay.asObservable(),
                                        isSelfSharingRelay.asObservable())
                .distinctUntilChanged({ $0 == $1 })
                .flatMapLatest { (asVM: InMeetGridCellViewModel?, focusingUser: ByteviewUser?, selfIsHost: Bool, isSelfSharingContent: Bool) -> Observable<(speakingUserName: String?, showFocusPrefix: Bool)> in
                    let targetID: ByteviewUser
                    let showFocusPrefix: Bool
                    if let id = focusingUser, !selfIsHost, !isSelfSharingContent {
                        targetID = id
                        showFocusPrefix = true
                    } else if let id = asVM?.pid {
                        targetID = id
                        showFocusPrefix = false
                    } else {
                        return .just((nil, false))
                    }
                    return Observable.create({ o -> Disposable in
                        participantService.participantInfo(pid: targetID, meetingId: meetingId, completion: { ap in
                            o.onNext((ap.name, showFocusPrefix))
                            o.onCompleted()
                        })
                        return Disposables.create()
                    })
                }
    }

    func singleGridViewModel(asIncludeLocal: Bool) -> Observable<InMeetGridCellViewModel> {
        let selfSdkUid = meeting.myself.rtcUid
        let selfByteviewUser = meeting.account
        return Observable.combineLatest(sortedVMsRelay.asObservable(),
                                        lastAsSdkUidRelay.asObservable(),
                                        focusingPidRelay.asObservable())
                .filterFlatMap(transform: { [weak self] sortedVMs, asSDKUID, focusPid -> InMeetGridCellViewModel? in
                    guard let self = self else { return nil }

                    if let focusPid = focusPid, let focusVM = self.gridDataSource.allGridViewModels[focusPid] {
                        // 焦点视频存在时，不考虑 AS 逻辑，直接返回焦点视频
                        return focusVM
                    } else if asIncludeLocal || asSDKUID != selfSdkUid, let asVM = self.asCellViewModel(for: asSDKUID), self.canAsVMShow(asVM) {
                        // 当前讲话的人更新，返回最新的 AS，依据参数决定自己是否可以作为 AS 返回
                        return asVM
                    } else if asIncludeLocal || self.activeSpeakerViewModel.secondLastActiveSpeaker != selfSdkUid, let lastAsVM = self.asCellViewModel(for: self.activeSpeakerViewModel.secondLastActiveSpeaker), self.canAsVMShow(lastAsVM) {
                        // 会中存在过 AS 后，若无人讲话，返回上一个 AS，依据参数决定自己是否可以作为 AS 返回。
                        return lastAsVM
                    }

                    // 默认返回会中除本地外分数最高的人，例如初始没人说话；或者展示上一个 AS 时，上一个 AS 离会。
                    return sortedVMs.first { $0.pid != selfByteviewUser && $0.type == .participant } ?? self.localGridCellViewModel
                })
    }

    var localGridCellViewModel: InMeetGridCellViewModel? {
        gridDataSource.allGridViewModels[meeting.myself.user]
    }

    let sortedVMsRelay = BehaviorRelay<[InMeetGridCellViewModel]>(value: [])

    lazy var isHideNonVideoParticipants = BehaviorRelay<Bool>(value: context.isHideNonVideoParticipants)

    let focusingPidRelay = BehaviorRelay<ByteviewUser?>(value: nil)

    lazy var isUsingCustomOrderRelay = BehaviorRelay<Bool>(value: isUsingCustomOrder)

    let allGridViewModels = BehaviorRelay<[ByteviewUser: InMeetGridCellViewModel]>(value: [:])
}

extension InMeetGridViewModel: InMeetGridParticipantStoreDelegate {
    func activeSpeakerInfoDidChange(asInfos: [ActiveSpeakerInfo], currentActiveSpeaker: ByteviewUser?) {
    }

    func allGridViewModelsDidChange(_ viewModels: [ByteviewUser: InMeetGridCellViewModel]) {
        allGridViewModels.accept(viewModels)
    }
}

extension InMeetGridViewModel: InMeetDataListener {
    func didChangeInMeetingInfo(_ info: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        // 开启讨论组，取消顺序同步，目前 iPad 不能开启分组讨论，所以下面的逻辑不会执行
        if isSyncingOthers && meeting.data.isOpenBreakoutRoom {
            endSyncingGridOrder()
            Toast.show(I18n.View_G_StoppedSyncingToast)
        }
    }

    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        guard !isWebinarAttendee else { return }
        updateServerOrdersWhenParticipantsLeave(output)
    }

    func didChangeWebinarAttendees(_ output: InMeetParticipantOutput) {
        guard isWebinar && !isWebinarAttendee else { return }
        updateServerOrdersWhenParticipantsLeave(output)
    }

    func didChangeWebinarParticipantForAttendee(_ output: InMeetParticipantOutput) {
        guard isWebinarAttendee else { return }
        updateServerOrdersWhenParticipantsLeave(output)
    }
}

extension InMeetGridViewModel: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if change == .hideSelf, let isHide = userInfo as? Bool, isHide {
            if isSyncingOthers {
                resetHideSelfOnUndoReorder = true
                // 产品需求：当且仅当开启「隐藏本人」后，customOrder 实际发生变化才 showReorderTag
                // 当且仅当自己在当前顺序的最后一位时，开启隐藏本人不会使实际顺序发生变化
                if let last = sortedGridViewModels.last, last.pid != meeting.myself.user {
                    showReorderTagOnSyncing()
                }
            }
        } else if change == .hideNonVideoParticipants, let isHide = userInfo as? Bool {
            isHideNonVideoParticipants.accept(isHide)
        }
    }
}

extension InMeetGridViewModel: InMeetShareDataListener {
    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        isSelfSharingRelay.accept(newScene.isSelfSharingContent(with: meeting.account))
    }
}

extension InMeetGridViewModel: InMeetActiveSpeakerListener {
    func didChangeActiveSpeaker(_ rtcUid: RtcUID?, oldValue: RtcUID?) {
        asSdkUidRelay.accept(rtcUid)
    }

    func didChangeLastActiveSpeaker(_ rtcUid: RtcUID, oldValue: RtcUID?) {
        lastAsSdkUidRelay.accept(rtcUid)
    }
}

extension InMeetGridViewModel: InMeetGridDataSourceListener {
    func sortResultDidChange(_ sortedParticipants: [InMeetGridCellViewModel]) {
        self.sortedGridViewModels = sortedParticipants
    }

    func sorterDidChange() {
        isUsingCustomOrderRelay.accept(isUsingCustomOrder)
    }
}

extension InMeetGridViewModel: InMeetingChangedInfoPushObserver {
    func didReceiveInMeetingChangedInfo(_ data: InMeetingData) {
        customOrderQueue.async { [weak self] in
            guard let self = self, data.type == .videoChatOrderInfo, let orderInfo = data.videoChatDisplayOrderInfo, orderInfo.action != .videoChatOrderUnknown else { return }
            Self.logger.info("Receive videoChatDisplayOrderInfo: \(orderInfo)")
            let oldValue = self.orderInfoFromServer
            // 无论推送数据是否需要被处理，均保存一份以备用
            self.orderInfoFromServer = orderInfo

            self.handleOrderInfo(orderInfo, oldValue: oldValue)
        }
    }
}

extension InMeetGridViewModel: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        selfIsHostRelay.accept(myself.isHost)
        guard let oldValue = oldValue else { return }
        // 身份变化
        handleMeetingRoleChanged(newRole: myself.meetingRole, oldRole: oldValue.meetingRole)

        // 切换讨论组，结束自定义顺序
        if myself.breakoutRoomId != oldValue.breakoutRoomId {
            endUsingCustomOrder()
            shouldCancelDragging.onNext(())
        }
    }
}

extension InMeetGridViewModel: InMeetParticipantListener {
    func didChangeFocusingParticipant(_ participant: Participant?, oldValue: Participant?) {
        focusingPidRelay.accept(participant?.user)

        guard participant != nil else { return }

        // 进入焦点视频取消自定义顺序
        endUsingCustomOrder()

        // 本端为主持人或主共享人时，设置焦点视频时需要回首屏
        let isHostOrSharer = meeting.myself.isHost || meeting.shareData.isSelfSharingContent
        if participant != oldValue && isHostOrSharer {
            shouldGoToFirstPage.onNext(())
        }
    }
}

// webinar
extension InMeetGridViewModel {

    // 是否为Webinar会议
    var isWebinar: Bool {
        meeting.subType == .webinar
    }

    // 是否是观众
    var isWebinarAttendee: Bool {
        isWebinar && meeting.isWebinarAttendee
    }
}
