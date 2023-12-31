//
// Created by maozhixiang.lip on 2022/7/12.
//

import Foundation
import RxSwift
import RxCocoa
import ByteViewNetwork
import ByteViewCommon
import ByteViewSetting

protocol BreakoutRoomHostControlListener {
    func updateToolbarItem(badge: ToolBarBadgeType)
    func updateBreakoutRoomAttention(attention: BreakoutRoomAttention)
}

enum BreakoutRoomAttention {
    case none
    case one(VCManageNotify.BreakoutRoomUser, ParticipantUserInfo, ByteViewNetwork.BreakoutRoomInfo)
    case many(Int)
}

class BreakoutRoomHostControlViewModel {
    private static let logger = Logger.breakoutRoom
    private var toolbarItemTapped: Bool {
        get { meeting.storage.bool(forKey: .tapToolbarForBreakoutRoom) }
        set { meeting.storage.set(newValue, forKey: .tapToolbarForBreakoutRoom) }
    }

    private let meeting: InMeetMeeting
    private let meetingRoleRelay: BehaviorRelay<Participant.MeetingRole> = .init(value: .participant)
    private let hostControlEnabledRelay: BehaviorRelay<Bool>
    private let breakoutRoomInfoRelay: BehaviorRelay<[BreakoutRoomInfo]> = .init(value: [])
    private let participantsRelay: BehaviorRelay<[Participant]> = .init(value: [])
    private let needHelpUsersRelay: BehaviorRelay<[VCManageNotify.BreakoutRoomUser]> = .init(value: [])
    private let toolbarGuideShouldShowRelay: BehaviorRelay<Bool> = .init(value: false)
    private let toolbarGuideShowedRelay: BehaviorRelay<Bool> = .init(value: false)
    private lazy var toolbarItemTappedRelay: BehaviorRelay<Bool> = .init(value: toolbarItemTapped)
    private let listenerRegistry = BreakoutRoomHostControlListenerRegistry()
    private let disposeBag = DisposeBag()
    private var roomsExpandStatus = [String: Bool]()

    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        self.hostControlEnabledRelay = .init(value: meeting.setting.showsBreakoutRoomHostControl)
        self.meeting.addMyselfListener(self, fireImmediately: true)
        self.meeting.data.addListener(self, fireImmediately: true)
        self.meeting.participant.addListener(self)
        self.meeting.setting.addListener(self, for: .showsBreakoutRoomHostControl)
        self.meeting.push.vcManageNotify.addObserver(self)
        self.driveListeners()
    }

    func didShowToolbarGuide() {
        guard !self.toolbarGuideShowedRelay.value else { return }
        self.toolbarGuideShowedRelay.accept(true)
    }

    func didTapToolbarItem() {
        guard !self.toolbarItemTappedRelay.value else { return }
        self.toolbarItemTapped = true
        self.toolbarItemTappedRelay.accept(true)
    }

    func addListener(_ listener: BreakoutRoomHostControlListener) {
        self.listenerRegistry.addListener(listener)
    }

    private func buildBreakoutRoomModels(_ rooms: [BreakoutRoomInfo],
                                         _ participants: [Participant],
                                         _ participantInfos: [ParticipantUserInfo]) -> [BreakoutRoomModel] {
        let infoDict = participantInfos
            .reduce(into: [ByteviewUser: ParticipantUserInfo]()) { dict, info in
                guard let user = info.pid?.pid else { return }
                dict[user] = info
            }
        let uidCount = participants
            .reduce(into: [:]) { dict, p in dict[p.user.id] = (dict[p.user.id] ?? 0) + 1 }
        let groupedParticipants = participants
            .compactMap { p -> BreakoutRoomParticipantModel? in
                guard let info = infoDict[p.user] else { return nil }
                let isDuplicated = (uidCount[p.user.id] ?? 0) > 1
                return BreakoutRoomParticipantModel(p, info, isDuplicated)
            }
            .groupBy { $0.breakoutRoomId }
            .reduce(into: [:]) { dict, pair in dict[pair.0] = pair.1 }
        let expandStatus = self.roomsExpandStatus
        return rooms
            .map { room in
                let roomId = room.breakoutRoomId
                let roomParticipants = groupedParticipants[roomId] ?? []
                return BreakoutRoomModel(
                    info: room,
                    participants: roomParticipants.sorted { $0.sortKey < $1.sortKey },
                    expanded: expandStatus[room.breakoutRoomId] ?? true,
                    onToggleExpanded: { [weak self] roomID, expanded in
                        self?.roomsExpandStatus[roomID] = expanded
                    }
                )
            }
            .sorted { $0.sortKey < $1.sortKey }
    }

    private func fetchParticipantInfo(_ participants: [ParticipantIdConvertible]) -> Driver<[ParticipantUserInfo]> {
        let meetingID = self.meeting.meetingId
        let participantService = self.meeting.httpClient.participantService
        return Observable
            .create { [weak self] observer in
                participantService.participantInfo(pids: participants, meetingId: meetingID) { infos in
                    if self != nil { observer.onNext(infos) }
                    observer.onCompleted()
                }
                return Disposables.create()
            }
            .asDriver(onErrorJustReturn: [])
    }

    class BreakoutRoomParticipantModel {
        private let participant: Participant
        private let participantInfo: ParticipantUserInfo
        private(set) var isDuplicated: Bool

        init(_ participant: Participant, _ info: ParticipantUserInfo, _ isDuplicated: Bool) {
            self.participant = participant
            self.participantInfo = info
            self.isDuplicated = isDuplicated
        }

        var breakoutRoomId: String {
            BreakoutRoomUtil.isMainRoom(participant.breakoutRoomId)
                ? participant.hostSetBreakoutRoomID
                : participant.breakoutRoomId
        }
        var isNotInRoom: Bool {
            BreakoutRoomUtil.isMainRoom(participant.breakoutRoomId)
                && participant.breakoutRoomId != participant.hostSetBreakoutRoomID
        }
        var name: String { participantInfo.name }
        var needHelp: Bool { participant.breakoutRoomStatus?.needHelp ?? false }
        var sortKey: (Int, String) {
            var priority: Int = 0
            priority = (priority << 1) | (needHelp ? 1 : 0)
            priority = (priority << 1) | (participant.meetingRole == .host ? 1 : 0)
            priority = (priority << 1) | (participant.meetingRole == .coHost ? 1 : 0)
            return (-priority, name)
        }

        func toInMeetParticipantCellModel(_ meeting: InMeetMeeting) -> InMeetParticipantCellModel {
            .create(
                with: participant,
                userInfo: participantInfo,
                meeting: meeting,
                hasCohostAuthority: meeting.setting.hasCohostAuthority,
                hostEnabled: meeting.setting.isHostEnabled,
                isDuplicated: isDuplicated,
                magicShareDocument: nil
            )
        }
    }

    class BreakoutRoomModel {
        private let info: BreakoutRoomInfo
        private let onToggleExpanded: (String, Bool) -> Void
        private let participants: [BreakoutRoomParticipantModel]

        var expanded: Bool {
            didSet {
                self.onToggleExpanded(info.breakoutRoomId, expanded)
            }
        }

        init(info: BreakoutRoomInfo,
             participants: [BreakoutRoomParticipantModel] = [],
             expanded: Bool,
             onToggleExpanded: @escaping (String, Bool) -> Void) {
            self.info = info
            self.participants = participants
            self.expanded = expanded
            self.onToggleExpanded = onToggleExpanded
        }

        var id: String { info.breakoutRoomId }
        var topic: String { info.topic }
        var isOnTheCall: Bool { info.status == .onTheCall }
        var needHelp: Bool { participants.contains { $0.needHelp } }
        var visibleParticipants: [BreakoutRoomParticipantModel] { expanded ? participants : [] }
        var participantCount: Int { participants.count }
        var sortKey: (Int, Int64, String) {
            var priority: Int = 0
            priority = (priority << 1) | (needHelp ? 1 : 0)
            return (-priority, info.startTime, info.topic)
        }
    }
}

extension BreakoutRoomHostControlViewModel: InMeetDataListener {
    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        if inMeetingInfo.breakoutRoomInfos != oldValue?.breakoutRoomInfos {
            self.breakoutRoomInfoRelay.accept(inMeetingInfo.breakoutRoomInfos)
            Self.logger.debug("breakoutRoomInfos changed, current = \(inMeetingInfo.breakoutRoomInfos)")
        }
    }
}

extension BreakoutRoomHostControlViewModel: InMeetParticipantListener {
    func didChangeGlobalParticipants(_ output: InMeetParticipantOutput) {
        participantsRelay.accept(output.newData.all)
    }
}

extension BreakoutRoomHostControlViewModel: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        if myself.meetingRole != self.meetingRoleRelay.value {
            self.meetingRoleRelay.accept(myself.meetingRole)
            Self.logger.debug("meetingRole changed, current role = \(myself.meetingRole)")
        }
    }
}

extension BreakoutRoomHostControlViewModel: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        guard key == .showsBreakoutRoomHostControl else { return }
        if self.hostControlEnabledRelay.value != isOn {
            self.hostControlEnabledRelay.accept(isOn)
            if !isOn {
                // 撤销分组会议管控权限时需要清除请求帮助用户列表，以避免再次获得
                // 管控权限时重复弹请求帮助窗口。
                self.needHelpUsersRelay.accept([])
            }
        }
    }
}

extension BreakoutRoomHostControlViewModel: VCManageNotifyPushObserver {
    func didReceiveManageNotify(_ notify: VCManageNotify) {
        Self.logger.debug("VCManageNotify received. notification = \(notify)")
        switch notify.notificationType {
        case .breakoutRoomUserNeedHelp:
            self.needHelpUsersRelay.accept(notify.needHelpUsers)
            return
        case .breakoutRoomUserGotHelp:
            self.showGotHelpToast(notify.helper)
            return
        case .breakoutRoomStarted:
            self.toolbarGuideShouldShowRelay.accept(true)
            return
        default:
            return
        }
    }

    private func showGotHelpToast(_ helper: VCManageNotify.BreakoutRoomUser) {
        guard let roomInfo = self.breakoutRoomInfoRelay.value.first(where: { $0.breakoutRoomId == helper.breakoutRoomId }) else { return }
        meeting.httpClient.participantService.participantInfo(pid: helper.user, meetingId: self.meeting.meetingId) { info in
            let toastContent = I18n.View_G_NameInRoomHandle(info.name, roomInfo.topic)
            Toast.show(toastContent)
        }
    }
}

extension BreakoutRoomHostControlViewModel {
    var hostControlEnabled: Driver<Bool> {
        self.hostControlEnabledRelay.asDriver()
    }

    var showToolbarItem: Driver<Bool> {
        self.hostControlEnabled
    }

    var toolbarItemBadge: Driver<ToolBarBadgeType> {
        Driver
            .combineLatest(
                self.hostControlEnabled,
                self.toolbarItemTappedRelay.asDriver(),
                self.needHelpUsersRelay.asDriver())
            .map { enabled, tapped, needHelpUsers in
                guard enabled else { return .none }
                if !needHelpUsers.isEmpty { return .dot }
                return tapped ? .none : .dot
            }
    }

    var showToolbarGuide: Driver<Bool> {
        Driver
            .combineLatest(
                self.hostControlEnabled,
                self.toolbarGuideShouldShowRelay.asDriver(),
                self.toolbarGuideShowedRelay.asDriver())
            .map { enabled, shouldShow, showed in enabled && shouldShow && !showed }
            .distinctUntilChanged()
    }

    var showEndButton: Driver<Bool> {
        Driver
            .combineLatest(
                self.meetingRoleRelay.asDriver(),
                self.breakoutRoomInfoRelay.asDriver())
            .map { role, rooms in role == .host && rooms.contains { $0.status == .onTheCall } }
            .distinctUntilChanged()
    }

    var breakoutRooms: Driver<[BreakoutRoomModel]> {
        Driver
            .combineLatest(
                self.breakoutRoomInfoRelay.asDriver(),
                self.participantsRelay.asDriver())
            .throttle(.milliseconds(1000))
            .flatMapLatest { [weak self] rooms, participants in
                guard let self = self else { return .empty() }
                let breakoutRoomParticipants = participants.filter {
                    !$0.isInMainBreakoutRoom || !BreakoutRoomUtil.isMainRoom($0.hostSetBreakoutRoomID)
                }
                return self.fetchParticipantInfo(breakoutRoomParticipants).map { infos in
                    self.buildBreakoutRoomModels(rooms, breakoutRoomParticipants, infos)
                }
            }
    }

    var attention: Driver<BreakoutRoomAttention> {
        Driver
            .combineLatest(
                self.hostControlEnabled.asDriver(),
                self.needHelpUsersRelay.asDriver(),
                self.breakoutRoomInfoRelay.asDriver())
            .flatMapLatest { [weak self] enabled, users, rooms in
                guard let self = self, enabled else { return .just(.none) }
                if users.isEmpty { return .just(.none) }
                if users.count > 1 { return .just(.many(users.count)) }
                let roomId = users[0].breakoutRoomId
                guard let roomInfo = rooms.first(where: { $0.breakoutRoomId == roomId }) else { return .empty() }
                return self.fetchParticipantInfo([users[0].user]).map { infos -> BreakoutRoomAttention in
                    guard let userInfo = infos.first else { return .none }
                    return .one(users[0], userInfo, roomInfo)
                }
            }
    }

    private func driveListeners() {
        self.toolbarItemBadge
            .drive(onNext: { [weak self] in self?.listenerRegistry.updateToolbarItem(badge: $0) })
            .disposed(by: self.disposeBag)
        self.showToolbarGuide
            .filter { $0 }
            .drive(onNext: { [weak self] _ in
                self?.showGuide()
            })
            .disposed(by: self.disposeBag)
        self.attention
            .drive(onNext: { [weak self] in self?.listenerRegistry.updateBreakoutRoomAttention(attention: $0) })
            .disposed(by: self.disposeBag)
    }

    private func showGuide() {
        let guide = GuideDescriptor(type: .breakoutRoomHostControl, title: nil, desc: I18n.View_MV_StartedYouJoinFree)
        guide.style = .darkPlain
        guide.sureAction = { [weak self] in self?.didShowToolbarGuide() }
        guide.duration = 3
        GuideManager.shared.request(guide: guide)
    }
}

extension BreakoutRoomHostControlListener {
    func updateToolbarItem(badge: ToolBarBadgeType) {}
    func updateBreakoutRoomAttention(attention: BreakoutRoomAttention) {}
}

private class BreakoutRoomHostControlListenerRegistry: BreakoutRoomHostControlListener {
    private let listeners = Listeners<BreakoutRoomHostControlListener>()

    private var lastToolbarItemParam: ToolBarBadgeType?
    private var lastBreakoutRoomAttentionParam: BreakoutRoomAttention?

    func updateToolbarItem(badge: ToolBarBadgeType) {
        self.lastToolbarItemParam = badge
        self.listeners.forEach { $0.updateToolbarItem(badge: badge) }
    }

    func updateBreakoutRoomAttention(attention: BreakoutRoomAttention) {
        self.lastBreakoutRoomAttentionParam = attention
        self.listeners.forEach { $0.updateBreakoutRoomAttention(attention: attention) }
    }

    func addListener(_ listener: BreakoutRoomHostControlListener) {
        self.listeners.addListener(listener)
        if let param = self.lastToolbarItemParam { listener.updateToolbarItem(badge: param) }
        if let param = self.lastBreakoutRoomAttentionParam { listener.updateBreakoutRoomAttention(attention: param) }
    }
}
