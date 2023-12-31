//
//  TrackEventName.swift
//  ByteViewTracker
//
//  Created by kiri on 2022/1/13.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 埋点名称
/// - https://codebase.byted.org/repo/ee/homeric_datas/-/blob/data/Events/Lark/VC/VC.yaml/
/// - https://bytedance.feishu.cn/wiki/wikcnuD5EZYoX5NuZA4QRp0bEkf#
/// - https://bytedance.feishu.cn/docs/lWImGvXBMCGQFStgMGU71b
/// - https://ad-kibana.bytedance.net/lark_suite_vc_data/app/kibana#/discover
public enum TrackEventName: String, Hashable {
    /// 为了某些不要埋点或需要用nil的case写起来方便
    /// - note: 此name的event不会被埋点
    case none
    /// 用于不能解析的动态埋点
    case unknown

    /* 老埋点key 定义 */

    /// 1v1 calling页面
    case vc_call_page_calling
    /// 1v1 Ringing页面
    case vc_call_page_ringing
    /// 1v1 OnTheCall页面
    case vc_call_page_onthecall
    /// 1v1邀请页面点击确认
    case vc_call_page_invite
    /// 点击发起视频通话
    case vc_call_click
    /// 1v1客户端收到服务端反馈的video_chat_info 内的 meeting_id时埋点
    case vc_call_client_create
    /// 创建通话失败
    case vc_call_fail
    /// 1v1主被叫成功建立连线 （音频流接通）
    case vc_call_success
    /// 被叫通话结束时检查有无网络，无网络时才埋点
    case vc_call_finish
    /// 主叫主动取消（点击button）
    case vc_call_cancel
    /// （被叫）点击接通--（主叫）跳出通话页面时间的差值
    case vc_call_oncallloading
    /// 主叫点击“视频通话”按钮 -> 主叫显示“正在等待对方接听”
    case vc_call_dialingduration
    /// 主叫正在等待对方接听-> 主叫主动挂断
    case vc_call_cancelduration
    /// 被叫点击接通
    case vc_call_accept
    /// 主叫拨号到被叫响铃时间
    case vc_call_receiveduration
    /// 被叫通话结束时检查有无网络，无网络时才埋点
    case vc_call_finish_callee_nonetwork
    /// 多人 Ringing页面
    case vc_meeting_page_ringing
    /// 多人OnTheCall页面
    case vc_meeting_page_onthecall
    /// OnTheCall/会前邀请页面下，邀请用户
    case vc_meeting_page_invite
    /// 预览加入会议
    case vc_meeting_page_preview
    /// 多人会议iOS、安卓端操作参会人与受邀请人
    case vc_meeting_page_userlist
    /// 推荐列表点击用户calling
    case vc_meeting_page_suggest_list
    /// 搜索列表选择用户calling
    case vc_meeting_page_search_list
    /// 会中麦克风/摄像头旁的设置
    case vc_meeting_page_setting
    case vc_minutes_bot_click
    /// 显示字幕页面
    case vc_meeting_subtitle_page
    /// 字幕设置页面
    case vc_meeting_subtitle_setting_page
    case vc_meeting_subtitle_setting
    /// meeting会中共享屏幕选择框
    case vc_meeting_onthecall_share_window
    /// 参会人等候室界面的相关事件
    case vc_meeting_page_waiting_rooms
    /// 直播设置页面
    case vc_live_setting_page
    case vc_pre_setting_page
    case vc_pre_waitingroom
    /// 音视频实验室设置页
    case vc_labs_setting_page
    case vc_labs
    case vc_meeting_lark_detail
    /// lark主端点击视频会议tab
    case vc_lark_tab
    /// 点击群组视频通话
    case vc_meeting_click
    /// 多人会议创建会议失败，增加主持人被禁言不能创建会议的情况
    case vc_meeting_fail
    /// 群组视频通话会议卡片分享
    case vc_in_meeting_link_share
    /// 发起/加入多人会议
    case vc_meeting_attend
    /// 视频会议页面弹窗
    case vc_meeting_popup
    /// 多人会议加入失败埋点
    case vc_meeting_attend_fail
    /// 弹窗提示页面
    case vc_meeting_lark_hint
    /// 发起会议或加入会议的来源
    case vc_meeting_lark_entry
    /// 点击入口，在出现Preview之前提示加入会议失败
    case vc_meeting_lark_entry_fail
    /// 无摄像头、麦克风权限进行视频会议
    case vc_meeting_root_check
    /// 通话中断率
    case vc_meeting_finish
    /// 音频订阅的首帧回调成功
    case vc_meeting_success
    /// 客户端点击entry（会议入口）/attend 收到服务端反馈的video_chat_info 内的 meeting_id和interactive_id时埋点
    case vc_meeting_client_join
    /// 直播开始弹窗
    case vc_begin_live_popup
    /// 入会时隐私协议弹窗
    case vc_privacy_policy_popup
    /// 直播结束弹窗
    case vc_end_live_popup
    /// 字幕弹窗
    case vc_meeting_subtitle_popup
    /// 当前用户展示当前网络不稳定
    case vc_voip_connection
    /// 会中，参会人进入会议等候室，主持人收到的提醒弹窗界面相关事件
    case vc_waiting_rooms_popup
    case vc_meeting_video_setting
    /// 点击按钮进入LM列表页
    case vc_meeting_tab
    /// 投屏码页面展示
    case vc_meeting_sharecode_view
    /// 投屏码页面页面下发生点击事件
    case vc_meeting_sharecode_click
    /// lark扫码分享
    case vc_vr_qr_code_scan
    /// 客户端信令信息
    case vc_client_signal_info
    /// 音视频首帧回调耗时超过5秒
    /// - slardar
    case vc_monitor_oncall_to_stream
    /// SDK回调到视频流&音频流
    case vc_monitor_join_to_stream
    /// SDK调用、回调相关
    case vc_monitor_sdk

    /// 会中设备发送的实际视频流分辨率设置
    case vc_video_stream_send_setting_status

    /// 会中设备接收、选择的实际视频流分辨率设置
    case vc_video_stream_recv_setting_status


    /// 监控字幕的接收耗时
    case monitor_vc_client_subtitle_delay
    /// 主叫Call被叫
    case vc_monitor_caller_start
    /// 主叫收到会议房间ID
    case vc_monitor_caller_receive_meeting_id
    /// 主叫听到被叫首帧
    case vc_monitor_caller_meet_callee
    /// 主叫结束时间
    case vc_monitor_caller_hangup
    /// 被叫听到主叫首帧
    case vc_monitor_callee_meet_caller
    /// 被叫结束时间
    case vc_monitor_callee_hangup
    /// 被叫收到Ring
    case vc_monitor_callee_ring
    /// 被叫点击接受
    case vc_monitor_callee_accept
    /// 会议异常 （SDK异常、心跳异常、crash、创建会议失败、接听失败、other）
    /// - slardar
    case vcex_meeting_error
    /// 状态机异常
    /// - slardar
    case vcex_statemachine_switch_fail
    /// SDK异常
    /// - slardar
    case vcex_bytertc_sdk
    /// calling超时
    /// - slardar
    case vcex_calling_client_timeout
    /// ringing超时
    /// - slardar
    case vcex_ringing_client_timeout
    /// 被中断的VC或VoIP
    case vc_voip_interrupted
    /// 共享标注控制器点击
    case vc_annotate_control_bar
    /// 共享标注画笔使用
    case vc_annotate_usage_monitor
    /// 共享标注弹窗
    case vc_annotate_popup
    case common_pricing_popup_view
    case common_pricing_popup_click
    case vc_display_feelgood_feedback
    /// Google Drive 文件选择页面
    case vc_meeting_share_drive_window
    /// 发起 Magic Share 打点
    case vc_meeting_magic_share_init_track
    /// Magic Share 前端消耗数据
    case vc_meeting_magic_share_stat
    /// VC Magic Share 展示区域大小打点
    case vc_meeting_magic_share_display_size
    case authorize_collaboration_request
    /// 视频会议聊天框
    case vc_meeting_chat_box
    /// 字幕不准确弹窗
    case vc_inaccurate_subtitle_popup
    /// 字幕是否使用日语弹窗
    case vc_japanese_subtitle_popup
    case vc_meeting_breakoutrooms_popup
    case public_share_view
    case public_share_click
    /// 点击lark中的链接
    case link_clicked

    /* 标准新埋点定义 */

    // VIEW

    /// 分组会议弹窗显示
    case vc_meeting_breakoutrooms_popup_view
    /// 会中设置页
    case vc_meeting_setting_view
    /// 会中主页
    case vc_meeting_onthecall_view
    /// 直呼会中页
    case vc_office_phone_calling_view
    /// 呼叫页，1v1场景下;用户（主叫）发起呼叫后页面展示
    case vc_meeting_calling_view
    /// 被呼叫页，1v1场景下;用户（被叫）收到呼叫的响铃页面页面展示
    case vc_meeting_callee_view
    /// 日程入会提醒页面展示
    case vc_meeting_cal_view
    /// 会前预览页，多人会议场景下，用户创建/加入会议前的预览页面
    case vc_meeting_pre_view
    /// 会前等候室，多人会议场景下，
    case vc_meeting_waiting_view
    /// 会中主持人操作页
    case vc_meeting_hostpanel_view
    /// 会中共享窗口选择页
    case vc_meeting_sharewindow_view
    /// 会中Magic Share页面展示
    case vc_meeting_magic_share_view
    case vc_share_code_input_popup_view
    case vc_share_code_input_popup_click
    /// 会中字幕页面
    case vc_meeting_subtitle_view
    /// 会中字幕设置页
    case vc_meeting_subtitle_setting_view
    /// 会中电话邀请页
    case vc_meeting_phone_invite_view
    /// 会中弹窗页
    case vc_meeting_popup_view
    /// 会中同声传译页
    case vc_meeting_interpretation_view
    /// 倒计时设置页
    case vc_countdown_setup_view
    /// 倒计时视图
    case vc_countdown_view
    /// 会议详情卡片
    case vc_meeting_card_view
    /// 会中视图布局
    case vc_meeting_layout_view
    /// 会前设置页
    case vc_meeting_pre_setting_view
    /// 移动端会中控制栏页面
    case vc_meeting_control_bar_view
    /// 会中发送消息页
    case vc_meeting_chat_send_message_view
    /// 会中发送表情
    case vc_meeting_chat_reaction_view
    /// 失败toast
    case vc_meeting_onthecall_popup_view
    /// 会中点击弹窗
    case vc_meeting_onthecall_popup_click
    /// 视频会议独立tab页
    case vc_tab_view
    /// 视频会议独立tab-会议详情页,视频会议独立tab-会议详情页发生点击事件
    case vc_tab_list_view
    /// 合集页面的展示
    case vc_tab_cluster_view
    /// 会中直播设置页
    case vc_live_meeting_setting_view
    case vc_meeting_magic_share_popup_view
    case vc_meeting_loudspeaker_view
    case vc_meeting_loudspeaker_click
    /// 直播弹窗确认页
    case vc_live_confirm_view
    case vc_share_code_input_view
    case vc_meeting_room_system_invite_view
    case vc_user_list_setting_status
    case vc_meeting_onthecall_status
    case vc_entry_auth_choose_click
    case vc_entry_auth_choose_view

    /// VoIP到达率
    case voippush_client_rec
    /// VoIP到达率
    case voippush_client_notice_succeed
    /// 用户点击离线响铃通知启动APP
    case voip_apns_ringing_launch
    /// app启动设置
    case client_notification_settings
    /// 用户点击离线响铃通知启动APP
    case vc_apns_ringing_launch

    // CLICK

    case vc_meeting_breakoutrooms_startpop_click
    case vc_meeting_breakoutrooms_setting_click
    case vc_meeting_breakoutrooms_popup_click
    /// 【会中主页面】发生的动作事件
    case vc_meeting_onthecall_click
    /// 设置界面页面
    case vc_meeting_setting_click
    /// 呼叫页，1v1场景下;用户在（主叫）发起呼叫页面发生点击事件
    case vc_meeting_calling_click
    /// 被呼叫页，1v1场景下;用户（被叫）收到呼叫后弹出的响铃页面发生点击事件
    case vc_meeting_callee_click
    /// 日程入会提醒窗口发生点击事件
    case vc_meeting_cal_click
    /// 【会前预览页】发生的点击动作
    case vc_meeting_pre_click
    case vc_meeting_waiting_click
    /// 会中主持人设置页点击事件
    case vc_meeting_hostpanel_click
    /// 会中共享窗口选择页发生点击事件
    case vc_meeting_sharewindow_click
    /// 会中Magic Share页面发生的点击事件
    case vc_meeting_magic_share_click
    /// 会中字幕页面发生点击事件
    case vc_meeting_subtitle_click
    case vc_meeting_popup_click
    /// 千方会议时，开启发言时的实际情况（含sip端）
    case vc_speaking_open_server
    /// 会中同声传译页发生点击事件
    case vc_meeting_interpretation_click
    /// 倒计时设置页点击事件
    case vc_countdown_setup_click
    /// 倒计时悬浮视图点击事件
    case vc_countdown_click
    /// 会议详情卡片发生点击事件
    case vc_meeting_card_click
    /// 会中视图布局发生点击事件
    case vc_meeting_layout_click
    /// 【会前设置页】发生的动作事件
    case vc_meeting_pre_setting_click
    case vc_meeting_chat_send_message_click
    case vc_meeting_chat_reaction_click
    /// 视频会议独立tab页点击动作
    case vc_tab_click
    /// 视频会议独立tab-会议详情页发生点击事件
    case vc_tab_dial_click
    case vc_tab_list_click
    /// 合集页面发生的点击行为
    case vc_tab_cluster_click
    /// 【会议入口】发生的动作事件
    case vc_meeting_entry_click
    /// 会中直播设置页点击事件
    case vc_live_meeting_setting_click
    case vc_meeting_magic_share_popup_click
    /// 共享屏幕页面下发生点击事件
    case vc_meeting_sharescreen_click
    /// 白板页面发生的点击事件
    case vc_board_click
    /// 直播弹窗确认页点击事件
    case vc_live_confirm_click
    case vc_share_code_input_click
    case vc_meeting_room_system_invite_click
    case setting_meeting_click
    case setting_meeting_missed_call_view
    case setting_meeting_missed_call_click
    /// Tips 不再提示
    case vc_interview_meeting_dont_remind_again_popup_click
    /// 会议状态
    case vc_meeting_setting_status
    /// 电话邀请呼叫事件
    case vc_meeting_phone_invite_click
    /// 会中点击摄像头按钮
    case vc_meeting_camera_click

    /* 其他新埋点定义 */
    /// MS数据埋点
    case vc_magic_share_first_action_dev
    /// MS数据包过滤
    case vc_ms_pkg_valid_dev
    /// STATUS
    case vc_toast_status
    /// setting
    case vc_setting_status
    /// 核心日志上传
    /// - slardar
    case vc_monitor_core_log
    case vc_biz_error

    case vc_mobile_ground_status_dev
    case vc_mute_status_conflict_dev
    case vc_net_disconnection_dev
    case vc_network_quality_status
    case vc_remote_network_quality_status

    case vc_initialization_time

    /// 通用埋点
    case vc_client_event_dev

    /// 基础性能
    case vc_basic_performance
    /// 可感知错误
    case vc_appreciable_error
    /// 会中监控，5s 时间间隔
    case vc_inmeet_perf_monitor

    /// 会中剩余电量
    case vc_power_remain_one_minute_dev

    /// 会中温度
    case vc_ios_temperature_change_dev

    /// CPU 核心维度使用率
    case vc_perf_cpu_cores_state_dev

    /// 线程维度 CPU 使用率
    case vc_perf_cpu_state_mobile_dev

    /// 入会过程 AppCPU 使用率
    case vc_perf_cpu_onthecall_dev

    /// 会中网络类型改变
    case vc_network_change_dev

    /// 会中截屏上报诊断日志
    case vc_snapshot_report_dev

    /// 会中反馈
    case vc_conference_feedback_view
    /// 蓝牙耳机相关状态上报
    case vc_bluetooth_status

    /// 端上在收到一条新的字幕时（seg_id之前没出现过），端上需要打个点
    case vc_new_seg_subtitle_receive_dev

    /// 设备当前选中的cam/mic名称，在入会成功/设备发生切换时上报
    case vc_cam_mic_selected_dev

    /// 设备当前订阅视频流的分辨率，在subscribe成功/该路流分辨率发送变化时上报
    case vc_cur_sub_strm_resolution_dev

    /// 客户端处理BinaryMessage的打点记录
    case vc_binary_message_req_recv_dev

    /// 前端收到响铃页的推送，判断是不是新特性推送，作为新特性的分母
    case vc_meeting_callee_status

    /// 设备会中发生动态降级
    case vc_meeting_dynamic_degrade_status

    /// 设备会中发生动态降级的恢复
    case vc_meeting_dynamic_upgrade_status

    /// 白板开启/关闭
    case vc_whiteboard_status

    ///  拒接回复
    case vc_meeting_callee_msgnotes_view
    case vc_meeting_callee_msgnotes_click
    case vc_meeting_callee_mobile_refusenotes_view
    case vc_meeting_callee_mobile_refusenotes_click

    /// 白板首帧渲染时长
    case vc_whiteboard_first_frame_paint_dev

    /// 一次绘制的平均fps
    case vc_whiteboard_fps_dev

    /// 同步入会配置弹窗展现
    case vc_ultrasonic_popover_view
    /// 同步入会配置弹窗行为
    case vc_ultrasonic_popover_click
    /// 超声波同步入会状态
    case vc_ultrasonic_status

    /// vc客户端信令请求
    case vc_client_signal_dev

    /// 会中字幕页监控事件(开启到下一状态，下一状态到首行字幕)
    case vc_meeting_subtitle_dev

    case vc_office_phone_calling_click
    case vc_office_phone_calling_popup_click
    case vc_phone_calling_prompt_click
    case vc_phone_calling_prompt_status
    /// VC会中或calling时收到系统来电
    case vc_phone_call_interrupt

    /// 字幕弹窗确认页面
    case vc_subtitle_popup_click
    /// 完整字幕筛选器点击某个参会人触发筛选
    /// 完整字幕搜索框输入内容
    case vc_meeting_subtitle_status

    /// 会中视图周期性埋点
    case vc_meeting_onthecall_heartbeat_status

    /// 字幕效果端到端评测
    case vc_subtitle_exp_dev

    /// 面试满意度问卷弹窗
    case vc_interview_satisfaction_popup_view
    /// 面试满意度问卷按钮点击
    case vc_interview_satisfaction_popup_click
    /// 会中状态表情状态的开始和结束
    case vc_meeting_reaction_status
    /// 会中特效状态的开始和结束
    case vc_meeting_effect_status
    /// 通知铃声设置
    case setting_detail_click
    /// Feed会议入口点击加入会议
    case navigation_event_list_click

    /// 投浏览器转妙享展现事件
    case vc_share_screen_to_ms_view
    /// 投浏览器转妙享点击事件
    case vc_share_screen_to_ms_click
    /// 被共享人从跟随共享屏幕切换到自由浏览文档并定位成功的成功/失败信息和耗时信息
    case vc_screen_to_file_dev
    /// 点击消息气泡
    case vc_meeting_chat_pop_click
    /// 端到端监控会中控制埋点
    case vc_meeting_control_result_dev


    case vc_webinar_role_change_rejoin_view
    case vc_webinar_role_change_rejoin_click
    case vc_meeting_vote_click
    case vc_secretchat_video_call_confirm_popup_view
    case vc_secretchat_video_call_confirm_popup_click

    case vc_interview_information_page_server

    /// 会中im聊天是否打开
    case vc_meeting_im_status

    /// 投屏转妙享展示Onboarding
    case vc_sharescreen_to_magicshare_onboarding_view
    /// 投屏转妙享点击Onboarding
    case vc_sharescreen_to_magicshare_onboarding_click
    /// 计费心跳埋点
    case vc_billing_heartbeat_status
    /// 计费全局视频流埋点
    case vc_billing_global_video_recv_status
    ///计费订阅和取消订阅埋点
    case vc_billing_video_recv_resolution_status
    /// 鼠标单独传输状态
    case vc_meeting_sharescreen_mouse_transfer_status
    /// 会前预览页弹窗展示事件
    case vc_meeting_pre_popup_view
    /// 会前预览页弹窗点击事件
    case vc_meeting_pre_popup_click
    /// im消息发送成功埋点
    case vc_meeting_chat_success_status
    /// 状态面板内各功能项点击事件
    case vc_mobile_status_bar_click
    /// VC 会中聚合埋点
    case vc_ios_meeting_aggregate_event
    /// 建会、入会到preview页面出现
    case vc_sla_client_preview_status
    /// 点击开始、接听到成功入会
    case vc_sla_client_join_status
    ///  RTC连接
    case vc_sla_rtc_join_status
    /// 点击键盘快捷键
    case vc_meeting_shortcut_click
    ///  E2EE加解密失败
    case vc_j2m_content_decrypt_status
    ///  E2EE秘钥错误
    case vc_j2m_meeting_key_status
    ///
    case vc_discussion_cluster_click
    /// 妙记申请弹窗
    case vc_minutes_popup_click
    /// 妙记申请弹窗
    case vc_minutes_popup_view
    /// 展示会议纪要页面
    case vc_meeting_notes_view
    /// 点击会议纪要页面
    case vc_meeting_notes_click
    /// 转录页面点击
    case vc_meeting_transcribe_click

    /// 上报avatar内存占用数据
    case vc_meeting_avatar_memory_size_dev

    /// feed中事件应用列表的动作事件
    case feed_event_list_click

    /// 办公电话技术埋点
    case vc_business_phone_call_status

    /// 加入会议互通拦截页面弹出
    case vc_tns_actively_join_cross_border_view
    /// 加入会议互通拦截弹框主按钮点击
    case vc_tns_actively_join_cross_border_click
    /// 邀请入会互通拦截页面弹出
    case vc_tns_intive_cross_border_view
    /// 文档加载时上报，用于性能数据统计
    case vc_magic_share_ccm_load_dev
    /// 妙享降级数据改变的时候，上报一个埋点
    case vc_magic_share_degrade_dev
}

extension TrackEventName: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}
