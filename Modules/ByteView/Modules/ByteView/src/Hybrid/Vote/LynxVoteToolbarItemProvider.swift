//
// Created by maozhixiang.lip on 2022/10/14.
//

import Foundation
import UniverseDesignIcon
import ByteViewHybrid
import ByteViewNetwork
import ByteViewTracker
import ByteViewMeeting
import UniverseDesignToast
import ByteViewSetting
import ByteViewUI

final class LynxVoteToolbarItemProvider: InMeetVoteViewModelProvider {
    private let meeting: InMeetMeeting
    private var guideShown: [String: Bool] = [:]
    private var canShowVote = true
    private var prevInMeetingDataVote: VoteStatisticInfo?
    private var listeners = Listeners<LynxVoteViewModelListener>()
    private var prevPanelVoteID: String?
    private weak var prevPanel: UIViewController?
    private var meetingRole: Participant.MeetingRole
    private(set) var votes: [VoteStatisticInfo]

    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        self.meetingRole = meeting.myself.meetingRole
        self.votes = meeting.data.inMeetingInfo?.voteList ?? []
        meeting.addMyselfListener(self, fireImmediately: true)
        meeting.push.combinedInfo.addObserver(self)
        meeting.push.inMeetingChange.addObserver(self)
        meeting.router.addListener(self)
        meeting.webinarManager?.addListener(self)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    func setCanShowVote(_ canShowVote: Bool) {
        if self.canShowVote == canShowVote { return }
        self.canShowVote = canShowVote
        if canShowVote {
            self.tryToShowPreviousActionPanel()
        }
    }

    @objc private func applicationDidBecomeActive(_ notification: Notification) {
        self.tryToShowPreviousActionPanel()
    }

    private func tryToShowPreviousActionPanel() {
        Util.runInMainThread { [weak self] in
            if let vote = self?.prevInMeetingDataVote {
                self?.tryToShowActionPanel(vote)
            }
        }
    }

    // 以下情况弹ActionPanel：
    // 1. 收到非自己创建的未参投的进行中的投票
    // 2. 收到主持人发送的投票提醒
    // 3. 收到公布投票结果的投票
    // 4. 入会时已有非自己创建的未参投的进行中的投票，且会中无本人其它设备
    private func tryToShowActionPanel(_ vote: VoteStatisticInfo) {
        guard self.canShowVote else { return }
        guard self.meeting.setting.canVote else { return }
        guard self.meeting.myself.user.id != vote.operatorUid else { return }
        guard vote.dataSubType != .meetingVoteRejoin || self.meeting.participant.duplicatedParticipant == nil else { return }
        let ongoingNotVotedVotes = [vote]
            .filter { $0.voteInfo?.voteStatus == VoteStatus.publish }
            .filter { $0.chooseStatus == ChooseStatus.unknownChoose }
        let newVotes = ongoingNotVotedVotes
            .filter { $0.dataSubType == .meetingVoteJoin }
        let otherOngoingVotes = ongoingNotVotedVotes
            .filter { $0.dataSubType == .meetingVoteRejoin || $0.dataSubType == .meetingVoteJoinNotice }
        let publishedVotes = [vote]
            .filter { $0.dataSubType == .meetingVoteSetting }
            .filter { $0.voteInfo?.voteStatus == VoteStatus.close }
            .filter { $0.voteInfo?.setting?.voteStatPublish ?? false }
        guard [newVotes, otherOngoingVotes, publishedVotes].flatMap({ $0 }).first != nil else { return }
        if UIApplication.shared.applicationState != .active {
            addLocalNotification(with: vote) // 应用在后台推系统消息
            return
        }
        if meeting.router.isFloating {
            showToastWhenFloating(with: vote)  // VC在小窗弹Toast
            return
        }
        guard let voteID = vote.voteInfo?.voteID else { return }
        self.showPanelPage(voteID: voteID)
        self.prevInMeetingDataVote = nil
    }

    func showVotePage() {
        rotateToPortraitIfNeeded { [weak self] in
            guard let self = self else { return }
            let vc = LynxManager.shared.createVoteIndexPage(vm: self)
            self.meeting.router.presentDynamicModal(vc,
                                                    regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                                    compactConfig: .init(presentationStyle: .fullScreen, needNavigation: true))
        }
    }

    func showPanelPage(voteID: String) {
        if let prevPanel = self.prevPanel {
            if voteID == self.prevPanelVoteID {
                Logger.vote.warn("vote panel already shown, voteID = \(voteID)")
                return
            }
            prevPanel.dismiss(animated: false)
        }
        rotateToPortraitIfNeeded { [weak self] in
            guard let self = self else { return }
            Logger.vote.info("show vote panel, voteID = \(voteID)")
            let vc = LynxManager.shared.createVotePanelPage(vm: self, voteID: voteID)
            let config = DynamicModalConfig(presentationStyle: .overFullScreen,
                                            backgroundColor: UIColor.ud.vcTokenMeetingFillMask,
                                            needNavigation: true)
            self.meeting.router.presentDynamicModal(vc, regularConfig: config, compactConfig: config)
            self.prevPanel = vc
            self.prevPanelVoteID = voteID
        }
    }

    private func rotateToPortraitIfNeeded(completion: (() -> Void)? = nil) {
        // disable-lint: magic number
        if Display.phone && UIApplication.shared.statusBarOrientation.isLandscape {
            // 横屏时直接打开lynx页面很可能发生页面布局异常，需要强转后async再加载lynx
            UIDevice.updateDeviceOrientationForViewScene(nil, to: .portrait, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion?()
            }
        } else {
            completion?()
        }
        // enable-lint: magic number
    }

    private func toastContent(of vote: VoteStatisticInfo) -> String {
        switch vote.dataSubType {
        case .meetingVoteJoinNotice:
            return I18n.View_G_HostRemindVote
        case .meetingVoteSetting:
            return I18n.View_G_HostAnnouncedPoll
        default:
            return I18n.View_G_HostCreatedPoll
        }
    }

    private func addLocalNotification(with vote: VoteStatisticInfo) {
        guard let voteID = vote.voteInfo?.voteID else { return }
        let notificationID = UUID().uuidString
        let body = self.toastContent(of: vote)
        UNUserNotificationCenter.current().addLocalNotification(withIdentifier: notificationID,
                                                                body: body, userInfo: ["voteID": voteID])
    }

    private func showToastWhenFloating(with vote: VoteStatisticInfo) {
        guard vote.voteInfo?.voteID != nil else { return }
        let toastContent = self.toastContent(of: vote)
        let operation = UDToastOperationConfig(text: I18n.View_G_ViewClick)
        let config = UDToastConfig(toastType: .info, text: toastContent, operation: operation, delay: 5)
        self.meeting.larkRouter.activeWithTopMost { [weak self] vc in
            UDToast.showToast(
                with: config,
                on: vc.view,
                delay: config.delay,
                operationCallBack: { _ in
                    self?.meeting.router.setWindowFloating(false)
                }
            )
        }
    }

    // webinarRole转场后，尝试弹出历史投票。转场过程中弹投票可能存在以下问题，所以需要延迟到转场完成：
    //    1. LynxVoteToolbarItemProvider初始化时机晚于changedInfo推送，因此投票更新大概率被丢弃，需要之后用inMeetingInfo里的数据
    //    2. 转场过程中InMeetContainerViewController还未展示，直接present会报错
    private func tryToShowVoteAfterWebinarTransition() {
        guard let manager = self.meeting.webinarManager, !manager.isTransitioning else {
            return
        }
        self.votes.forEach {
            self.tryToShowActionPanel($0)
        }
    }
}

extension LynxVoteToolbarItemProvider: LynxVoteViewModel {
    var httpClient: HttpClient { meeting.httpClient }

    var scene: LynxSceneInfo {
        guard Thread.isMainThread else { return .unknown }
        return .init(isRegular: VCScene.isRegular, size: VCScene.bounds.size)
    }

    var lynxMeeting: LynxMeetingInfo {
        LynxMeetingInfo(meetingID: self.meeting.meetingId, meetingSubType: self.meeting.subType,
                        myself: .init(user: self.meeting.myself.user, role: self.meeting.myself.meetingRole))
    }

    func showToast(_ content: String, icon: LynxToastIconType?, duration: TimeInterval?) {
        if let icon = icon, let iconType = VCToastType.init(rawValue: icon.rawValue) {
            Toast.show(content, type: iconType, duration: duration)
        } else {
            Toast.show(content, duration: duration)
        }
    }

    func showToolbarGuide(type: String, content: String) {
        guard !(self.guideShown[type] ?? false) else { return }
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            guard let guideType = GuideType.init(rawValue: type) else { return }
            let guide = GuideDescriptor(type: guideType, title: nil, desc: content)
            guide.style = .darkPlain
            guide.sureAction = { [weak self] in self?.guideShown[type] = true }
            guide.duration = 3
            GuideManager.shared.request(guide: guide)
        }
    }

    func showUserProfile(uid: String) {
        InMeetUserProfileAction.show(userId: uid, meeting: self.meeting)
    }

    func present(_ vc: UIViewController, regularConfig: DynamicModalConfig, compactConfig: DynamicModalConfig) {
        meeting.router.presentDynamicModal(vc, regularConfig: regularConfig, compactConfig: compactConfig)
    }

    func addListener(_ listener: LynxVoteViewModelListener) {
        self.listeners.addListener(listener)
    }
}

extension LynxVoteToolbarItemProvider: VideoChatCombinedInfoPushObserver {
    func didReceiveCombinedInfo(inMeetingInfo: VideoChatInMeetingInfo, calendarInfo: CalendarInfo?) {
        if inMeetingInfo.voteList != self.votes {
            self.votes = inMeetingInfo.voteList
            self.listeners.forEach { $0.votesDidChange(self.votes) }
        }
    }
}

extension LynxVoteToolbarItemProvider: InMeetingChangedInfoPushObserver {
    func didReceiveInMeetingChangedInfo(_ data: InMeetingData) {
        guard data.type == .meetingVote else { return }
        guard let vote = data.voteStatistic else { return }
        Logger.vote.info("vote updated, \(vote)")
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            // 小窗回大窗时，依赖 self.prevInMeetingDataVote.dataSubType == .meetingVoteJoin 来决定是否弹出投票
            // 当本端为主持人时，会依次收到meetingVoteJoin、meetingVoteTotalNum两个推送，若后者覆盖前者，则回到大窗时无法弹出投票
            // 因此针对这种case，要避免meetingVoteJoin被覆盖
            if self.meeting.router.isFloating, self.meetingRole == .host,
               let prevVote = self.prevInMeetingDataVote, prevVote.dataSubType == .meetingVoteJoin,
               vote.dataSubType == .meetingVoteTotalNum, vote.voteInfo?.voteID == prevVote.voteInfo?.voteID,
               (prevVote.version ?? 0) + 1 == vote.version ?? 0 {
                return
            }
            self.prevInMeetingDataVote = vote
            self.tryToShowActionPanel(vote)
        }
    }
}

extension LynxVoteToolbarItemProvider: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        guard myself.meetingRole != self.meetingRole else { return }
        self.meetingRole = myself.meetingRole
        self.listeners.forEach { $0.meetingDidChange(self.lynxMeeting) }
    }
}

extension LynxVoteToolbarItemProvider: RouterListener {
    func didChangeWindowFloatingAfterAnimation(_ isFloating: Bool, window: FloatingWindow?) {
        if !isFloating {
            self.tryToShowPreviousActionPanel()
        }
    }
}

extension LynxVoteToolbarItemProvider: WebinarRoleListener {
    func webinarDidChangeTransitionState(isTransitioning: Bool) {
        if !isTransitioning {
            self.tryToShowVoteAfterWebinarTransition()
        }
    }
}

private extension Logger {
    static let vote = getLogger("LynxVote")
}
