//
//  VChatMeetingCardViewModelImpl.swift
//  LarkByteView
//
//  Created by liujianlong on 2021/5/24.
//

import Foundation
import RxSwift
import RxRelay
import LarkModel
import LarkSetting
import ByteViewInterface
import Action
import EENavigator
import LarkUIKit
import RustPB
import ByteViewCommon
import ByteViewTracker
import ByteViewNetwork
import LarkContainer

protocol VChatMeetingCardViewModelImplDelegate: AnyObject {
    func needUpdate()
}

class MainThreadScheduler: ImmediateSchedulerType {
    static let instance = MainThreadScheduler()
    func schedule<StateType>(_ state: StateType, action: @escaping (StateType) -> Disposable) -> Disposable {
        if Thread.isMainThread {
            return action(state)
        } else {
            return MainScheduler.instance.schedule(state, action: action)
        }
    }
}

struct VChatPreviewedParticipantSlice {
    var participants: [VChatPreviewedParticipant]
    var totalCount: Int
}

class VChatMeetingCardViewModelImpl {
    static let logger = Logger.meetingCard
    let context: VChatMeetingCardViewModelContext
    let content: VChatMeetingCardContent
    let isFromSecretChat: Bool

    var messageId: String?

    let disposeBag = DisposeBag()

    let isDisplaying = BehaviorRelay(value: false)

    let meetingCardContent: BehaviorRelay<VChatMeetingCardContent>
    let topic: Observable<String>
    let joinButtonStatus: Observable<MeetingCardStatus>
    let meetingSource: VCMeetingSource
    let meetingTagTypeRelay: BehaviorRelay<MeetingTagType>
    var meetingTagType: Observable<MeetingTagType> { meetingTagTypeRelay.asObservable() }
    let meetingNumber: String
    let participants: Observable<VChatPreviewedParticipantSlice>

    let meetingDuration: BehaviorRelay<TimeInterval?>
    let meetingIdRelay: BehaviorRelay<String?>
    let webinarAttendeeNum: Observable<Int>
    let joinedDeviceDesc: BehaviorRelay<String?> = BehaviorRelay(value: nil)
    weak var delegate: VChatMeetingCardViewModelImplDelegate?
    private lazy var isRelationTagEnabled = context.setting?.isRelationTagEnabled ?? false
    let userResolver: UserResolver
    var httpClient: HttpClient? { context.httpClient }
    private var meetingObserver: MeetingObserver?

    deinit {
        Self.logger.debug("deinit")
    }

    init(context: VChatMeetingCardViewModelContext, content: VChatMeetingCardContent, isFromSecretChat: Bool) {
        self.userResolver = context.userResolver
        self.context = context
        self.content = content
        self.isFromSecretChat = isFromSecretChat
        self.meetingCardContent = BehaviorRelay(value: content)
        let observer = try? context.userResolver.resolve(assert: MeetingService.self).createMeetingObserver()
        self.meetingObserver = observer
        let currentMeeting = observer?.currentMeeting
        self.meetingIdRelay = BehaviorRelay(value: currentMeeting?.state == .onTheCall ? currentMeeting?.meetingId : nil)
        self.meetingTagTypeRelay = BehaviorRelay(value: .none)
        self.topic = self.meetingCardContent.map({ $0.topic })
            .distinctUntilChanged()
            .observeOn(MainThreadScheduler.instance)

        let meetingIDObservable = meetingIdRelay.asObservable()
        let contentIDObservable = Observable.combineLatest(self.meetingCardContent, meetingIDObservable)
            .share(replay: 1, scope: .whileConnected)
        self.joinButtonStatus = contentIDObservable
            .map { content, currentMeetingID -> MeetingCardStatus in
                Self.computeMeetingCardStatus(context: context, currentMeetingID: currentMeetingID, content: content)
            }
            .do(onNext: { status in
                Self.logger.info("joinButton status:\(status), meetingID:\(content.meetingID)")
            })
            .distinctUntilChanged()
            .observeOn(MainThreadScheduler.instance)

        self.meetingSource = content.meetingSource
        self.meetingNumber = content.meetNumber

        self.webinarAttendeeNum = self.meetingCardContent
            .map { $0.webinarAttendeeNum }
            .distinctUntilChanged()
            .observeOn(MainThreadScheduler.instance)

        let httpClient = context.httpClient
        let deviceId = context.account?.deviceId ?? ""
        let me = ParticipantId(id: context.userId, type: .larkUser, deviceId: deviceId)
        self.participants = contentIDObservable.map { content, _ -> ([ParticipantId], Int) in
            var previewParticipants = Array(content.participants.prefix(MeetingCardConstant.countOfParticipantsInDetail)
                                                .map({ $0.participantId }))
            if let first = previewParticipants.first, !(first.id == me.id && first.type == me.type) {
                // myAccountNotAtFirstIndex
                if let m = previewParticipants.first(where: { $0 == me }) {
                    previewParticipants.lf_remove(object: m)
                    previewParticipants.insert(m, at: 1)
                    } else if let m = previewParticipants.first(where: { $0.id == me.id && $0.type == me.type }) {
                        previewParticipants.lf_remove(object: m)
                        previewParticipants.insert(m, at: 1)
                    }
                }
                let totalCount = max(Int(content.participants.count), Int(content.totalParticipantNum))
                return (previewParticipants, totalCount)
            }
            .distinctUntilChanged(Self.compareParticipants(lhs:rhs:))
            .flatMapLatest({ participants, totalCount -> Observable<VChatPreviewedParticipantSlice> in
                guard let httpClient = httpClient else { return .empty() }
                return httpClient.participantService.participantsByIdsUsingCache(participants, meetingId: content.meetingID, compactMap: { p, ap -> VChatPreviewedParticipant? in
                    return VChatPreviewedParticipant(id: p.id, deviceId: p.deviceId, type: p.type,
                                                     userName: ap.name, avatarInfo: ap.avatarInfo)
                })
                .asObservable()
                .map {
                    return VChatPreviewedParticipantSlice(participants: $0, totalCount: totalCount)
                }
            })
            .share(replay: 1, scope: .forever)
            .observeOn(MainThreadScheduler.instance)

        self.meetingDuration = BehaviorRelay(value: nil)
        self.meetingCardContent.distinctUntilChanged {
            $0.status == $1.status
        }.flatMapLatest { content -> Observable<TimeInterval?> in
            guard let httpClient = httpClient, content.status != .unknown else {
                return .just(nil)
            }
            if content.status == .end {
                return .just(TimeInterval(content.endTimeMs - content.startTimeMs) / 1000)
            } else {
                return Self.getMeetingDuration(meetingId: content.meetingID, httpClient: httpClient)
                    .asObservable()
                    .map { duration -> TimeInterval in Date().timeIntervalSince1970 - duration }
                    .catchErrorJustReturn(TimeInterval(content.startTimeMs / 1000))
                    .flatMap({ startTime -> Observable<TimeInterval?> in
                        Observable<Int>.timer(.seconds(0), period: .seconds(1), scheduler: MainScheduler.instance)
                            .map({ _ -> TimeInterval? in
                                Date().timeIntervalSince1970 - startTime
                            })
                    })
            }
        }.subscribe(onNext: { [weak self] in
            self?.meetingDuration.accept($0)
        }).disposed(by: disposeBag)

        self.meetingCardContent
            .asObservable()
            .subscribe(onNext: { [weak self] content in
                self?.getMeetingTagType(context: context, content: content)
                self?.updateJoinedDeviceInfo()
            }).disposed(by: disposeBag)

        observer?.setDelegate(self)
        Self.logger.debug("init meetingID:\(content.meetingID), status:\(content.status)")
    }

    func computeIsShowHour() -> Bool {
        if content.status == .end {
            return Self.formatMeetingDuration(TimeInterval(content.endTimeMs - content.startTimeMs) / 1000).1
        } else if content.status == .unknown {
            return false
        } else {
            return Self.formatMeetingDuration(Date().timeIntervalSince1970 - TimeInterval(content.startTimeMs / 1000)).1
        }
    }

    func changeSelfFrame() {
        guard let delegate = self.delegate else {
            return
        }
        delegate.needUpdate()
    }

    func computeIsExternal() -> Bool {
        return Self.computeIsExternal(context: context, content: content)
    }

    func updateContent(newContent: VChatMeetingCardContent) {
        let oldContent = meetingCardContent.value
        Self.logger.debug("update meetingID:\(newContent.meetingID), oldMeetingID:\(oldContent.meetingID) status:\(newContent.status), oldStatus:\(oldContent.status)")
        self.meetingCardContent.accept(newContent)
    }

    private func timeLengthNotice() {
        guard let messageId = self.messageId else {
            return
        }
        context.reloadRow(by: messageId, animation: .automatic)
    }

    var navigator: Navigatable { userResolver.navigator }
    func joinMeeting() {
        guard let targetVC = context.targetVC else { return }
        VCTracker.post(name: .vc_meeting_entry_click, params: [.click: "card", .target: TrackEventName.vc_meeting_pre_view])
        let content = self.meetingCardContent.value
        let currentMeetingId = self.meetingObserver?.currentMeeting?.toActiveMeeting()?.meetingId
        let meetingCardStatus = Self.computeMeetingCardStatus(context: context, currentMeetingID: currentMeetingId, content: content)
        guard meetingCardStatus == .joined || meetingCardStatus == .joinable else { return }
        let topic: String
        switch content.meetingSource {
        case .cardUnknownSourceType, .cardFromUser:
            topic = content.topic
        case .cardFromCalendar:
            topic = content.topic.isEmpty ? I18n.Lark_View_ServerNoTitle : content.topic
        case .cardFromInterview:
            topic = I18n.Lark_View_VideoInterviewNameBraces(content.topic)
        @unknown default:
            return
        }
        let body = JoinMeetingBody(id: content.meetingID, idType: .meetingId, isFromSecretChat: isFromSecretChat, entrySource: .meetingCard, topic: topic, chatId: content.chatID, messageId: content.messageID, meetingSubtype: Int(content.meetingSubtype))
        self.navigator.present(body: body, from: targetVC, prepare: { $0.modalPresentationStyle = .fullScreen })
    }

    func getMeetingTagType() -> MeetingTagType {
        return meetingTagTypeRelay.value
    }

    func participantsPreviewTapped() {
        let content = self.meetingCardContent.value
        guard let targetVC = context.targetVC,
              !content.participants.isEmpty else {
            return
        }
        if content.participants.count == 1 {
            let navigator = self.navigator
            if let participant = content.participants.first, participant.userType == .larkUser {
                let friendSource = PersonCardUtility.personCardFriendSource(chatterAPI: context.chatterAPI,
                                                                            sponsorID: content.sponsorID,
                                                                            meetingId: content.meetingID,
                                                                            meetingTopic: content.topic,
                                                                            chatterID: participant.userID)
                friendSource.subscribe(onSuccess: { [weak targetVC] info in
                    guard let targetVC = targetVC else { return }
                    let body = PersonCardUtility.personCardBody(friendSource: info)
                    navigator.presentOrPush(
                        body: body,
                        wrap: LkNavigationController.self,
                        from: targetVC,
                        prepareForPresent: { vc in
                            vc.modalPresentationStyle = .formSheet
                        })
                })
                .disposed(by: disposeBag)
            }
        } else {
            // 兼容4.2.0之前的卡片数据
            if content.totalParticipantNum == 0, let httpClient = self.httpClient {
                httpClient.participantService.participantsByIdsUsingCache(content.participants.map({ $0.participantId }), meetingId: content.meetingID,
                                                               compactMap: { p, ap -> VChatPreviewedParticipant? in
                        return VChatPreviewedParticipant(id: p.id, deviceId: p.deviceId, type: p.type, userName: ap.name, avatarInfo: ap.avatarInfo)
                    })
                    .observeOn(MainScheduler.instance)
                    .subscribe(onSuccess: { [weak self] previewParticipants in
                        self?.pushToParticipantDetailVC(with: previewParticipants)
                    })
                    .disposed(by: disposeBag)
            } else {
                self.participants
                    .take(1)
                    .subscribe(onNext: { [weak self] previewParticipants in
                        self?.pushToParticipantDetailVC(with: previewParticipants.participants)

                    })
                    .disposed(by: disposeBag)
            }
        }
    }

    private func pushToParticipantDetailVC(with previewParticipants: [VChatPreviewedParticipant]) {
        guard let targetVC = context.targetVC else {
            return
        }
        let content = self.meetingCardContent.value
        let chatterAPI = context.chatterAPI
        let navigator = self.navigator
        Self.logger.info("participantsCount:\(previewParticipants.count), num:\(content.totalParticipantNum)")
        let participants = Self.getPreviewedParticipants(content: content, previewedParticipants: previewParticipants)
        let isInterview = meetingSource == .cardFromInterview
        let body = PreviewParticipantsBody(participants: participants, totalCount: Int(content.totalParticipantNum), meetingId: content.meetingID, chatId: content.chatID, isInterview: isInterview, isWebinar: content.isWebinar) { [weak self] participant, fromVC in
            guard let self = self else { return }
            if participant.participantType == .larkUser ||
                (participant.participantType == .pstnUser && participant.bindType == .lark) {
                let chatterID = participant.participantType == .larkUser ? participant.userId : participant.bindId
                let source = PersonCardUtility.personCardFriendSource(chatterAPI: chatterAPI,
                                                                      sponsorID: content.sponsorID,
                                                                      meetingId: content.meetingID,
                                                                      meetingTopic: content.topic,
                                                                      chatterID: chatterID)
                source.asObservable()
                    .subscribe(onNext: { (source) in
                        let body = PersonCardUtility.personCardBody(friendSource: source)
                        navigator.push(body: body, from: fromVC)
                    })
                    .disposed(by: self.disposeBag)
            }
        }
        context.dependency?.showPreviewParticipants(body: body, from: targetVC)
    }

    static func formatMeetingDuration(_ interval: TimeInterval?) -> (String, Bool) {
        guard let interval = interval else {
            return ("", false)
        }
        let diffIntervalSecond = Int64(interval)
        let hour = Int(diffIntervalSecond / 3600)
        let minute = Int((diffIntervalSecond % 3600) / 60)
        let second = Int(diffIntervalSecond % 60)
        if hour > 0 {
            return (String(format: "%02d:%02d:%02d", hour, minute, second), true)
        } else {
            return (String(format: "%02d:%02d", minute, second), false)
        }
    }

    static private func compareParticipants(lhs: ([ParticipantId], Int), rhs: ([ParticipantId], Int)) -> Bool {
        return lhs.1 == rhs.1 && lhs.0 == rhs.0
    }

    static func getPreviewedParticipants(content: VChatMeetingCardContent, previewedParticipants: [VChatPreviewedParticipant]) -> [PreviewParticipant] {
        let sponsorID = content.sponsorID
        var alreadyHasSponsor = false
        var participantCountDic: [String: Int] = [:]
        previewedParticipants.forEach { (participant) in
            participantCountDic[participant.id] = (participantCountDic[participant.id] ?? 0) + 1
        }
        let duplicateDeviceSet = Set(participantCountDic.filter { $0.value > 1 }.map { $0.key })
        let participants = content.participants
        return previewedParticipants.map { (p: VChatPreviewedParticipant) -> PreviewParticipant in
            let isSponsor: Bool
            if alreadyHasSponsor {
                isSponsor = false
            } else {
                isSponsor = sponsorID == p.id
                alreadyHasSponsor = isSponsor
            }
            let participant = participants.first(where: { $0.id == p.id && $0.deviceID == p.deviceId && $0.userType.rawValue == p.type.rawValue })
            let deviceType = participant?.deviceType ?? .mobile
            let showDevice = duplicateDeviceSet.contains(p.id) && (deviceType == .mobile || deviceType == .web)
            let isLarkGuest = participant?.isLarkGuest ?? false
            let tenantTag = participant?.tenantTag.rawValue
            let userTenantID = participant?.tenantID ?? ""
            let bindId = participant?.bindID ?? ""
            let bindType = participant?.bindType ?? .unkown
            return PreviewParticipant(userId: p.id,
                                      userName: p.userName,
                                      avatarInfo: p.avatarInfo,
                                      participantType: .init(rawValue: p.type.rawValue),
                                      isLarkGuest: isLarkGuest,
                                      isSponsor: isSponsor,
                                      deviceType: .init(rawValue: deviceType.rawValue) ?? .unknown,
                                      showDevice: showDevice,
                                      tenantId: userTenantID,
                                      tenantTag: tenantTag.flatMap({ .init(rawValue: $0) }),
                                      bindId: bindId,
                                      bindType: .init(rawValue: bindType.rawValue) ?? .unknown,
                                      showCallme: participant?.usedCallMe ?? false)
        }
    }

    static func computeMeetingCardStatus(context: VChatMeetingCardViewModelContext,
                                         currentMeetingID: String?,
                                         content: VChatMeetingCardContent) -> MeetingCardStatus {
        let deviceInMeeting = isSelfDeviceInMeeting(context: context, currentMeetingID: currentMeetingID, content: content)
        let accountInMeeting = isSelfAccountInMeeting(context: context, currentMeetingID: currentMeetingID, content: content)
        let isMeetingOwner = selfIsMeetingOwner(context: context, content: content)
        if content.status == .unknown {
            return .unknown
        }

        if content.status == .end {
            return .end
        }

        if deviceInMeeting {
            return .joined
        }

        if content.status == .full {
            if isMeetingOwner && !accountInMeeting {
                return .joinable
            }
            return .full
        }

        return .joinable
    }

    private static func isSelfDeviceInMeeting(context: VChatMeetingCardViewModelContext,
                                              currentMeetingID: String?,
                                              content: VChatMeetingCardContent) -> Bool {
        let selfDeviceInMeeting = content.participants.contains(where: { p in
            let userID = p.userID
            let deviceID = p.hasDeviceID ? p.deviceID : nil
            return p.status == .onTheCall && context.isMe(chatterId: userID, deviceId: deviceID) && p.userType == .larkUser
        })
        // meeting去取自己在不在会中
        var isSelfInMeetingFromVC = false
        if let meeting = try? context.userResolver.resolve(assert: MeetingService.self).currentMeeting, meeting.isActive,
           meeting.meetingId == content.meetingID {
            isSelfInMeetingFromVC = meeting.state == .onTheCall
        }
        return selfDeviceInMeeting || isSelfInMeetingFromVC
    }

    private static func isSelfAccountInMeeting(context: VChatMeetingCardViewModelContext,
                                               currentMeetingID: String?,
                                               content: VChatMeetingCardContent) -> Bool {
        let selfAccountInMeeting = content.participants.contains(where: { p in
            let userID = p.userID
            return context.isMe(chatterId: userID, deviceId: nil)
        })

        return selfAccountInMeeting
    }

    private static func selfIsMeetingOwner(context: VChatMeetingCardViewModelContext,
                                           content: VChatMeetingCardContent) -> Bool {
        guard let type = content.meetingOwnerType,
              let userID = content.meetingOwnerId else {
            return false
        }
        return type == .larkUser && context.isMe(chatterId: userID, deviceId: nil)
    }

    private var hasSetMeetingTagType = false
    private func getMeetingTagType(context: VChatMeetingCardViewModelContext, content: VChatMeetingCardContent) {
        guard let account = context.account, account.tenantId != "0", let httpClient = context.httpClient else {
            meetingTagTypeRelay.accept(.none)
            return
        }
        let tenantTag = account.tenantTag
        if let localTenantTag = tenantTag, localTenantTag != .standard {
            meetingTagTypeRelay.accept(.none)
            return // 小B用户不显示外部标签
        }
        let localTenatId = account.tenantId
        let deviceId = account.deviceId
        let tenantIdSet = Set(content.allParticipantTenant.filter { String($0) != localTenatId })
        Self.logger.info("getMeetingTagType isRelationTagEnabled: \(isRelationTagEnabled), for meeting: \(content.meetingID), allParticipantTenant: \(tenantIdSet)")
        if isRelationTagEnabled, tenantIdSet.count == 1,
           let tenantId = tenantIdSet.first {
            Self.logger.info("fetch TenantInfo for tenant \(tenantId)")
            let info = VCRelationTagService.getTargetTenantInfo(httpClient: httpClient, tenantId: tenantId) { [weak self] info in
                guard let self = self else {
                    return
                }
                guard let info = info, let tag = info.relationTag?.meetingTagText else {
                    let type: MeetingTagType = content.isCrossWithKa ? .cross : .external
                    self.meetingTagTypeRelay.accept(type)
                    return
                }
                self.meetingTagTypeRelay.accept(.partner(tag))
            }

            if let info = info, let tag = info.relationTag?.meetingTagText, !hasSetMeetingTagType {
                Self.logger.info("set meetingTagType from cache")
                hasSetMeetingTagType = true
                self.meetingTagTypeRelay.accept(.partner(tag))
            }
        } else if tenantIdSet.count >= 1 {
            self.meetingTagTypeRelay.accept(content.isCrossWithKa ? .cross : .external)
        } else {
            // 兜底
            for participant in content.participants {
                if participant.deviceID == account.deviceId {
                    continue
                }
                if participant.isExternal(localDeviceId: deviceId, localTenanTag: tenantTag?.rawValue, localTenatId: localTenatId) {
                    self.meetingTagTypeRelay.accept(content.isCrossWithKa ? .cross : .external)
                    return
                }
            }
            self.meetingTagTypeRelay.accept(content.isCrossWithKa ? .cross : .none)
        }
    }

    private static func computeIsExternal(context: VChatMeetingCardViewModelContext, content: VChatMeetingCardContent) -> Bool {
        guard let account = context.account, account.tenantId != "0" else {
            return false
        }

        let localTenatId = account.tenantId
        let tenantTag = account.tenantTag
        let deviceId = account.deviceId
        if let localTenantTag = tenantTag, localTenantTag != .standard {
            return false // 小B用户不显示外部标签
        }

        for participant in content.participants {
            if participant.deviceID == deviceId {
                continue
            }

            if participant.isExternal(localDeviceId: deviceId, localTenanTag: tenantTag?.rawValue, localTenatId: localTenatId) {
                return true
            }
        }

        for tenantID in content.allParticipantTenant {
            if tenantID != Int64(localTenatId) {
                return true
            }
        }

        return false
    }

    static func getMeetingDuration(meetingId: String, httpClient: HttpClient?) -> Observable<TimeInterval> {
        guard let httpClient = httpClient else { return .empty() }
        return RxTransform.single { (completion: @escaping (Result<TimeInterval, Error>) -> Void) in
            let startTime = Date()
            httpClient.getResponse(MeetingDurationRequest(meetingId: meetingId)) {
                completion($0.map({ $0.duration(since: startTime) }))
            }
        }.asObservable()
    }

    private func updateJoinedDeviceInfo() {
        let currentMeetingId = meetingObserver?.currentMeeting?.toActiveMeeting()?.meetingId
        let meetingCardStatus = Self.computeMeetingCardStatus(context: context, currentMeetingID: currentMeetingId, content: content)
        // 本端已入会则不展示joinedDevice
        if meetingCardStatus == .joined || meetingCardStatus == .end {
            self.joinedDeviceDesc.accept(nil)
            return
        }
        self.httpClient?.getResponse(GetJoinedDeviceInfoRequest()) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                let joinedDevices = response.devices
                    .filter { $0.meetingID == self.content.meetingID }
                    .sorted(by: { $0.joinTime < $1.joinTime })
                if joinedDevices.count > 1 {
                    self.joinedDeviceDesc.accept(I18n.View_G_JoinedonOtherDevices_Desc("\(joinedDevices.count)"))
                } else if let device = joinedDevices.first {
                    self.joinedDeviceDesc.accept(I18n.View_G_AlreadyJoinedOnThisTypeOfDevice_Desc(device.defaultDeviceName))
                } else {
                    self.joinedDeviceDesc.accept(nil)
                }
                Self.logger.info("getJoinedDevices success, meetingID:\(self.content.meetingID), total:\(response.devices.count), currentMeeting:\(joinedDevices.count)")
            case .failure:
                self.joinedDeviceDesc.accept(nil)
            }
        }
    }
}

extension VChatMeetingCardViewModelImpl: MeetingObserverDelegate {
    func meetingObserver(_ observer: MeetingObserver, meetingChanged meeting: Meeting, oldValue: Meeting?) {
        if meeting.isPending { return }
        let currentMeeting = meeting.isEnd ? observer.currentMeeting : meeting
        let id = currentMeeting?.state == .onTheCall ? currentMeeting?.meetingId : nil
        if id != self.meetingIdRelay.value {
            self.meetingIdRelay.accept(id)
        }
    }
}
