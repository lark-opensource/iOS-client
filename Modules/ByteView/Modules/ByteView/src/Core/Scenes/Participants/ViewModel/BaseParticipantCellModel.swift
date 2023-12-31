//
//  BaseParticipantCellModel.swift
//  ByteView
//
//  Created by wulv on 2022/2/14.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import UniverseDesignIcon
import ByteViewUDColor
import ByteViewNetwork
import UniverseDesignColor
import ByteViewSetting

/// 参会人主持人/联席主持人配置
struct ParticipantRoleConfig: Equatable {
    /// 主持人/联席主持人标签文本
    let role: String?
    /// 主持人/联席主持人背景颜色
    let bgColor: UIColor?
    /// 主持人/联席主持人标签背景颜色
    let tagBgColor: UIColor?
    /// 主持人/联席主持人标签文本颜色
    let textColor: UIColor?
    /// 主持人/联席主持人标签文本
    var roleAttributeString: NSAttributedString?
    /// 最小宽度
    var minWidth: CGFloat?

    init(role: String?, bgColor: UIColor?, tagBgColor: UIColor?, textColor: UIColor?, minWidth: CGFloat?) {
        self.role = role
        self.bgColor = bgColor
        self.tagBgColor = tagBgColor
        self.textColor = textColor
        self.minWidth = minWidth
    }

    // disable-lint: magic number
    static var hostConfig: Self {
        Self.init(role: I18n.View_M_Host, bgColor: .ud.vcTokenMeetingBgHost, tagBgColor: UIColor.ud.N600.withAlphaComponent(0.8) & UIColor.ud.N600.withAlphaComponent(0.8), textColor: .ud.primaryOnPrimaryFill, minWidth: 35)
    }

    static var cohostConfig: Self {
        Self.init(role: I18n.View_M_CoHost, bgColor: .ud.vcTokenMeetingBgCohost, tagBgColor: .ud.vcTokenMeetingTagBgCohost, textColor: .ud.vcTokenMeetingTagTextCohost, minWidth: 44)
    }
    // enable-lint: magic number
}

class BaseParticipantCellModel {
    /// 头像 (会中、邀请、等候室可空，其他非空）
    var avatarInfo: AvatarInfo?
    /// 红点
    let showRedDot: Bool
    /// 昵称
    var displayName: String?
    /// 小尾巴，展示(me、访客等)文案
    let nameTail: String?
    /// 参会人ID
    let pID: String
    let service: MeetingBasicService
    var httpClient: HttpClient { service.httpClient }
    var isRelationTagEnabled: Bool { service.setting.isRelationTagEnabled }

    /// 关联标签
    private(set) var relationTag: VCRelationTag?

    init(avatarInfo: AvatarInfo?,
         showRedDot: Bool,
         displayName: String?,
         nameTail: String?,
         pID: String,
         service: MeetingBasicService
    ) {
        self.avatarInfo = avatarInfo
        self.showRedDot = showRedDot
        self.displayName = displayName
        self.nameTail = nameTail
        self.pID = pID
        self.service = service
    }

    func isEqual(_ rhs: BaseParticipantCellModel) -> Bool {
        rhs.canEqual(self)
        && avatarInfo == rhs.avatarInfo
        && showRedDot == rhs.showRedDot
        && displayName == rhs.displayName
        && nameTail == rhs.nameTail
        && pID == rhs.pID
    }

    func canEqual(_ cellModel: BaseParticipantCellModel) -> Bool { true }

    /// 是否可以显示外部标签
    func showExternalTag() -> Bool { false }

    /// 需要请求关联标签的 user
    func relationTagUser() -> VCRelationTag.User? { nil }

    /// 需要请求关联标签的 uid
    func relationTagUserID() -> String? { nil }

    func getRelationTag(_ completion: @escaping ((UserFlagType?) -> Void)) {
        guard showExternalTag(), self.isRelationTagEnabled, let user = relationTagUser() else {
            completion(nil)
            return
        }

        if let userFlagType = UserFlagType.fromRelationTag(relationTag) {
            completion(userFlagType)
            return
        }
        httpClient.participantRelationTagService.relationTagsByUsers([user]) { [weak self] tags in
            let relationTag = tags.first
            guard let requestUID = self?.relationTagUserID(), relationTag?.userID == requestUID else {
                completion(nil)
                return
            }
            self?.relationTag = relationTag
            let userFlagType = UserFlagType.fromRelationTag(relationTag)
            completion(userFlagType)
        }
    }
}

extension BaseParticipantCellModel: Equatable {
    /**
     只有显式声明遵循协议才有对应的PWT；
     由于子类无法显式声明父类遵循的协议，所以即使重写该方法，方法调度仍然使用父类的PWT；
     为了子类有自己的实现，子类需要override`isEqual()->Bool`和`canEqual()->Bool`
     https://kukushi.github.io/blog/swift-equtable
     */
    /* final */static func == (lhs: BaseParticipantCellModel, rhs: BaseParticipantCellModel) -> Bool {
        lhs.isEqual(rhs)
    }
}

protocol ParticipantCellModelUpdate {
    func updateRole(with meeting: InMeetMeeting)
    func updateShowShareIcon(with inMeetingInfo: VideoChatInMeetingInfo?)
    func updateShowFocus(with inMeetingInfo: VideoChatInMeetingInfo?)
    func updateDeviceImg(with duplicatedParticipantIds: Set<String>)
}

extension ParticipantCellModelUpdate {
    func updateRole(with meeting: InMeetMeeting) {}
    func updateShowShareIcon(with inMeetingInfo: VideoChatInMeetingInfo?) {}
    func updateShowFocus(with inMeetingInfo: VideoChatInMeetingInfo?) {}
    func updateDeviceImg(with duplicatedParticipantIds: Set<String>) {}
}

extension Participant {

    func canBecomeHost(hostEnabled: Bool, isInterview: Bool) -> Bool {
        hostEnabled && !isLarkGuest && (!isInterview || role != .interviewee)
    }

    /// 主持人标签
    func roleConfig(hostEnabled: Bool, isInterview: Bool) -> ParticipantRoleConfig? {
        guard canBecomeHost(hostEnabled: hostEnabled, isInterview: isInterview) else { return nil }
        switch meetingRole {
        case .host: return .hostConfig
        case .coHost: return .cohostConfig
        default: return nil
        }
    }
}
