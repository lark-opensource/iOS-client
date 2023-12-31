//
//  ToolBarConfiguration.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation

class ToolBarConfiguration {
    // iPhone bar 上视图显示顺序
    static let phoneMainItems: [ToolBarItemType] = [
        .microphone,
        .roomControl,
        .camera,
        .speaker,
        .participants,
        .notes,
        .handsup,
        .chat,
        .subtitle,
        .more
    ]

    /// iPhone toolbar 展开后 collectionView 里视图显示顺序
    static let phoneCollectionItems: [ToolBarItemType] = [
        // 企业信息、特效、字幕、录制、转译、My AI、共享、分组讨论 / 重新加入分组讨论 / 请求主持人帮助、多端协同、断开音频、倒计时、投票、同声传译、直播、设置
        .interviewPromotion, .interviewSpace,
        .chat,
        .effects,
        .subtitle,
        .record,
        .transcribe,
        .myai,
        .share,
        .askHostForHelp,
        .rejoinBreakoutRoom,
        .breakoutRoomHostControl,
        .room,
        .switchAudio,
        .countDown,
        .vote,
        .interpretation,
        .live,
        .settings
    ]

    /// iPad 左侧视图显示顺序
    static let padLeftItems: [ToolBarItemType] = [
        .microphone,
        .speaker,
        // 普通会议聊天表情在 pad bar 左侧，webinar 会议在中间，因此 left, center 都要写
        .reaction,
        .chat
    ]

    /// iPad 中间视图显示顺序
    static let padCenterItems: [ToolBarItemType] = [
        .roomCombined,
        .microphone,
        .camera,
        .speaker,
        .share,
        .record,
        .participants,
        // ==== for webinar ====
        .reaction,
        .chat,
        .handsup,
        // =====================
        .leaveMeeting
    ]

    /// iPad 右侧视图显示顺序
    static let padRightItems: [ToolBarItemType] = [
        .interviewPromotion, .interviewSpace,
        .notes,
        .security,
        .subtitle,
        .transcribe,
        .vote,
        .askHostForHelp, .breakoutRoomHostControl, .rejoinBreakoutRoom,
        .interpretation,
        .countDown,
        .live,
        .more
    ]

    /// iPad 更多列表内视图显示顺序，每一组是一个 section，section 之间有分割线
    static let padMoreItems: [[ToolBarItemType]] = [
        [
            // 安全、共享、录制、参会人、聊天、字幕、特效、切换音频
            .roomControl,
            .chat,
            .share,
            .record,
            .participants,
            .security,
            .subtitle,
            .effects,
            .switchAudio
        ],
        [
            // 纪要、聊天、企业信息、转录、倒计时、投票、同声传译、分组讨论、直播
            .interviewPromotion, .interviewSpace,
            .notes,
            .transcribe,
            .countDown,
            .vote,
            .interpretation,
            .askHostForHelp, .breakoutRoomHostControl, .rejoinBreakoutRoom,
            .live
        ],
        [
            .settings
        ]
    ]

    /// iPad 中间视图的收起顺序
    static let centerCollapsePriority: [ToolBarItemType] = [
        .record,
        .share,
        .participants,
        .handsup,
        .roomCombined
    ]

    /// iPad 右侧视图的收起顺序
    static let rightCollapsePriority: [ToolBarItemType] = [
        .vote,
        .askHostForHelp, .breakoutRoomHostControl, .rejoinBreakoutRoom,
        .interpretation,
        .transcribe,
        .subtitle,
        .security,
        .notes
    ]

    /// iPad 左侧、中间按钮、复合型子按钮文案隐藏的顺序
    static let centerTitleCollapsePriority: [ToolBarItemType] = [
        .record,
        .share,
        .microphone
    ]

    /// iPad 右侧按钮文案隐藏的顺序
    static let rightTitleCollapsePriority: [ToolBarItemType] = Array(padRightItems.reversed()[1...])

    /// ----------- iPad 复合型按钮 ---------
    static let combination: [ToolBarItemType: [ToolBarItemType]] = [
        .roomCombined: [.microphone, .roomControl]
    ]
}
