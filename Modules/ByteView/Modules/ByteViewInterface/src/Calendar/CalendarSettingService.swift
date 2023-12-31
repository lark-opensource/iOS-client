//
//  CalendarSettingService.swift
//  ByteViewInterface
//
//  Created by wangpeiran on 2021/12/19.
//

import Foundation

public protocol CalendarSettingService {
    /// 日程设置初次打开视频设置
    /// - Parameters:
    ///  - vcSettingId: 用户设置id
    ///  - callback: 信息回调
    func openSettingForStart(vcSettingId: String?, from: UIViewController,
                             completion: @escaping (Result<CalendarSettingResponse, Error>) -> Void)

    /// 创建 webinar 会议设置页
    func createWebinarConfigController(param: WebinarConfigParam) -> UIViewController?

    /// 获取 webinar 会议设置页信息
    /// param vc: webinar 会议设置页
    func getWebinarLocalConfig(vc: UIViewController) -> Result<WebinarConfigParam, Error>?

    /// 预约会议时，获取最大参会人数上限
    func pullWebinarMaxParticipantsCount(organizerTenantId: Int64, organizerUserId: Int64, completion: @escaping (Result<Int64, Error>) -> Void)

    func pullWebinarSuiteQuota(completion: @escaping (Result<Bool, Error>) -> Void)
}

public struct WebinarConfigParam {
    /// 会议设置
    public let configJson: String?
    /// 嘉宾权限：日程邀请参与者
    public let speakerCanInviteOthers: Bool
    /// 嘉宾权限：在日程中查看嘉宾列表
    public let speakerCanSeeOtherSpeakers: Bool
    /// 观众权限：日程邀请参与者
    public let audienceCanInviteOthers: Bool
    /// 观众权限：在日程中查看嘉宾列表
    public let audienceCanSeeOtherSpeakers: Bool

    public init(configJson: String?, speakerCanInviteOthers: Bool, speakerCanSeeOtherSpeakers: Bool, audienceCanInviteOthers: Bool, audienceCanSeeOtherSpeakers: Bool) {
        self.configJson = configJson
        self.speakerCanInviteOthers = speakerCanInviteOthers
        self.speakerCanSeeOtherSpeakers = speakerCanSeeOtherSpeakers
        self.audienceCanInviteOthers = audienceCanInviteOthers
        self.audienceCanSeeOtherSpeakers = audienceCanSeeOtherSpeakers
    }
}

public struct CalendarSettingResponse {
    public var vcSettingId: String

    public init(vcSettingId: String) {
        self.vcSettingId = vcSettingId
    }
}
