//
//  SettingDisplayItem.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/2/27.
//

import Foundation

/// 设置项
enum SettingDisplayItem: String {

    /// 日程会议开始通知
    case calendarMeetingStartNotify
    /// 进出会议时播放声音提醒
    case playEnterExitChimes
    /// 加入会议时开启字幕
    case turnOnSubtitleWhenJoin
    /// 禁用麦克风和扬声器
    case micSpeakerDisabled
    /// 会议自动云录制
    case groupMeetingAutoRecord
    /// 语音/视频通话自动云录制
    case singleMeetingAutoRecord
    /// 录制开始提醒，ViewUserSetting.DisplayBoolOption
    case recordCompliancePopup
    /// 同时播放语音提醒，ViewUserSetting.DisplayBoolOption
    case recordComplianceVoicePrompt
    /// 录制文件布局，ViewUserSetting.RecordLayoutType
    case recordLayoutType
    /// 录制内容隐藏非视频参会者
    case hideCamMutedParticipantInRecording
    /// 智能纪要
    case aiSummary
    /// 在妙记中生成智能纪要
    case generateAiSummaryInMinutes
    /// 在纪要文档中生成智能会议纪要
    case generateAiSummaryInNotes
    /// 在会议中使用AI对话
    case chatWithAiInMeet
    /// 声纹识别
    case enableVoiceprintRecognition
    /// 我的声纹
    case myVoiceprint
    /// 未接会议提醒，ViewUserSetting.MeetingAdvanced.MissedCallReminder
    case missedCallReminder
    /// 移动网络改善语音质量
    case useCellularImproveAudioQuality
    /// 智能修正标注
    case adjustAnnotate
    /// 问题反馈
    case feedback
    /// 视频镜像
    case mirrorVideo
    /// 高清画质
    case highResolution
    /// 人物居中
    case centerStage
    /// 画中画
    case pip
    /// 数据模式标准
    case dataModeStandard
    /// 数据模式节能
    case dataModeEco
    /// 数据模式语音
    case dataModeVoice
    /// 隐藏本人视图
    case hideSelfParticipant
    /// 隐藏非视频参会者
    case hideNonVideoParticipants
    /// 字幕语言
    case subtitleLanguage
    /// 口说语言
    case spokenLanguage
    /// 字幕注释
    case subtitlePhrase
    /// 表情
    case reactionSetting
    case reactionDisplayMode
    /// 聊天设置
    case chatSetting
    /// 聊天语言
    case chatLanguage
    /// 使用超声波连接
    case ultrasonicConnection
    /// 自动隐藏工具栏
    case autoHideToolbar
    /// 是否允许自己成为 ActiveSpeaker
    case enableSelfAsActiveSpeaker
    /// 长按空格暂时开麦
    case keyboardMute

    /// 显示视频分辨率
    case displayFPS
    /// 显示Codec
    case displayCodec

    /// 锁定会议
    case lockMeeting

    /// 入会范围-所有人
    case securityLevelPublic
    /// 入会范围-同租户
    case securityLevelTenant
    /// 入会范围-日程参与者
    case securityLevelCalendar
    /// 入会范围-联系人和群
    case securityLevelContactsAndGroup

    /// 开启等候室
    case lobbyOnEntry

    /// 入会自动静音
    case muteOnEntry
    /// 参会人自己打开麦克风
    case allowPartiUnmute

    /// 仅主持人可共享
    case onlyHostCanShare
    /// 仅主持人可抢占共享
    case onlyHostCanReplaceShare
    /// 仅共享人可标注
    case onlyPresenterCanAnnotate

    /// 发送表情
    case allowSendReaction
    /// 修改会中姓名
    case allowPartiChangeName
    /// 申请录制
    case allowRequestRecord
    /// 发送消息
    case allowSendMessage
    /// 使用虚拟背景
    case allowVirtualBackground
    /// 使用虚拟头像
    case allowVirtualAvatar

    /// 观众发送消息
    case allowAttendeeSendMessage
    /// 观众发送表情
    case allowAttendeeSendReaction

    /// 日程会议设置-自动录制
    case calendarMeetingAutoRecord

    case addHostHeader

    /// 添加主持人
    case addHost

    ///  backup host
    case backupHost

    case paddingCell

    case addInterpreterHeader
    /// 添加译员
    case addInterpreter
    /// 编辑译员
    case editInterpreter

    /// 彩排模式
    case rehearsalMode
    /// 允许嘉宾发起会议
    case allowPanelistStartMeeting
    /// 嘉宾权限
    case panelistPermission
    /// 观众权限
    case attendeePermission
    /// 高级选项
    case webinarAdvancedSetting

    /// 问题反馈-可以点击到下一页的cell
    case feedbackNext
    /// 问题反馈-可以选择的cell
    case feedbackSubtype
    /// 问题反馈-输入框
    case feedbackDesc

    /// （嘉宾）在日程中邀请观众
    case speakerCanInviteOthers
    /// （嘉宾）在日程中查看嘉宾列表
    case speakerCanSeeOtherSpeakers
    /// （观众）在日程中邀请观众
    case audienceCanInviteOthers
    /// （观众）在日程中查看嘉宾列表
    case audienceCanSeeOtherSpeakers

    // 进入通话时音频播放设备
    case audioOutputDevice

    /// 纪要创建权限 - 所有人
    case noteCanCreate
    /// 纪要创建权限 - 仅主持人
    case noteCanCreateByHost
    /// 纪要编辑权限 - 所有人
    case noteCanEdit
    /// 纪要编辑权限 - 仅主持人
    case noteCanEditByHost

    /// 入会开启麦克风
    case defaultMicrophoneOn
    /// 入会开启摄像头
    case defaultCameraOn
}

extension SettingDisplayItem: CustomStringConvertible {
    var description: String { rawValue }
}
