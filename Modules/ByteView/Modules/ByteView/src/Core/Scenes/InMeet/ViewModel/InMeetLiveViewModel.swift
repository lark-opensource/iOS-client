//
//  InMeetLiveViewModel.swift
//  ByteView
//
//  Created by kiri on 2021/5/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI

enum ByteLiveUnavailableType: Equatable {
    case none
    case inactive
    case versionExpired
    case packageExpired
    case noAppPermission
    case needCreateSubAccount
}

class LiveProviderAvailableStatus {
    init(response: GetLiveProviderInfoResponse?) {
        self.response = response
    }

    var byteLiveUnAvailableType: ByteLiveUnavailableType = .none
    var isLarkLiveAvailable: Bool = false
    var isByteLiveAvailable: Bool = false
    var isProviderByteLive: Bool = false
    var isByteLiveCreatorSameWithUser: Bool = true
    var response: GetLiveProviderInfoResponse?
}

typealias LiveMeetingData = InMeetingData.LiveMeetingData
final class InMeetLiveViewModel: InMeetingChangedInfoPushObserver, VideoChatExtraInfoPushObserver, InMeetDataListener, InMeetParticipantListener, InMeetMeetingProvider {
    static let logger = Logger.ui
    let disposeBag = DisposeBag()
    let meeting: InMeetMeeting
    var votingDispose: DisposeBag?
    var isShowingLivingRequest: Bool = false

    private var lastNonIdleCount = 0
    private let isEnableStartRelay = BehaviorRelay(value: true)
    private let liveInfoRelay = BehaviorRelay<LiveInfo?>(value: nil)
    private let liveChangedDataSubject = PublishSubject<LiveMeetingData>()
    private(set) var liveUsersCount = 0
    private let liveUsersCountRelay = BehaviorRelay<Int>(value: 0)
    private lazy var liveMeetingDataSubject = ReplaySubject<LiveMeetingData>.create(bufferSize: 1)
    var liveInfo: LiveInfo? {
        liveInfoRelay.value
    }
    var liveProviderStatus: LiveProviderAvailableStatus?
    private(set) lazy var liveInfoObservable: Observable<LiveInfo?> = liveInfoRelay.asObservable()
    private(set) lazy var liveChangedDataObservable: Observable<LiveMeetingData> = liveChangedDataSubject.asObservable()
    private(set) lazy var isLiveObservable: Observable<Bool> = liveInfoObservable.map { $0?.isLiving ?? false }
    private(set) lazy var liveUsersCountObservable = liveUsersCountRelay.asObservable()
    private(set) lazy var liveMeetingDataObservable = liveMeetingDataSubject.asObservable()

    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        meeting.push.inMeetingChange.addObserver(self)
        meeting.push.extraInfo.addObserver(self)
        meeting.data.addListener(self)
        meeting.participant.addListener(self)
        meeting.router.addListener(self)

        DispatchQueue.global().async { [weak self] in
            self?.bindRx()
        }
    }

    private func bindRx() {
        handleAskingLiveToast()
        bindShowVoting()
        let delayTime: Int = 30
        isEnableStartRelay.flatMapLatest { isEnable -> Observable<Bool> in
            if !isEnable {
                return Observable.just(true).delay(.seconds(delayTime), scheduler: MainScheduler.instance)
            } else {
                return .empty()
            }
        }.bind(onNext: isEnableStartRelay.accept)
            .disposed(by: disposeBag)

        // 直播状态变更
        isLiveObservable.distinctUntilChanged().subscribe(onNext: { isOn in
            Self.logger.info("Live status changed: \(isOn)")
        }).disposed(by: disposeBag)

    }

    var meetingId: String { meeting.meetingId }

    var isLiving: Bool {
        return liveInfo?.isLiving ?? false
    }

    var isEnableStartLive: Observable<Bool> {
        return isEnableStartRelay.asObservable()
    }

    /// (isVoting, sponsorID)
    var isVoting: Observable<(Bool, String)> {
        return liveInfoObservable.flatMap { info -> Observable<(Bool, String)> in
            guard let info = info, let vote = info.liveVote else {
                return .empty()
            }
            return .just((vote.isVoting, vote.sponsorID))
        }
        .startWith((false, ""))
        .distinctUntilChanged { $0.0 == $1.0 && $0.1 == $1.1 }
    }

    var isShowVotingRefuse: Observable<Bool> {
        return liveInfoObservable.flatMap { info -> Observable<LiveVote> in
            guard let vote = info?.liveVote else {
                return .empty()
            }
            return .just(vote)
        }
        .map { !$0.isVoting && $0.reason == .refused }
        .takeUntil(false)
        .distinctUntilChanged()
    }

    func updateLiveAction(action: UpdateLiveAction,
                          user: ByteviewUser?,
                          voteID: String?,
                          privilege: LivePrivilege?,
                          enableChat: Bool?,
                          enablePlayback: Bool?,
                          layout: LiveLayout?,
                          member: [LivePermissionMember]?) -> Completable {
        guard let isProviderByteLive = self.liveProviderStatus?.isProviderByteLive else { return .empty() }
        let larkOnlyActions: [UpdateLiveAction] = [.voteAccept, .voteRefuse]

        if !isProviderByteLive
            || larkOnlyActions.contains(action) {
            return self.updateLarkLiveAction(action: action, user: user, voteID: voteID, privilege: privilege, enableChat: enableChat, enablePlayback: enablePlayback, layout: layout, member: member)
        }

        let byteLiveAction = UpdateLiveActionByteLive(action: action)
        var livePermission: LivePermissionByteLive?
        if let privilege = privilege {
            livePermission = LivePermissionByteLive(lp: privilege)
        }
        let byteLiveMember = member?.map({ larkMember in
            return LivePermissionMemberByteLive(larkMember: larkMember)
        })
        return self.updateByteLiveAction(action: byteLiveAction, user: user, livePermission: livePermission, enableChat: enableChat, layout: layout, member: byteLiveMember)
    }

    func updateByteLiveAction(action: UpdateLiveActionByteLive,
                              user: ByteviewUser?,
                              livePermission: LivePermissionByteLive?,
                              enableChat: Bool?,
                              layout: LiveLayout?,
                              member: [LivePermissionMemberByteLive]?) -> Completable {
        var request = VideoChatLiveActionByteLiveRequest(meetingId: meetingId, action: action)
        request.requester = user
        request.livePermission = livePermission
        request.layoutStyle = layout
        request.enableLiveComment = enableChat
        request.members = member
        let httpClient = meeting.httpClient
        return RxTransform.completable {
            httpClient.send(request, completion: $0)
        }.do(onError: { Self.logger.error("updateByteLiveAction error: \($0)") },
             onCompleted: { Self.logger.error("updateByteLiveAction success") })
    }

    func updateLarkLiveAction(action: UpdateLiveAction,
                              user: ByteviewUser?,
                              voteID: String?,
                              privilege: LivePrivilege?,
                              enableChat: Bool?,
                              enablePlayback: Bool?,
                              layout: LiveLayout?,
                              member: [LivePermissionMember]?) -> Completable {
        let meetingId = self.meetingId
        var request = LiveActionRequest(meetingId: meetingId, action: action)
        request.requester = user
        request.voteId = voteID
        request.privilege = privilege
        request.enableLiveComment = enableChat
        request.enablePlayback = enablePlayback
        request.layoutStyle = layout
        request.members = member
        let httpClient = meeting.httpClient
        let response: Completable = RxTransform.completable {
            httpClient.send(request, completion: $0)
        }.do(onError: { [weak self] error in
            if action == .participantRequestStart {
                self?.isEnableStartRelay.accept(true)
            }

            guard action == .start || action == .stop else {
                return
            }
            let isStartLive = action == .start
            if let error = error as? RustBizError {
                MeetingTracksV2.trackStartLiveFail(meetingId: meetingId, isStart: isStartLive, errorCode: error.code, errorDescription: error.displayMessage)
            } else {
                MeetingTracksV2.trackStartLiveFail(meetingId: meetingId, isStart: isStartLive)
            }
            Self.logger.error("updateLarkLiveAction error: \(error)")
        }, onCompleted: {
            Self.logger.error("updateLarkLiveAction success")
        })
        if action == .participantRequestStart {
            isEnableStartRelay.accept(false)
        }
        return response
    }

    func showVotingAlert(_ dispose: DisposeBag) {
        let policyUrl = service.setting.policyURL
        Policy.showLivestreamRequestFromHostAlert(policyUrl: policyUrl,
            handler: { [weak self] approve in
                guard let self = self, let voteID = self.liveInfo?.liveVote?.voteID else { return }
                self.updateLiveAction(action: approve ? .voteAccept : .voteRefuse, user: nil, voteID: voteID, privilege: nil, enableChat: nil, enablePlayback: nil, layout: nil, member: nil).subscribe().disposed(by: self.disposeBag)
            },
            completion: { result in
                if case .success(let alert) = result {
                    Disposables.create { [weak alert] in
                        DispatchQueue.main.async {
                            alert?.dismiss()
                        }
                    }
                    .disposed(by: dispose)
                }
            })
    }

    func showRefuseVoting() {
        guard meeting.setting.hasHostAuthority else {
            Toast.show(I18n.View_M_CantLivestreamNoConsent)
            return
        }
        ByteViewDialog.Builder()
            .id(.votingRefuse)
            .title(I18n.View_M_CantLivestreamNoConsent)
            .rightTitle(I18n.View_G_ConfirmButton)
            .show { [weak self] alert in
                guard let self = self else {
                    alert.dismiss()
                    return
                }
                Disposables.create { [weak alert] in
                    DispatchQueue.main.async {
                        alert?.dismiss()
                    }
                }
                .disposed(by: self.disposeBag)
            }
    }

    func bindShowVoting() {
        isShowVotingRefuse
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] show in
                if show {
                    self?.showRefuseVoting()
                }
            })
            .disposed(by: disposeBag)

        isVoting
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (isVoting, sponsorID) in
                guard let self = self else { return }
                if isVoting, !sponsorID.isEmpty,
                   sponsorID != self.meeting.account.deviceId {
                    let dispose = DisposeBag()
                    self.showVotingAlert(dispose)
                    self.votingDispose = dispose
                } else {
                    self.votingDispose = nil
                }
            })
            .disposed(by: disposeBag)
    }

    private func handleAskingLiveToast() {
        let liveDataObservable = liveChangedDataObservable
        liveDataObservable
            .filter { $0.type == .hostResponse }
            .map { $0.liveInfo.isLiving }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] accepted in
                if !accepted && self != nil {
                    Toast.show(I18n.View_M_HostDeclinedToLivestreamNew)
                }
            })
            .disposed(by: disposeBag)

        let notificationID = UUID().uuidString

        liveDataObservable
            .filter { $0.type == .participantRequest }
            .flatMap({ [weak self] (liveData) -> Observable<(ByteviewUser, String)> in
                guard let self = self else { return .empty() }
                let subject = ReplaySubject<ParticipantUserInfo>.create(bufferSize: 1)
                let participantService = self.meeting.httpClient.participantService
                participantService.participantInfo(pid: liveData.requester, meetingId: self.meeting.meetingId) { ap in
                    subject.onNext(ap)
                }
                return subject.asObservable().map { ap in (liveData.requester, ap.name) }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (requester, name) in
                guard let self = self,
                      !self.isShowingLivingRequest else {
                    return
                }

                let leftHandler: () -> Void = { [weak self] in
                    guard let self = self else { return }
                    LiveTracks.trackAskingLiveAlert(isAgree: false)
                    self.isShowingLivingRequest = false
                    self.getLiveProviderAvailableStatus()
                        .subscribe(onSuccess: { [weak self] status in
                            guard let self = self else { return }
                            if status.isProviderByteLive {
                                self.updateByteLiveAction(action: .hostRefuse, user: requester, livePermission: nil, enableChat: nil, layout: nil, member: nil).subscribe().disposed(by: self.disposeBag)
                            } else {
                                self.updateLarkLiveAction(action: .hostRefuse, user: requester, voteID: nil, privilege: nil, enableChat: nil, enablePlayback: nil, layout: nil, member: nil).subscribe().disposed(by: self.disposeBag)
                            }
                        }, onError: { _ in
                            Toast.show(I18n.View_G_CouldNotSendRequest)
                        })
                        .disposed(by: self.disposeBag)
                }

                let rightHandler: () -> Void = { [weak self] in
                    guard let self = self else {
                        return
                    }
                    LiveTracks.trackAskingLiveAlert(isAgree: true)
                    self.isShowingLivingRequest = false
                    self.enterLiveSettings(by: requester)
                }

                let completion: (ByteViewDialog) -> Void = { [weak self] alert in
                    guard let self = self else {
                        alert.dismiss()
                        return
                    }
                    Disposables.create { [weak alert] in
                        DispatchQueue.main.async {
                            alert?.dismiss()
                        }
                    }
                    .disposed(by: self.disposeBag)
                }

                self.isShowingLivingRequest = true
                Policy.startAskLiveStreamRequestAlert(
                    isFollow: self.meeting.shareData.isSharingDocument,
                    isInBreakoutRoom: self.meeting.data.isInBreakoutRoom,
                    requester: name,
                    handler: { agree in agree ? rightHandler() : leftHandler() },
                    completion: completion)

                if UIApplication.shared.applicationState != .active {
                    let body: String = I18n.View_G_YouReceivedRequest
                    UNUserNotificationCenter.current().addLocalNotification(withIdentifier: notificationID, body: body)
                }
            })
            .disposed(by: disposeBag)
    }

    private func enterLiveSettings(by requester: ByteviewUser) {
        if let topController = self.router.topMost, topController is LiveSettingsViewController {
            return
        }

        self.getLiveProviderAvailableStatus()
            .subscribe(onSuccess: { [weak self] status in
                guard let self = self else { return }
                Util.runInMainThread {
                    if self.shouldShowLiveUnavailableView {
                        guard let response = status.response else { return }
                        LiveSettingUnavailableAlert
                            .unavailableAlert(type: status.byteLiveUnAvailableType, role: response.userInfo.role)
                            .rightHandler({ _ in
                                self.showByteLiveAppIfNeeded()
                                self.showByteLiveBotAndSendMessageIfNeeded()
                            })
                            .show()
                    } else {
                        let presentLiveSettingsVC = { [weak self] in
                            guard let self = self else { return }
                            let vm = LiveSettingsViewModel(meeting: self.meeting, live: self, liveProviderStatus: status, liveSource: .participantAskLiving(requester))
                            let viewController = LiveSettingsViewController(viewModel: vm)
                            self.meeting.router.presentDynamicModal(viewController,
                                                              regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                                              compactConfig: .init(presentationStyle: .fullScreen, needNavigation: true))
                        }
                        if self.meeting.router.isFloating {
                            self.meeting.router.setWindowFloating(false) { _ in
                                presentLiveSettingsVC()
                            }
                        } else {
                            presentLiveSettingsVC()
                        }
                    }
                }
            }, onError: { _ in
                Toast.show(I18n.View_M_LivestreamingErrorTryAgainLaterNew)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Guide

    var maxParticipantsCount: Int? {
        if meeting.type == .meet {
            return meeting.setting.maxParticipantNum + meeting.setting.maxAttendeeNum
        } else {
            return nil
        }
    }

    private func checkLiveGuide() {
        if isLiveGuideAllowed, let maxParticipantsCount = self.maxParticipantsCount {
            // 参会者满人触发
            let nonIdleCount = meeting.participant.currentRoom.count + meeting.participant.attendee.count
            if self.lastNonIdleCount != nonIdleCount, matchesParticipantsCountPredicate(current: nonIdleCount, max: maxParticipantsCount) {
                showLiveGuide()
            }
            self.lastNonIdleCount = nonIdleCount
        }
    }

    private func matchesParticipantsCountPredicate(current: Int, max: Int) -> Bool {
        let factor: Double = 0.8
        return current >= Int(Double(max) * factor)
    }

    private var isLiveGuideAllowed: Bool {
        return meeting.setting.isLiveEnabled && service.shouldShowGuide(.live)
    }

    private func showLiveGuide() {
        let guide = GuideDescriptor(type: .liveReachMaxParticipant, title: nil, desc: I18n.View_M_LivestreamingOnboardingNew)
        guide.style = .plain
        guide.sureAction = { [weak self] in self?.service.didShowGuide(.live) }
        GuideManager.shared.request(guide: guide)
    }

    // MARK: - push
    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        if let info = inMeetingInfo.liveInfo, info != liveInfo {
            liveInfoRelay.accept(info)
            if info.isLiving {
                isEnableStartRelay.accept(true)
                liveUsersCountRelay.accept(liveUsersCount)
            } else {
                liveUsersCountRelay.accept(0)
            }
        }
    }

    func didReceiveInMeetingChangedInfo(_ data: InMeetingData) {
        if data.meetingID == meetingId, data.type == .liveMeeting, let change = data.liveData {
            liveChangedDataSubject.onNext(change)
            if change.type == .hostResponse {
                isEnableStartRelay.accept(true)
            }
        }
    }

    func didReceiveExtraInfo(_ message: VideoChatExtraInfo) {
        Logger.meeting.info("didReceiveExtraInfo: \(message.type)")
        if message.type == .updateLiveExtraInfo, let info = message.liveExtraInfo {
            liveUsersCount = Int(info.onlineUsersCount)
            if isLiving, liveUsersCount != liveUsersCountRelay.value {
                liveUsersCountRelay.accept(liveUsersCount)
            }
        } else if message.type == .inMeetingChanged {
            message.inMeetingData.forEach { (data) in
                if data.meetingID == meetingId, data.type == .liveMeeting, let liveData = data.liveData {
                    liveMeetingDataSubject.onNext(liveData)
                }
            }
        }
    }

    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        Util.runInMainThread {
            self.checkLiveGuide()
        }
    }

    func didChangeWebinarAttendees(_ output: InMeetParticipantOutput) {
        Util.runInMainThread {
            self.checkLiveGuide()
        }
    }
}

extension InMeetLiveViewModel {
    func getLiveProviderAvailableStatus() -> Single<LiveProviderAvailableStatus> {
        if !meeting.setting.isEnterpriseLiveEnabled {
            return RxTransform.single {
                let status = LiveProviderAvailableStatus(response: nil)
                status.isProviderByteLive = false
                status.isByteLiveAvailable = false
                status.isLarkLiveAvailable = true
                self.liveProviderStatus = status
                $0(.success(status))
            }
        }

        return RxTransform.single {
            let request = GetLiveProviderInfoRequest(meetingId: self.meetingId)
            let httpClient = self.meeting.httpClient
            return httpClient.getResponse(request, completion: $0)
        }
        .do(onSuccess: {
            LiveSettingsViewModel.logger.info("get LiveProviderInfo success: \($0)")
        }, onError: {
            LiveSettingsViewModel.logger.error("get LiveProviderInfo error: \($0)")
        })
        .map { info -> LiveProviderAvailableStatus in
            let status = LiveProviderAvailableStatus(response: info)

            // 海外没有企业直播逻辑, 直接进飞书直播
            if info.isOversea {
                status.byteLiveUnAvailableType = .none
                status.isLarkLiveAvailable = true
                status.isByteLiveAvailable = false
                status.isProviderByteLive = false
                status.isByteLiveCreatorSameWithUser = true
                self.liveProviderStatus = status
                return status
            }

            status.isByteLiveCreatorSameWithUser = info.userInfo.isByteLiveCreatorSameWithUser

            // 判断企业直播是否可用
            repeat {
                // 直播中并且是企业直播 则认为企业直播可用
                if info.liveSettings.isLiving
                    && info.liveSettings.liveBrand == .byteLive {
                    status.isByteLiveAvailable = true
                    status.byteLiveUnAvailableType = .none
                    break
                }

                let byteLiveInfo = info.byteLiveInfo
                // 未开通
                if !byteLiveInfo.hasByteLive {
                    status.isByteLiveAvailable = false
                    status.byteLiveUnAvailableType = .inactive
                    break
                }
                // 版本到期
                if byteLiveInfo.isVersionExpired {
                    status.isByteLiveAvailable = false
                    status.byteLiveUnAvailableType = .versionExpired
                    break
                }
                // 时长包用完
                if byteLiveInfo.isPackageExpired {
                    status.isByteLiveAvailable = false
                    status.byteLiveUnAvailableType = .packageExpired
                    break
                }
                // 管理员未授权该用户
                if !byteLiveInfo.hasByteLiveAppPermission {
                    status.isByteLiveAvailable = false
                    status.byteLiveUnAvailableType = .noAppPermission
                    break
                }
                // 需要创建子账号申请开播
                if byteLiveInfo.needApplyCreateSubAccount {
                    status.isByteLiveAvailable = false
                    status.byteLiveUnAvailableType = .needCreateSubAccount
                    break
                }
                status.isByteLiveAvailable = true
                status.byteLiveUnAvailableType = .none
            } while false

            // 已经飞书直播开播了不关注hasLarkLive
            if info.liveSettings.isLiving
                && info.liveSettings.liveBrand == .larkLive {
                status.isLarkLiveAvailable = true
            } else {
                status.isLarkLiveAvailable = info.hasLarkLive
            }

            // 只有已经开播过的才根据历史选择企业直播 || 飞书直播不可用时默认选择企业直播
            if (info.liveSettings.liveBrand == .byteLive && info.liveSettings.liveHistory == .createAndHasStarted)
                || status.isLarkLiveAvailable == false {
                status.isProviderByteLive = true
            } else {
                status.isProviderByteLive = false
            }
            self.liveProviderStatus = status
            return status
        }
    }

    var shouldShowLiveUnavailableView: Bool {
        guard let status = liveProviderStatus else { return false }
        guard let response = status.response else { return false }

        if response.isOversea {
            return false
        }

        if response.liveSettings.isLiving {
            return false
        }

        //
        // 开播过
        //   上次开播使用 bytelive ---> 继续处理
        //   上次开播使用 larklive ---> return false (corner case: hasLarkLive == false 这时如何处理? 现在依旧可以进入设置页)
        //
        // 没开播过
        //   both ---> return false
        //   hasOnlyLarkLive ---> return false
        //   hasOnlyByteLive ---> 继续处理
        //   nothing ---> true

        if response.liveSettings.liveHistory == .createAndHasStarted, response.liveSettings.liveBrand != .unknow {
            // 若用飞书直播开播过，不显示
            if response.liveSettings.liveBrand == .larkLive {
                // TODO: 若上一次用 飞书直播 开播过，本次 hasLarkLive 为 false，处理逻辑未确定
                return false
            }
        } else {
            // 若没开播过
            if status.isLarkLiveAvailable {
                return false
            }
            if !status.isLarkLiveAvailable && !status.isByteLiveAvailable {
                return true
            }
        }

        if status.isByteLiveAvailable {
            return false
        } else {
            return true
        }
    }

    func showByteLiveAppIfNeeded() {
        if self.liveProviderStatus?.byteLiveUnAvailableType == .noAppPermission,
           let url = self.liveProviderStatus?.response?.byteLiveInfo.byteLiveAppURL {
            self.router.setWindowFloating(true)
            self.larkRouter.goto(scheme: url)
        }
    }

    func showByteLiveBotAndSendMessageIfNeeded() {
        if self.liveProviderStatus?.byteLiveUnAvailableType == .needCreateSubAccount,
           let url = self.liveProviderStatus?.response?.byteLiveInfo.byteLiveBotApplink {
            self.httpClient.send(ByteLiveBotSendMessageRequest())
            self.router.setWindowFloating(true)
            self.larkRouter.goto(scheme: url)
        }
    }
}

extension InMeetLiveViewModel: RouterListener {
    func didChangeWindowFloatingBeforeAnimation(_ isFloating: Bool, window: FloatingWindow?) {
        if isFloating {
            Logger.live.info("try to close live window if it exist")
            meeting.service.live.stopLive()
        }
    }
}
