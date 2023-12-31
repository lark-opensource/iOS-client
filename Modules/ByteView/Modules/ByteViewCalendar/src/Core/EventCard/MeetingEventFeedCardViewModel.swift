//
//  MeetingEventFeedCardViewModel.swift
//  ByteViewCalendar
//
//  Created by lutingting on 2023/8/2.
//

import Foundation
import CalendarFoundation
import RxSwift
import RxCocoa
import ByteViewNetwork
import ByteViewCommon
import LarkSetting
import UniverseDesignIcon
import ByteViewTracker
import LKCommonsLogging
import LarkContainer
import ByteViewInterface

final class MeetingEventFeedCardViewModel {

    static let log = Logger.getLogger("EventFeedCard")
    static let timer: Driver<Int> = Driver.interval(.seconds(1)).startWith(1)

    let userResolver: UserResolver
    let vcInfo: IMNoticeInfo
    let trace: EventFeedCardTrace

    var updateTagClosure: ((MeetingTagType) -> Void)?

    private lazy var isRelationTagEnabled: Bool = {
        do {
            let fg = try userResolver.resolve(assert: FeatureGatingService.self)
            return fg.staticFeatureGatingValue(with: "lark.suite_admin.orm.b2b.relation_tag_for_office_apps")
        } catch {
            return false
        }
    }()

    var startTime: Int64 { vcInfo.startTime }
    var meetingId: String { vcInfo.meetingId }
    var topic: String { vcInfo.topic.isEmpty ? I18n.View_G_ServerNoTitle : vcInfo.topic }
    var isCrossWithKa: Bool { vcInfo.isCrossWithKa }

    var timingDriver: Driver<String> {
        let startTime: Int64 = Int64(vcInfo.startTime)
        return Self.timer.map { _ in
            DateUtil.formatDuration(Date().timeIntervalSince1970 - TimeInterval(startTime), concise: true)
        }
    }

    var isExternal: Bool {
        guard let account = self.account, let tenantTag = account.tenantTag, tenantTag == .standard else { // 小B用户不显示外部标签
            return false
        }
        if vcInfo.containsMultipleTenant {
            return true
        } else {
            return vcInfo.sameTenantId.isEmpty ? false : vcInfo.sameTenantId != account.tenantId
        }
    }

    private var hasInitMeetingTagType = false

    @RwAtomic
    private(set) var meetingTagType: MeetingTagType = .none {
        didSet {
            guard meetingTagType != oldValue else { return }
            Self.log.info("update meetingTagType for meeting: \(meetingTagType), \(vcInfo.meetingId)")
            updateTagClosure?(meetingTagType)
        }
    }

    var meetingNumber: String { "\(I18n.View_MV_IdentificationNo): \(formatMeetingNumber(vcInfo.meetingNumber))" }

    /// 正在彩排中
    var isRehearsing: Bool { vcInfo.meetingSubType == .webinar && vcInfo.rehearsalStatus == .on }
    var isWebinar: Bool { vcInfo.meetingSubType == .webinar }
    var account: AccountInfo? { try? userResolver.resolve(assert: AccountInfo.self) }
    var httpClient: HttpClient? { try? userResolver.resolve(assert: HttpClient.self) }

    init(userResolver: UserResolver, vcInfo: IMNoticeInfo, trace: EventFeedCardTrace) {
        self.userResolver = userResolver
        self.vcInfo = vcInfo
        self.trace = trace
        self.getMeetingTagType()
    }

    private func getMeetingTagType() {
        guard let account = self.account, let httpClient = self.httpClient else { return }
        Self.log.info("getMeetingTagType isRelationTagEnabled: \(isRelationTagEnabled), for meeting: \(vcInfo.meetingId), \(vcInfo.allParticipantTenant)")
        if isRelationTagEnabled,
           vcInfo.allParticipantTenant.filter({ String($0) != account.tenantId }).count == 1,
        let tenantId = vcInfo.allParticipantTenant.first(where: {String($0) != account.tenantId }) {
            Self.log.info("fetch TenantInfo for tenant \(tenantId)")
            let info = getTargetTenantInfo(httpClient: httpClient, tenantId: tenantId, completion: { [weak self] info in
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
                Self.log.info("set meetingTagType from cache")
                self.meetingTagType = .partner(tag)
            }
            hasInitMeetingTagType = true
        } else {
            self.meetingTagType = isCrossWithKa ? .cross : isExternal ? .external : .none
        }
    }

    func getTargetTenantInfo(httpClient: HttpClient, tenantId: Int64, completion: @escaping (TargetTenantInfo?) -> Void) -> TargetTenantInfo? {
        let request = GetTargetTenantInfoRequest(targetTenantIds: [tenantId])
        httpClient.getResponse(request) { result in
            switch result {
            case .success(let resp):
                if let info = resp.targetTenantInfos.first(where: {$0.key == tenantId}) {
                    Self.log.info("fetch TenantInfo for tenant \(tenantId) success")
                    RelationTagCache.shared.storeTenantInfo(info.value, id: String(info.key))
                    completion(info.value)
                    return
                } else {
                    Self.log.info("fetch TenantInfo for tenant \(tenantId) error: no info in response")
                }
            case .failure(let error):
                Self.log.info("fetch TenantInfo for tenant \(tenantId) error: \(error)")
            }
            completion(nil)
        }

        return RelationTagCache.shared.tenantInfo(String(tenantId))
    }

    private func formatMeetingNumber(_ meetingNumber: String) -> String {
        let s = meetingNumber
        guard s.count >= 9 else {
            return ""
        }
        let index1 = s.index(s.startIndex, offsetBy: 3)
        let offset: Int = -3
        let index2 = s.index(s.endIndex, offsetBy: offset)
        return "\(s[..<index1]) \(s[index1..<index2]) \(s[index2..<s.endIndex])"
    }

    func joinMeeting() {
        VCTracker.post(name: .feed_event_list_click, params: [.click: "enter_vc", "is_top": trace.feedIsTop, "feed_tab": trace.feedTab])
        let navigator = userResolver.navigator
        let body = JoinMeetingBody(id: vcInfo.meetingId, idType: .meetingId, entrySource: .eventCard, topic: vcInfo.topic, meetingSubtype: vcInfo.meetingSubType.rawValue)
        let fromVC = navigator.mainSceneWindow?.fromViewController ?? UIViewController()
        navigator.present(body: body, from: fromVC)
    }
}

extension MeetingEventFeedCardViewModel: EventFeedCardModel {

    var sortTime: Int64 { startTime }

    /// 指meetingId
    var cardID: String { meetingId }

    var cardType: EventFeedCardType { .vc }
}

enum MeetingTagType: Equatable {
    case none
    /// 外部
    case external
    /// 互通
    case cross
    /// 关联租户
    case partner(String)

    var text: String? {
        switch self {
        case .external:
            return I18n.View_G_ExternalLabel
        case .cross:
            return I18n.View_G_ConnectLabel
        case .partner(let relationTag):
            return relationTag
        case .none:
            return nil
        }
    }
}
