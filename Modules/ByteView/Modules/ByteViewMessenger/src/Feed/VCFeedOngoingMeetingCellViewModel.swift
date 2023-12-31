//
//  VCFeedOngoingMeetingCellViewModel.swift
//  ByteViewMessenger
//
//  Created by lutingting on 2022/9/19.
//

import Foundation
import RxSwift
import RxCocoa
import RxRelay
import Action
import ByteViewNetwork
import ByteViewCommon
import ByteViewInterface
import UniverseDesignIcon
import LarkOpenFeed
import LarkTag
import ByteViewTracker
import EENavigator
import LKCommonsLogging
import LarkSetting
import LarkContainer

protocol VCFeedOngoingMeetingCellViewModelDelegate: AnyObject {
    func needUpdateFeedOngoingMeetingCell(_ item: VCFeedOngoingMeetingCellViewModel)
}

final class VCFeedOngoingMeetingCellViewModel {

    private lazy var isRelationTagEnabled: Bool = {
        do {
            let fg = try userResolver.resolve(assert: FeatureGatingService.self)
            return fg.staticFeatureGatingValue(with: "lark.suite_admin.orm.b2b.relation_tag_for_office_apps")
        } catch {
            return false
        }
    }()

    var startTimeInterval: Int64 { return 0 }

    static let timer: Driver<Int> = Driver.interval(.seconds(1)).startWith(1)
    let grootChannelQueue: DispatchQueue = DispatchQueue(label: "ByteViewMessenger.GrootChannel")
    var isGrootChannelOpened: Bool = false

    let userResolver: UserResolver
    var httpClient: HttpClient? { try? userResolver.resolve(assert: HttpClient.self) }
    private lazy var meetingObserver = RxMeetingObserver(try? userResolver.resolve(assert: MeetingService.self).createMeetingObserver())
    private var currentMeeting: RxMeetingObserver.RxMeeting? { meetingObserver.currentMeeting }
    init(userResolver: UserResolver, vcInfo: IMNoticeInfo, delegate: VCFeedOngoingMeetingCellViewModelDelegate? = nil) {
        self.userResolver = userResolver
        self.vcInfo = vcInfo
        self.delegate = delegate
        self.getMeetingTagType()
    }

    weak var delegate: VCFeedOngoingMeetingCellViewModelDelegate?

    var sortKey: Int64 {
        vcInfo.startTime
    }

    var loadTime: Int64 {
        vcInfo.startTime
    }

    var cellIdentifier: String {
        return VCFeedOngoingMeetingCell.cellIdentifier
    }

    var matchKey: String {
        return vcInfo.meetingId
    }

    var meetingID: String {
        return vcInfo.meetingId
    }

    var timing: String {
        DateUtil.formatDateTime(TimeInterval(vcInfo.startTime), isRelative: true)
    }

    // todo: 启动时计算当前时差值
    private var currentTime: Int64 {
        return Int64((Date().timeIntervalSince1970 * 1000).rounded())
    }

    let vcInfo: IMNoticeInfo

    var topic: String {
        vcInfo.topic.isEmpty ? I18n.View_G_ServerNoTitle : vcInfo.topic
    }

    var topicColor: UIColor {
        UIColor.ud.textTitle
    }

    var isCrossWithKa: Bool {
        vcInfo.isCrossWithKa
    }

    var isExternal: Bool {
        guard let account = try? userResolver.resolve(assert: AccountInfo.self),
              let tenantTag = account.tenantTag, tenantTag == .standard else { // 小B用户不显示外部标签
            return false
        }
        if vcInfo.containsMultipleTenant {
            return true
        } else {
            return !vcInfo.sameTenantId.isEmpty && vcInfo.sameTenantId != "-1" && vcInfo.sameTenantId != account.tenantId
        }
    }

    private var hasInitMeetingTagType = false
    @RwAtomic
    private(set) var meetingTagType: MeetingTagType = .none {
        didSet {
            guard meetingTagType != oldValue else { return }
            Logger.feedOngoing.info("update meetingTagType for meeting: \(meetingTagType), \(vcInfo.meetingId)")
            if hasInitMeetingTagType {
                self.delegate?.needUpdateFeedOngoingMeetingCell(self)
            }
            self.meetingTagTypeRelay.accept(meetingTagType)
        }
    }

    let meetingTagTypeRelay = BehaviorRelay<MeetingTagType>(value: .none)

    var descriptionColor: UIColor {
        return UIColor.ud.textPlaceholder
    }

    var meetTypeIcon: UDIconType {
        .videoOutlined
    }

    var timingDriver: Driver<String> {
        let startTime: Int64 = Int64(vcInfo.startTime)
        return Self.timer.map { _ in
            DateUtil.formatDuration(Date().timeIntervalSince1970 - TimeInterval(startTime), concise: true)
        }
    }

    var meetingNumber: String {
        return "\(I18n.View_MV_IdentificationNo): \(Utils.formatMeetingNumber(vcInfo.meetingNumber))"
    }

    var isCurrentMeeting: Bool {
        currentMeeting?.id == vcInfo.meetingId
    }

    var isJoined: Bool {
        return currentMeeting?.isOnTheCall == true && isCurrentMeeting
    }

    var isInLobby: Bool {
        return currentMeeting?.isInLobby == true && isCurrentMeeting
    }

    /// 正在彩排中
    var isRehearsing: Bool {
        return vcInfo.meetingSubType == .webinar && vcInfo.rehearsalStatus == .on
    }

    private var joinButtonTitle: String {
        if isCurrentMeeting {
            if isInLobby {
                return I18n.View_MV_WaitingRightNow
            } else if isJoined {
                return isRehearsing ? I18n.View_G_JoinRehearsal_Button : I18n.View_MV_JoinedAlready
            } else {
                return isRehearsing ? I18n.View_G_JoinRehearsal_Button : I18n.View_MV_JoinRightNow
            }
        } else {
            // V5.11 无论是否锁定、是否开启等候室，都展示加入
            return isRehearsing ? I18n.View_G_JoinRehearsal_Button : I18n.View_MV_JoinRightNow
        }
    }

//    private let joinButtonTitleRelay: Behav
    var joinButtonTitleDriver: Driver<String> {
        meetingObserver.relay.asDriver()
            .compactMap { [weak self] _ in
                return self?.joinButtonTitle
            }.startWith(joinButtonTitle)
    }

    var joinAction: CocoaAction {
        return CocoaAction { [weak self] _ in
            guard let self = self else { return Observable<()>.empty() }
            self.joinMeeting()
            return .empty()
        }
    }

    private var navigator: Navigatable { userResolver.navigator }
    private func joinMeeting() {
        VCTracker.post(name: .navigation_event_list_click, params: [.click: "join_vc", .target: .none])
        let body = JoinMeetingBody(id: vcInfo.meetingId, idType: .meetingId, entrySource: .imNotice, topic: vcInfo.topic, meetingSubtype: vcInfo.meetingSubType.rawValue)
        let fromVC = navigator.mainSceneWindow?.fromViewController ?? UIViewController()
        userResolver.navigator.present(body: body, from: fromVC)
    }

    private func getMeetingTagType() {
        guard let account = try? userResolver.resolve(assert: AccountInfo.self), let httpClient = self.httpClient else { return }
        Logger.feedOngoing.info("getMeetingTagType isRelationTagEnabled: \(isRelationTagEnabled), for meeting: \(vcInfo.meetingId), \(vcInfo.allParticipantTenant)")
        if isRelationTagEnabled,
           vcInfo.allParticipantTenant.filter({ String($0) != account.tenantId }).count == 1,
        let tenantId = vcInfo.allParticipantTenant.first(where: {String($0) != account.tenantId }) {
            Logger.feedOngoing.info("fetch TenantInfo for tenant \(tenantId)")
            let info = VCRelationTagService.getTargetTenantInfo(httpClient: httpClient, tenantId: tenantId, completion: { [weak self] info in
                guard let self = self else {
                    return
                }
                guard let info = info, let tag = info.relationTag?.meetingTagText else {
                    self.meetingTagType = self.isCrossWithKa ? .cross : self.isExternal ? .external : .none
                    return
                }
                self.meetingTagType = .partner(tag)
            })

            if let info = info, let tag = info.relationTag?.meetingTagText, !hasInitMeetingTagType {
                Logger.feedOngoing.info("set meetingTagType from cache")
                self.meetingTagType = .partner(tag)
            }
            hasInitMeetingTagType = true
        } else {
            self.meetingTagType = isCrossWithKa ? .cross : isExternal ? .external : .none
        }
    }
}

extension VCFeedOngoingMeetingCellViewModel: EventItem, EventFeedHeaderViewItem, EventListCellItem {

    var reuseId: String { VCFeedOngoingMeetingCell.cellIdentifier }
    var calHeightMode: EventListCellCalHeightMode { .manualDimension(72) } // 默认自动计算高度

    // EventFeedHeaderView
    var icon: UIImage {
        UDIcon.getIconByKey(.videoFilled, iconColor: UIColor.ud.functionSuccessFillDefault)
    }

    var status: String {
        I18n.Lark_Event_EventInProgress_Status
    }

    var title: String {
        topic
    }

    var tags: [LarkTag.TagType] {[]}

    var tagItems: [LarkTag.Tag] {
        switch self.meetingTagType {
        case .external:
            return [Tag(type: .external)]
        case .cross:
            return [Tag(type: .connect)]
        case .partner(let tag):
            return [Tag(title: tag, style: .blue, type: .relation)]
        case .none:
            return []
        }
    }

    // EventItem
    var biz: EventBiz { .vc }


    var id: String {
        matchKey
    }

    var position: Int {
        Int(sortKey)
    }

    func tap() {
        joinMeeting()
    }

    var description: String {
        "VCFeedOngoingMeetingCellViewModel, biz: \(biz), id: \(id), position: \(position)"
    }
}

private final class RxMeetingObserver: MeetingObserverDelegate {
    private let proxy: MeetingObserver?
    let relay: BehaviorRelay<RxMeeting?>
    var currentMeeting: RxMeeting? { relay.value }

    init(_ proxy: MeetingObserver?) {
        self.proxy = proxy
        if let proxy {
            self.relay = .init(value: proxy.currentRxMeeting)
            proxy.setDelegate(self)
        } else {
            self.relay = .init(value: nil)
        }
    }

    func meetingObserver(_ observer: MeetingObserver, meetingChanged meeting: Meeting, oldValue: Meeting?) {
        if meeting.isPending { return }
        let obj = meeting.state == .end ? observer.currentRxMeeting : observer.convertToRx(meeting)
        if relay.value != obj {
            relay.accept(obj)
        }
    }

    struct RxMeeting: Equatable {
        let id: String
        let isOnTheCall: Bool
        let isInLobby: Bool
    }
}

private extension MeetingObserver {
    var currentRxMeeting: RxMeetingObserver.RxMeeting? {
        currentMeeting.flatMap({ convertToRx($0) })
    }

    func convertToRx(_ meeting: Meeting) -> RxMeetingObserver.RxMeeting? {
        guard !meeting.isPending, let meeting = meeting.toActiveMeeting() else { return nil }
        return .init(id: meeting.meetingId, isOnTheCall: meeting.state == .onTheCall, isInLobby: meeting.isInLobby)
    }
}
