//
//  Push.swift
//  ByteViewNetwork
//
//  Created by kiri on 2023/2/16.
//

import Foundation

public struct Push {
    /// 会议信息
    /// - notifyVideoChat = 2210
    public static let notifyVideoChat = PushReceiver<VideoChatInfo>()

    /// 不会影响到状态机核心逻辑的数据推送
    /// - notifyVideoChatExtra = 2306
    /// - note：此推送为后端推给rust，rust将更新内容放入到VideoChatCombinedInfo，然后全量推给端上。
    public static let videoChatExtra = PushReceiver<VideoChatExtraInfo>()

    /// Rust-sdk向客户端push 聚合之后的data
    /// - pushVideoChatCombinedInfo = 2313
    public static let videoChatCombinedInfo = PushReceiver<VideoChatCombinedInfo>()

    /// 全量参会人
    /// - pushMeetingInfo = 87103
    public static let fullParticipants = PushReceiver<InMeetingUpdateMessage>()

    /// 参会人变化
    /// - pushMeetingParticipantChange = 87101
    public static let participantChange = PushReceiver<MeetingParticipantChange>()

    /// 会议变化通知
    /// - pushMeetingChangedInfo = 87104
    public static let inMeetingChangedInfo = PushReceiver<InMeetingChangedInfo>()

    /// 通知客户端心跳停止了
    /// - pushByteviewHeartbeatStop = 2303
    public static let heartbeatStop = PushReceiver<ByteviewHeartbeatStop>()

    /// 全量等候室参会人
    /// - pushFullVcLobbyParticipants = 89325
    public static let fullLobbyParticipants = PushReceiver<FullLobbyParticipants>()

    /// 等候室参会人变更，等候室准入/结束/转移等通知
    /// - pushVcManageResult = 89344
    public static let vcManageResult = PushReceiver<VCManageResult>()

    /// 等候室事件、举手、分组讨论事件等
    /// - pushVcManageNotify = 89343
    public static let vcManageNotify = PushReceiver<VCManageNotify>()

    /// 会中 webinar 观众变化(主持人&嘉宾视角）
    /// - pushMeetingWebinarAttendeeChange = 87106
    public static let webinarAttendeeChange = PushReceiver<MeetingParticipantChange>()

    /// 会中观众的视图列表变化（观众视角）
    /// - pushMeetingWebinarAttendeeViewChange = 87107
    public static let webinarAttendeeViewChange = PushReceiver<MeetingParticipantChange>()

    /// Groot推送的数据
    /// - pushGrootCells = 89002
    public static let grootCells = PushReceiver<PushGrootCells>()

    /// Rust通知客户端当前channel状态
    /// - pushGrootChannelStatus = 89097
    public static let grootChannelStatus = PushReceiver<PushGrootChannelStatus>()

    /// 推送通知
    /// - pushVideoChatNotice = 2215
    public static let videoChatNotice = PushReceiver<VideoChatNotice>()

    /// 推送对VideoChatNotice的更新动作
    /// - pushVideoChatNoticeUpdate = 2350
    public static let videoChatNoticeUpdate = PushReceiver<VideoChatNoticeUpdate>()

    /// 虚拟背景
    /// - pushVcVirtualBackground = 89346
    public static let virtualBackground = PushReceiver<GetVirtualBackgroundResponse>()

    /// 向群长连推送会议状态发生改变的命令字
    /// - pushAssociatedVcStatus = 2334
    public static let associatedVideoChatStatus = PushReceiver<GetAssociatedVideoChatStatusResponse>()

    /// 会中聊天消息推送
    /// - pushVideoChatInteractionMessages = 2360
    public static let interactionMessages = PushReceiver<PushVideoChatInteractionMessages>()

    /// 用户信息（更新昵称等）
    /// - pushChatters = 5010
    public static let chatters = PushReceiver<ChattersEntity>()

    /// 用户设置推送
    /// - pushViewUserSetting = 2376
    public static let viewUserSetting = PushReceiver<PullViewUserSettingResponse>()

    /// RTC数据通道
    /// - pushSendMessageToRtc = 88889
    public static let sendMessageToRtc = PushReceiver<PushSendMessageToRtcResponse>()

    /// 翻译结果推送
    /// - pushVcTranslateResults = 89382
    public static let translateResults = PushReceiver<PushTranslateResults>()

    /// RTC远端断网提示
    /// - pushVcRemoteRtcNetStatus = 89392
    public static let remoteRtcNetStatus = PushReceiver<RTCNetStatusNotify>()

    /// - pushSuggestedParticipants = 2397
    public static let suggestedParticipants = PushReceiver<InMeetingSuggestedParticipantsChanged>()

    // 会议视频链接更新推送
    // - pushCalendarEventVideoMeetingChange = 3226
    public static let calendarEventVideoMeetingChange = PushReceiver<CalendarEventVideoMeetingChangeData>()

    /// - pushEmojiPanel = 5122
    public static let emojiPanel = PushReceiver<EmojiPanelPushMessages>()

    /// vc接入im互动消息推送
    /// - pushVcMessagePreviews = 2363
    public static let messagePreviews = PushReceiver<VCMessagePreviews>()

    /// 推送VC事件卡片变化（全量信息）
    /// PUSH_VC_IM_CHAT_BANNER_CHANGE = 89223
    public static let vcEventCard = PushReceiver<GetVcImChatBannerResponse>()

    /// 推送会中设备变化信息
    /// PUSH_JOINED_DEVICES_INFO = 2319
    public static let vcJoinedDevicesInfo = PushReceiver<VCJoinedDeviceInfoChangeData>()
}

public struct ServerPush {

    /// - notifyEnterprisePhone = 89452
    public static let enterprisePhone = PushReceiver<EnterprisePhoneNotify>()

    /// 推送用户常用表情
    /// - pushUserRecentEmoji = 89314
    public static let userRecentEmoji = PushReceiver<UserRecentEmojiEvent>(shouldCacheLast: true)

    /// 会议秘钥请求推送
    /// - PUSH_E2EE_KEY_EXCHANGE = 2357
    public static let meetingKeyExchange = PushReceiver<PushE2EEKeyExchange>()
}
