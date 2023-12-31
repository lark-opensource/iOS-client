//
//  MeetTabMeetCellViewModel.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//

import Foundation
import UniverseDesignIcon
import ByteViewCommon
import ByteViewNetwork
import RxRelay

class MeetTabMeetCellViewModel: MeetTabCellViewModel {

    override var sortKey: Int64 {
        if let sortKey = Int64(vcInfo.historyID) {
            return sortKey
        } else {
            Logger.tab.error("read error historyID: \(vcInfo.historyID)")
            return 0
        }
    }

    override var loadTime: Int64 {
        return vcInfo.sortTime
    }

    override var cellIdentifier: String {
        return MeetTabHistoryDataSource.meetCellIdentifier
    }

    override var matchKey: String {
        return vcInfo.historyID
    }

    override var meetingID: String {
        return vcInfo.meetingID
    }

    var timing: String {
        DateUtil.formatDateTime(TimeInterval(vcInfo.sortTime), isRelative: true)
    }

    // todo: 启动时计算当前时差值
    private var currentTime: Int64 {
        return Int64((Date().timeIntervalSince1970 * 1000).rounded())
    }

    var isAggregated: Bool {
        return vcInfo.historyAbbrInfo.callCount > 1
    }

    let viewModel: MeetTabViewModel
    var account: AccountInfo { viewModel.account }
    var httpClient: HttpClient { viewModel.httpClient }
    let vcInfo: TabListItem
    let user: ParticipantUserInfo?

    var topic: String {
        if vcInfo.phoneType == .outsideEnterprisePhone || vcInfo.phoneType == .insideEnterprisePhone {
            return vcInfo.phoneNumber
        }
        switch vcInfo.meetingType {
        case .meet:
            if vcInfo.meetingSource == .vcFromInterview {
                return I18n.View_M_VideoInterviewNameBraces(vcInfo.meetingTopic)
            } else {
                return vcInfo.meetingTopic.isEmpty ? I18n.View_G_ServerNoTitle : vcInfo.meetingTopic
            }
        case .call:
            if vcInfo.phoneType == .ipPhone && vcInfo.historyAbbrInfo.interacterUserType == .pstnUser {
                return vcInfo.ipPhoneNumber
            } else {
                guard let name = user?.name else { return I18n.View_G_ServerNoTitle }
                return name
            }
        default:
            return I18n.View_G_ServerNoTitle
        }
    }

    var callCountText: String {
        return "(\(vcInfo.historyAbbrInfo.callCount))"
    }

    var topicColor: UIColor {
        return (vcInfo.historyAbbrInfo.callStatus == .callCanceled && vcInfo.historyAbbrInfo.historyType == .historyBeCalled) ? UIColor.ud.colorfulRed.dynamicColor : UIColor.ud.textTitle
    }

    var isOngoing: Bool {
        return vcInfo.meetingStatus == .meetingOnTheCall
    }

    var isCalendar: Bool {
        return [.vcFromCalendar, .vcFromInterview].contains(vcInfo.meetingSource)
    }

    private var hasSetMeetingTagType = false
    @RwAtomic
    private(set) var meetingTagType: MeetingTagType = .none {
        didSet {
            guard meetingTagType != oldValue else { return }
            Logger.tab.info("update meetingTagType for meeting: \(meetingTagType), \(vcInfo.meetingID), history: \(vcInfo.historyID)")
            hasSetMeetingTagType = true
            self.meetingTagTypeRelay.accept(meetingTagType)
        }
    }
    let meetingTagTypeRelay = BehaviorRelay<MeetingTagType>(value: .none)

    var isCrossWithKa: Bool {
        vcInfo.isCrossWithKa
    }

    var isExternal: Bool {
        guard account.tenantTag == .standard else { // 小B用户不显示外部标签
            return false
        }
        if vcInfo.containsMultipleTenant {
            return true
        } else {
            // sameTenantID为-1的场景是会中没有lark或room时返回
            return !vcInfo.sameTenantID.isEmpty && vcInfo.sameTenantID != "-1" && vcInfo.sameTenantID != account.tenantId
        }
    }

    // disable-lint: duplicated code
    private func getMeetingTagType() {
        let isRelationTagEnabled = self.viewModel.setting.isRelationTagEnabled
        if isRelationTagEnabled,
           vcInfo.allParticipantTenant.filter({ String($0) != account.tenantId }).count == 1,
        let tenantId = vcInfo.allParticipantTenant.first(where: { String($0) != account.tenantId }) {
            Logger.tab.info("fetch TenantInfo for tenant \(tenantId)")
            let service = MeetTabRelationTagService(httpClient: httpClient)
            let info = service.getTargetTenantInfo(tenantId: tenantId, completion: { [weak self] info in
                guard let self = self else {
                    return
                }
                guard let info = info, let tag = info.relationTag?.meetingTagText else {
                    self.meetingTagType = self.isCrossWithKa ? .cross : self.isExternal ? .external : .none
                    return
                }
                self.meetingTagType = .partner(tag)
            })

            if let info = info, let tag = info.relationTag?.meetingTagText, !hasSetMeetingTagType {
                Logger.tab.info("set meetingTagType from cache")
                self.meetingTagType = .partner(tag)
            }
        } else {
            self.meetingTagType = isCrossWithKa ? .cross : isExternal ? .external : .none
        }
    }
    // enable-lint: duplicated code

    func isIconHidden(with iconType: TabListItem.LogoType) -> Bool {
        !vcInfo.contentLogos.contains(iconType)
    }

    var descriptionColor: UIColor {
        return UIColor.ud.colorfulGreen.dynamicColor
    }

    var meetTypeIcon: UDIconType {
        return vcInfo.meetingType == .call ? .callOutlined : .videoOutlined
    }

    var coverUrl: String? {
        validMinutes.first?.coverUrl
    }

    var accessToken: String {
        account.accessToken
    }

    var previewImage: UIImage? {
        if isWebinar {
            if vcInfo.contentLogos.contains(.larkMinutes) {
                return nil
            } else {
                return BundleResources.ByteViewTab.MinutesPreview.webinarVideoColorful
            }
        } else if hasRecordInfo {
            if vcInfo.contentLogos.contains(.larkMinutes) {
                return nil
            } else {
                // 没有填充 recordInfo 时显示正常 MP4 图标
                // 填充了 recordInfo 后，判断如果 MP4 生成中或生成失败，则显示加载中图标
                if vcInfo.hasRecordInfo,
                   (vcInfo.recordInfo.recordInfo.isEmpty && vcInfo.recordInfo.url.isEmpty) || vcInfo.recordInfo.recordInfo.first?.status == .pending {
                    return UDIcon.getIconByKey(.timeOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill)
                } else {
                    return BundleResources.ByteViewTab.MinutesPreview.fileVideoColorful
                }
            }
        } else {
            if vcInfo.meetingType == .call {
                return UDIcon.getIconByKey(.callFilled, iconColor: UIColor.ud.primaryOnPrimaryFill)
            } else {
                return BundleResources.ByteViewTab.MinutesPreview.tabVideoColorful
            }
        }
    }

    var previewBgImage: UIImage? {
        guard hasRecordInfo else { return BundleResources.ByteViewTab.MinutesPreview.BG.Call }
        if vcInfo.contentLogos.contains(.larkMinutes) {
            return BundleResources.ByteViewTab.MinutesPreview.BG.Generating
        } else {
            return BundleResources.ByteViewTab.MinutesPreview.BG.Video
        }
    }

    var previewBadgeImage: UIImage? {
        guard hasRecordInfo else { return nil }
        if vcInfo.contentLogos.contains(.larkMinutes) {
            return UDIcon.getIconByKey(.tabMinutesColorful, iconColor: UIColor.ud.primaryOnPrimaryFill)
        } else {
            return nil
        }
    }

    var previewBadgeShadowColor: UIColor {
        if vcInfo.contentLogos.contains(.larkMinutes) {
            return UIColor.ud.staticBlack.withAlphaComponent(0.3)
        } else {
            return UIColor.ud.vcTokenVCannotateBgBlue.withAlphaComponent(0.3)
        }
    }

    var minutesNumber: Int {
        guard hasRecordInfo else { return 0 }
        if vcInfo.contentLogos.contains(.larkMinutes) {
            if minutesInfo.isEmpty { // 妙记生成失败服务端会传空，此时通过 contentLogos 控制
                return 1
            } else {
                return minutesInfo.count
            }
        } else {
            if vcInfo.recordInfo.recordInfo.isEmpty {
                return vcInfo.recordInfo.url.count
            } else {
                return vcInfo.recordInfo.recordInfo.count
            }
        }
    }

    private var minutesInfo: [TabDetailRecordInfo.MinutesInfo] {
        if vcInfo.recordInfo.minutesInfoV2.isEmpty {
            return vcInfo.recordInfo.minutesInfo
        } else {
            return vcInfo.recordInfo.minutesInfoV2 + vcInfo.recordInfo.minutesBreakoutInfo
        }
    }

    private var validMinutes: [TabDetailRecordInfo.MinutesInfo] {
        if minutesInfo.contains(where: { !$0.hasViewPermission }) {
            return []
        } else {
            return minutesInfo
        }
    }

    var hasRecordInfo: Bool {
        vcInfo.contentLogos.contains(.larkMinutes) ||
        vcInfo.contentLogos.contains(.record)
    }

    private var collectionInfo: [CollectionInfo] {
        vcInfo.collectionInfo.filter { collection in
            if collection.collectionType == .ai {
                return self.viewModel.fg.isSmartFolderEnabled
            } else {
                return true
            }
        }
    }

    var hasCollectionInfo: Bool {
        !collectionInfo.isEmpty
    }

    var collectionTag: String {
        collectionInfo.first(where: { collection in
            if collection.collectionType == .ai {
                return self.viewModel.fg.isSmartFolderEnabled
            } else {
                return true
            }
        })?.tagContent ?? ""
    }

    var isWebinar: Bool {
        vcInfo.meetingSubType == .webinar
    }

    init(viewModel: MeetTabViewModel, vcInfo: TabListItem, user: ParticipantUserInfo?) {
        self.viewModel = viewModel
        self.vcInfo = vcInfo
        self.user = user
        super.init()
        self.getMeetingTagType()
    }
}
