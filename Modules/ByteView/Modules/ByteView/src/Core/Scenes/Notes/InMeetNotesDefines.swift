//
//  InMeetNotesDefines.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/6/26.
//

import Foundation
import ByteViewUI

// 与前端的交互参考 https://bytedance.feishu.cn/docx/WjTddzO5QoYNZSxGxYCcQhoXnLh

struct InMeetNotesKeyDefines {

    /// 调用web时使用的命令
    enum Command {
        /// 更新会议信息
        static let updateMeetingInfo: String = "PUSH_AGENDA_MEETING_INFO"
        /// 更新激活的议程信息
        static let updateAgendaInfo: String = "PUSH_AGENDA_CHANGE_INFO"
        /// 显示外部参会人提示
        static let showPermissionTips: String = "lark.biz.util.showMessage"
        /// 透传调用web方法
        static let callPassThroughFunc: String = "INVOKE_CCM_NATIVE"
    }

    /// web回调时传递的事件
    enum Event {
        /// notes加载完毕
        static let agendaReady: String = "agendaReady"
        /// web经由native透传埋点
        static let track: String = "track"
        /// 用户点击关闭了“外部参会人”提示
        static let closePermissionTips: String = "closePermissionTips"
        /// 前端通知客户端开始录制，在录制开启成功后会收到
        static let startRecording: String = "startRecording"
        /// 前端通知客户端上报最新的会议信息
        static let notesReady: String = "notesReady"
        /// 获取AI相关配置信息
        static let getAIInfo: String = "GET_AI_INFO"
        /// 用户点击了快捷共享按钮
        static let startMagicShare: String = "startMagicShare"
    }

    /// 点击导航栏的按钮事件
    enum NavigationBarItem {
        /// 关闭
        static let close: String = "close"
        /// 更多（···按钮）
        static let more: String = "MORE_OPERATE" // 这里遵循CCM前端定义，既有大写又有小写-_-!
        /// 通知（铃铛按钮）
        static let notification: String = "MESSAGE"
        /// 分享（转发按钮）
        static let share: String = "SHARE"
    }

    /// 参数定义
    enum Params {
        static let command: String = "command"
        static let payload: String = "payload"
        static let eventName: String = "eventName"
        static let params: String = "params"
        static let method: String = "method"
        static let callbackCommand: String = "callbackCommand"
        static let content: String = "content"
        static let promptId: String = "promptId"
        static let bizExtraData: String = "bizExtraData"
        static let eventDuration: String = "event_duration" // 即时会议不传，日程会议传入日程时长，时长（单位：分钟）
        static let attendeeNum: String = "attendee_num"
        static let meetingId: String = "meeting_id"
        static let source: String = "source"
        static let meeting: String = "meeting"
    }

    enum MeetType {
        /// 1v1
        static let vcCallMeeting: String = "vc_call_meeting"
        /// 群聊会议
        static let vcNormalMeeting: String = "vc_normal_meeting"
        /// 日程会议
        static let vcCalendarMeeting: String = "vc_calendar_meeting"
    }

    static func generateNotesSceneInfo(with meetingId: String) -> SceneInfo {
        var sceneInfo = SceneInfo(key: SceneKey.vcSideBar, id: "vc_notes_\(meetingId)")
        sceneInfo.title = I18n.View_G_Notes_FeatureTitle
        return sceneInfo
    }
}
