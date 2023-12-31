//
//  TrackWarning.swift
//  ByteViewTracker
//
//  Created by kiri on 2022/1/16.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

extension DevTrackEvent {

    /// 告警
    public enum Warning: String {
        /// MeetingSession泄漏
        case leak_meeting
        /// 一般对象泄漏
        case leak_object

        /// MS-runtime创建后未收到didReady回调
        case ms_miss_did_ready
        /// MS-共享人未收到有效的[FollowStates]数据
        case ms_presenter_no_valid_follow_states
        /// MS-跟随者未收到有效的[FollowStates]数据
        case ms_follower_no_valid_follow_states

        /// OnTheCall之后5秒内未收到FullParticipants
        case meeting_miss_fullparticipants

        /// 状态机线程async超过2秒
        case state_queue_timeout
        /// 状态机执行事件耗时超过2秒
        case state_execute_timeout

        /// 推送线程async超过2秒
        case push_queue_timeout

        /// VC 服务端按照 sessionKey 从 passport 服务端查到的用户 DID，与 passport 客户端保存的 DID 不一致导致无法入会
        case passport_inconsistent_did

        /// RTC 视频流订阅后，首祯超时
        case rtc_subscribe_timeout

        /// 收到无效 VoIP  推送，无法解析为 视频会议业务线
        case pushkit_invalid_push

        /// 收到其他用户的推送，常见原因是 Passport 卸载重装后登出失败，切换租户失败
        case pushkit_other_user_push

        /// 收到服务端日程会议开始的推送时，客户端因为某些前置检查失败而没有显示日程会议提醒弹框
        case calendar_prompt_not_show_on_push

        /// 加入/创建会议 precheck 阶段检验失败
        case join_meeting_precheck_failed

        /// 加入/创建会议调用服务端 join 接口失败，或接口成功但服务端返回业务错误
        case join_meeting_failed

        /// 应用后台被系统挂起或杀死
        case background_task_expire
    }
}
