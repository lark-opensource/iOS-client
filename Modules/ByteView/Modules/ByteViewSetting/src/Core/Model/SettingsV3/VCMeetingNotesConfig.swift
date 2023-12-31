//
//  VCMeetingNotesConfig.swift
//  ByteViewSetting
//
//  Created by liurundong.henry on 2023/9/8.
//

import Foundation

// settings_key = vc_meeting_notes_config
// https://cloud.bytedance.net/appSettings-v2/detail/config/182212/detail/status
public struct VCMeetingNotesConfig: Decodable {
    /// rust控制的客户端限流
    public let loadQps: Int
    /// 纪要按钮请求头像的间隔（会议人数不足阈值时使用）
    public let request_avatar_interval_n1_s: Int
    /// 纪要按钮请求头像的间隔（会议人数不低于阈值时使用）
    public let request_avatar_interval_n2_s: Int
    /// 纪要按钮请求头像的间隔时间阈值
    public let request_avatar_interval_threshold: Int
    public static let `default` = VCMeetingNotesConfig(loadQps: 100,
                                                       request_avatar_interval_n1_s: 30,
                                                       request_avatar_interval_n2_s: 120,
                                                       request_avatar_interval_threshold: 100)
}

public extension VCMeetingNotesConfig {
    /// 传入当前会议的参会人数量，获取请求纪要协作者数据的时间间隔，单位秒
    /// - Parameter currentParticipantsCount: 当前会议的参会人数量
    /// - Returns: 纪要协作者数据的时间间隔，单位秒
    func getNotesCollaboratorsSyncRequestTimeInterval(currentParticipantsCount: Int) -> Int {
        return currentParticipantsCount < request_avatar_interval_threshold ? request_avatar_interval_n1_s : request_avatar_interval_n2_s
    }
}
