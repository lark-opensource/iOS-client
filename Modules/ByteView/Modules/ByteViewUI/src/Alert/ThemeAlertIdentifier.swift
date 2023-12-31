//
//  ThemeAlertIdentifier.swift
//  ByteViewUI
//
//  Created by kiri on 2023/1/18.
//

import Foundation

public enum ThemeAlertIdentifier: String {
    case microphone
    case camera
    case rejoinMeeting
    case joinMeeting
    case exitCallByJoinMeeting
    case exitMeetingByLogout
    case startMeeting
    case updateApp
    case howling // 啸叫提醒
    case peopleMinutes // 面试速记
    case assignOtherToShare
    case hostRequestMicrophone
    case hostRequestCamera
    case requestRecord
    case conformRequestRecording // 请求主持人录制的二次确认窗口
    case conformRequestLiving    // 请求主持人直播的二次确认窗口
    case requestStopRecord
    case confirmBeforeRecord
    case requestLiving
    case votingRefuse
    case startLive
    case stopLive
    case netBusinessError
    case forceJoin
    case shareToParticipants
    case shareToGroup
    case leaveFollowAndOpenLink
    case recordMeetingAudio
    case requestLivingFromHost
    case spokenMismatching // 字幕口说语言不匹配
    case spokenNonsupport // 字幕口说语言不支持
    case recordingConfirm
    case selectSubtitleSpokenLanguage // 开启字幕选择口说语言
    case muteMicrophoneForAll   // 全员静音
    case micHandsUp // 举手申请发言
    case micHandsDown   // 申请发言手放下
    case cameraHandsUp // 举手申请开启摄像头
    case cameraHandsDown // 取消申请开启摄像头
    case liveCert
    case permissionOfDocs   // 文档权限
    case quiteLobbyByHeartBeatStop
    case onewayContact
    case interpreterConfirm
    case preEndCountDown // 确认提前结束倒计时
    case closeCountDown // 关闭倒计时
    case confirmBeforeAskHostForHelp
    case confirmBeforeRejoinBreakoutRoom
    case breakoutRoomWillEnd
    case breakoutRoomAutoFinish
    case reclaimHostWhenBreakoutRoom
    case openLinkInMagicShareConfirm // 共享人在MS中点非CCM链接，弹出外部打开的提示
    case recordUnmuteConfirm // 单人会中静音状态开启录制的提示
    case unmuteAlert
    case enterpriseCall
    case autoEnd // 单人自动结束会议
    case voiceprint //语音识别
    case rename // 会中改名
    case disconnectRoom // 断开会议室链接
    case callme
    case securityCompliance // 安全事件触发，结束会议
    case focusVideo // 焦点视频
    case downAllHands // 放下所有参会人举手
    case closeRecordingReminder // 关闭录制发起弹窗
    case webinarAttendeeBecomeParticipant // Webinar 主持人请求观众设置为嘉宾
    case webinarAttendeeAskedUnmute // Webinar 主持人请求观众打开麦克风
    case webinarHostConfirmEndRehearsalMeeting // Webinar 主持人确认是否在彩排模式下结束会议
    case padNoAudio
    case switchAudioMode
    case upgradePlan
    case shareContentChange // 抢共享提示
    case permissionOfMinutes // 妙记权限
}
