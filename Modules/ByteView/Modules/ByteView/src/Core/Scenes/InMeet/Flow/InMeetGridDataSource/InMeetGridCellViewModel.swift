//
//  InMeetGridCellViewModel.swift
//  ByteView
//
//  Created by liujianlong on 2021/6/16.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import ByteViewCommon
import ByteViewNetwork
import ByteViewSetting
import ByteViewRtcBridge

class InMeetGridCellViewModel: Hashable {

    enum CellType {
        case participant
        case share
        case activeSpeaker
    }

    let type: CellType

    let isRemoved = BehaviorRelay(value: false)

    let isMe: Bool

    var rtcUid: RtcUID {
        participant.value.rtcUid
    }

    var streamKey: RtcStreamKey? {
        if isMe {
            return .local
        }
        return .stream(uid: rtcUid, sessionId: meeting.sessionId)
    }
    let meeting: InMeetMeeting
    let context: InMeetViewContext
    let roleStrategy: MeetingRoleStrategy
    let pid: ByteviewUser

    private var inMeetInfo: Observable<VideoChatInMeetingInfo> { dependency.inMeetInfoRelay.asObservable().compactMap { $0 } }

    private let dependency: CellViewModelDependency

    var hasHostAuthority: BehaviorRelay<Bool> {
        dependency.hasHostAuthority
    }


    let isActiveSpeaker: Observable<Bool>
    let rtcNetworkStatus: Observable<RtcNetworkStatus?>

    let participant: BehaviorRelay<Participant>
    var participantInfo: Observable<(Participant, ParticipantUserInfo)> {
        participant
            .distinctUntilChanged()
            .flatMapLatest { [weak self] p -> Observable<(Participant, ParticipantUserInfo)> in
            guard let self = self else { return .empty() }
            return Observable<(Participant, ParticipantUserInfo)>.create { [weak self] ob -> Disposable in
                guard let self = self else {
                    return Disposables.create {}
                }
                let participantService = self.meeting.httpClient.participantService
                participantService.participantInfo(pid: p, meetingId: self.meeting.meetingId) { ap in
                    ob.onNext((p, ap))
                    ob.onCompleted()
                }
                return Disposables.create {}
            }
        }.distinctUntilChanged {
            $0.0 == $1.0 && $0.1 == $1.1
        }
    }

    var isPortraitMode: Observable<Bool> {
        let pid = self.pid
        return inMeetInfo.map { inMeetInfo -> Bool in
            if let shareScreenInfo = inMeetInfo.shareScreen {
                return shareScreenInfo.isSharing && shareScreenInfo.isPortraitMode && shareScreenInfo.participant == pid
            } else {
                return false
            }
        }
        .distinctUntilChanged()
    }

    var couldCancelInvite: Observable<Bool> {
        Observable.combineLatest(participant, dependency.hasHostAuthority)
            .map { [weak self] participant, hasHostAuthority -> Bool in
                guard let self = self else { return false }
                let ringing = participant.status == .ringing
                let mySelfIdentifier = self.meeting.account
                let couldCancelInvite = ringing && (participant.inviter == mySelfIdentifier || hasHostAuthority == true)
                return couldCancelInvite
            }

    }

    var sharingUserIdentifiers: Observable<Set<ByteviewUser>> {
        inMeetInfo.map(\.sharingIdentifiers)
    }

    var focusingUser: Observable<ByteviewUser?> {
        inMeetInfo.map(\.focusVideoData?.focusUser)
    }

    lazy var meetType: Observable<MeetingType> = {
        inMeetInfo.map { $0.vcType }
    }()

    lazy var isConnected: Observable<Bool> = {
        if isMe || meeting.type != .call || type != .participant {
            return .just(true)
        } else {
            return Observable.combineLatest(self.meetType,
                                            dependency.isConnectedRelay.asObservable(),
                                            self.participant.asObservable())
            .map { (type: MeetingType, isConnected: Bool, v: Participant) in
                type != .call || isConnected || v.settings.isMicrophoneMuted
            }
        }
    }()

    private let canBeActiveSpeaker: BehaviorRelay<Bool> = BehaviorRelay(value: true)
    private var canBeActiveSpeakerTimer: Timer?

    lazy var isOwnerJoinedMeeting: Observable<Bool> = {
        inMeetInfo.map { $0.meetingSettings.isOwnerJoinedMeeting }
    }()

    lazy var hasRoleTag: Observable<Bool> = {
        let roleStrategy = meeting.data.roleStrategy
        return Observable.combineLatest(self.meetType, self.participant.asObservable(), isOwnerJoinedMeeting)
                .map { meetType, participant, isOwnerJoined -> Bool in
                    return Self.canShowHostAndCohost(meetType: meetType,
                                                     isLarkGuest: participant.isLarkGuest,
                                                     role: participant.role,
                                                     roleStrategy: roleStrategy,
                                                     meetingRole: participant.meetingRole,
                                                     isOwnerJoinedMeeting: isOwnerJoined)
                }
    }()

    var meetingLayoutStyle: Observable<MeetingLayoutStyle> {
        dependency.meetingLayoutStyleRelay.asObservable().distinctUntilChanged()
    }

    let squareInfo: InMeetingCollectionViewSquareGridFlowLayout.SquareInfo

    var weight: Int {
        participant.value.gridType == .room ? 2 : 1
    }

    var isFocused: Bool {
        self.participant.value.user == meeting.data.inMeetingInfo?.focusingUser
    }

    let batteryManager: InMeetBatteryStatusManager

    init(meeting: InMeetMeeting,
         context: InMeetViewContext,
         dependency: CellViewModelDependency,
         participant: Participant,
         batteryManager: InMeetBatteryStatusManager,
         type: CellType = .participant) {
        self.meeting = meeting
        self.context = context
        self.dependency = dependency
        self.type = type
        self.batteryManager = batteryManager

        self.pid = participant.user
        self.isMe = participant.user == meeting.account
        self.participant = BehaviorRelay(value: participant)
        let roleStrategy = meeting.data.roleStrategy
        self.roleStrategy = roleStrategy


        self.isActiveSpeaker = Observable.combineLatest(self.participant.asObservable(),
                                                        self.dependency.activeSpeakerSdkUidRelay.asObservable(),
                                                        self.canBeActiveSpeaker.asObservable().distinctUntilChanged())
            .observeOn(MainScheduler.instance)
            .map({ participant, speakerSDKUID, canBeActiveSpeaker in
                guard canBeActiveSpeaker else { return false }
                return Self.calActiveSpeaker(speakerSDKUID: speakerSDKUID, participant: participant)
            })

        self.rtcNetworkStatus = Observable.combineLatest(self.participant.asObservable(),
                                                         dependency.rtcNetworkStatusRelay.asObservable())
            .map({ participant, status in
                /// 防止没有收到RTC回调
                return status?[participant.rtcUid]
            })

        self.squareInfo = .init(gridType: participant.gridType)
    }

    func updateParticipant(participant: Participant) {
        let oldValue = self.participant.value
        let oldIsMicMuted = oldValue.settings.isMicrophoneMutedOrUnavailable
        let newIsMicMuted = participant.settings.isMicrophoneMutedOrUnavailable
        let isMicOpened = oldIsMicMuted && !newIsMicMuted
        let isParticipantChanged = oldValue.user != participant.user

        if isParticipantChanged || isMicOpened {
            markCanBecomeActiveSpeaker()
        } else if oldIsMicMuted != newIsMicMuted {
            Util.runInMainThread { [weak self] in
                guard let self = self else { return }
                let time = Double(self.meeting.setting.activeSpeakerConfig.holdTimeMs + 500) / 1000
                self.canBeActiveSpeakerTimer = Timer.scheduledTimer(withTimeInterval: time, repeats: false, block: { [weak self] _ in
                    self?.canBeActiveSpeaker.accept(false)
                })
            }
        }

        self.participant.accept(participant)
    }

    private func markCanBecomeActiveSpeaker() {
        canBeActiveSpeakerTimer?.invalidate()
        canBeActiveSpeakerTimer = nil
        canBeActiveSpeaker.accept(true)
    }

    static func calActiveSpeaker(speakerSDKUID: RtcUID?, participant: Participant) -> Bool {
        if participant.rtcUid == speakerSDKUID {
            return true
        } else if participant.callMeInfo.status == .onTheCall && participant.callMeInfo.rtcUID == speakerSDKUID {
            return true
        }
        return false
    }

    static func canShowHostAndCohost(meetType: MeetingType,
                                     isLarkGuest: Bool,
                                     role: ParticipantRole,
                                     roleStrategy: MeetingRoleStrategy,
                                     meetingRole: ParticipantMeetingRole,
                                     isOwnerJoinedMeeting: Bool) -> Bool {
        return meetType == .meet &&
            roleStrategy.participantCanBecomeHost(role: role) &&
            (meetingRole == .host || meetingRole == .coHost) &&
            isOwnerJoinedMeeting &&
            !isLarkGuest
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.pid)
    }

    static func == (lhs: InMeetGridCellViewModel, rhs: InMeetGridCellViewModel) -> Bool {
        return lhs === rhs || lhs.pid == rhs.pid
    }

}

extension InMeetGridCellViewModel: CustomStringConvertible {
    var description: String {
        "\(participant.value.user)"
    }
}
