//
//  VideoChatNotice.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/12/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 推送通知
/// - PUSH_VIDEO_CHAT_NOTICE = 2215
/// - Videoconference_V1_VideoChatNotice
public struct VideoChatNotice: Equatable {

    /// 标识当前notice，由rust生成，客户端reply的时候需要带上
    public var noticeID: String

    public var meetingID: String

    public var messageID: String

    public var status: StatusCode

    public var type: TypeEnum

    public var message: String

    public var title: String

    public var popupType: PopupType

    public var msgI18NKey: I18nKeyInfo?

    public var titleI18NKey: I18nKeyInfo?

    public var btnI18NKey: I18nKeyInfo?

    /// 执行的cmd，传给客户端，未来可用于打点
    public var cmd: Int32

    /// action产生时间
    public var actionTime: MeetingActionTime

    /// 服务端会议结束时间，unix表示
    public var meetingEndTime: Int64

    ///alert time out 时间
    public var timeout: Int32

    /// toast展示时间
    public var toastDurationMs: Int32

    /// 服务端推送的sid，打点用
    public var pushSid: String

    /// 各业务自定义字段
    public var extra: [String: String]

    /// Tips相关的设置项
    public var tipsConfig: TipsConfig

    public enum StatusCode: Int, Hashable {
        case unknown // = 0
        case success // = 1
        case userBusyError // = 2

        ///后续按需要扩展
        case shareCardUserPermission // = 3
    }

    public enum TypeEnum: Int, Hashable {
        case unknown // = 0
        case toast // = 1

        /// 弹出确认框
        case popup // = 2

        /// PC端不支持视频会议的提醒
        case alert // = 3

        /// 开始会议前的设置弹窗
        case preview // = 4

        /// 会中展示的tips
        case tips // = 5

        /// 广播
        case broadcast // = 6

        ///后续按需要扩展，例如弹窗、Loading
        case handsUpToast // = 7

        /// 语音提示
        case voice // = 8
    }

    /// json序列化后放入extra中，key:zh_cn/en_us/ja_jp
    struct VoiceResource {
        public var resourceName: String
        public var downloadURL: String
        public var version: Int64
    }

    public enum PopupType: Int, Hashable {
        case unknown // = 0

        /// popup点击确定后直接进入会议
        case popupForceJoin // = 1

        /// popup点击确定后进入preview界面
        case popupPreview // = 2
        case popupNormal // = 3

        /// 录制合规确认弹窗
        case popupRecordingConfirm // = 4

        /// magic share 文档权限开启确认
        case popupDocPermConfirm // = 5

        /// follow提示用户外部权限被打开了
        case noticeExternalPermChanged // = 6

        /// 会议快结束后推送倒计时弹窗
        case popupMeetingEndConfirm // = 7

        /// 推送手动收回主持人的弹窗
        case popupManualCallbackHost // = 8

        /// 录制空间已满需升级套餐
        case popupRecordingUpgradePlan // = 9

        /// 转录合规确认弹窗
        case popupTranscribingConfirm // = 10

        /// 会中AI对话不依赖录制自动启动失败
        case popupAiChatAutoTurnOnFailed // = 11
    }

    public struct TipsConfig: Equatable {
        /// Tips自动撤销时间（毫秒）
        public var autoDismissTime: Int64
    }
}

extension VideoChatNotice: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_VideoChatNotice
    init(pb: Videoconference_V1_VideoChatNotice) {
        self.noticeID = pb.noticeID
        self.meetingID = pb.meetingID
        self.messageID = pb.messageID
        self.status = .init(rawValue: pb.status.rawValue) ?? .unknown
        self.type = .init(rawValue: pb.type.rawValue) ?? .unknown
        self.popupType = .init(rawValue: pb.popupType.rawValue) ?? .unknown
        self.title = pb.title
        self.message = pb.message
        self.titleI18NKey = pb.hasTitleI18NKey ? pb.titleI18NKey.vcType : nil
        self.msgI18NKey = pb.hasMsgI18NKey ? pb.msgI18NKey.vcType : nil
        self.btnI18NKey = pb.hasBtnI18NKey ? pb.btnI18NKey.vcType : nil
        self.cmd = pb.cmd
        self.pushSid = pb.pushSid
        self.actionTime = pb.actionTime.vcType
        self.meetingEndTime = pb.meetingEndTime
        self.timeout = pb.timeout
        self.toastDurationMs = pb.toastDurationMs
        self.extra = pb.extra
        self.tipsConfig = .init(
            autoDismissTime: pb.tipsConfig.autoDismissTime
        )
    }
}

extension VideoChatNotice.TipsConfig: CustomStringConvertible {
    public var description: String {
        String(
            indent: "TipsConfig",
            "autoDismissTime: \(autoDismissTime)"
        )
    }
}

extension VideoChatNotice: CustomStringConvertible {
    public var description: String {
        String(indent: "VideoChatNotice",
               "meetingId: \(meetingID)",
               "noticeId: \(noticeID)",
               "messageId: \(messageID)",
               "status: \(status)",
               "type: \(type)",
               "popupType: \(popupType)",
               "msgI18NKey: \(msgI18NKey)",
               "titleI18NKey: \(titleI18NKey)",
               "btnI18NKey: \(btnI18NKey)",
               "cmd: \(cmd)",
               "actionTime: \(actionTime)",
               "meetingEndTime: \(meetingEndTime)",
               "timeout: \(timeout)",
               "toastDurationMs: \(toastDurationMs)",
               "pushSid: \(pushSid)",
               "extra.keys: \(extra.keys)", // extra的value可能含有url，不可打印
               "tipsConfig: \(tipsConfig)"
        )
    }
}
