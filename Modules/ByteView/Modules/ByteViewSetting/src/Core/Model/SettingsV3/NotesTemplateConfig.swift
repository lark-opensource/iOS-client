//
//  NotesTemplateConfig.swift
//  ByteViewSetting
//
//  Created by liurundong.henry on 2023/6/29.
//

import Foundation

// settings_key = notes_template_category_id_config
// https://cloud.bytedance.net/appSettings-v2/detail/config/173374/detail/status
// disable-lint: magic number
public struct NotesTemplateConfig: Decodable {
    /// 1v1
    public let vcCallMeeting: Int
    /// 群聊会议
    public let vcNormalMeeting: Int
    /// 日程会议
    public let vcCalendarMeeting: Int
    /// 创建日程（VC未使用）
    public let calendarCreate: Int

    /// 如果没拉取到，返回-1，需要使用方根据用户是国内/海外来判断使用哪个默认值
    static let `default` = NotesTemplateConfig(vcCallMeeting: -1,
                                               vcNormalMeeting: -1,
                                               vcCalendarMeeting: -1,
                                               calendarCreate: -1)

    public static let feishuConfig = NotesTemplateConfig(vcCallMeeting: 1399,
                                                         vcNormalMeeting: 1398,
                                                         vcCalendarMeeting: 1397,
                                                         calendarCreate: 1397)

    public static let larkConfig = NotesTemplateConfig(vcCallMeeting: 1001183,
                                                       vcNormalMeeting: 1001182,
                                                       vcCalendarMeeting: 1001181,
                                                       calendarCreate: 1001181)
}
