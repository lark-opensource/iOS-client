//
//  VCMeetingEntry.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/6/29.
//

import Foundation

// 需要新增入口请联系上海视频会议团队
public enum VCMeetingEntry: String, CustomStringConvertible, Codable {
    /// 原CallClickSource，发起1v1入口
    case addressBookCard = "user_profile"  // 通讯录卡片
    case rightUpCornerButton = "right_up_corner_button"   // 右上角按钮
    case bottomAddButton = "plus"   // 下方加号按钮
    case messageBubble = "bubble" // 气泡消息对话框
    case meetingSpaceCallHistory = "meeting_space_call_profile"
    //    case meetingTab = "meeting_tab" // 独立 tab 详情页
    case openPlatform1v1 = "openplatform_1v1" // 开放平台1V1场景，如通过小程序拉起
    case enterpriseDirectCall = "enterprise_direct_call" // 企业办公电话直呼
    case enterpriseBack2Back = "enterprise_back2back" // 企业办公电话双呼
    case ipPhone = "ip_phone" // IpPhone 电话

    /// 发起普通会议入口
    case groupPlus = "group_plus"                       // 群下方加号
    case calendarDetails = "calendar_detail"            // 日历详情页
    case groupSideBar = "group_sidebar"                 // 会议侧边栏
    case meetingCard = "card"                           // 会议卡片
    case callingPage = "calling_page"                   // 响铃页面
    case joinRoom = "join_room"                         // 会议号加入
    case chatWindowBanner = "chat_window_banner"        // 聊天窗口会议按钮
    case meetingSpaceBanner = "meeting_space_banner"    // 会议空间入会按钮
    case tapTopJoinMeeting = "tab_top_join_room"        // 独立tab加入会议
    case tabTopMeetingNow = "tab_top_meet_now"          // 独立tab开启即时会议
    case upcomingJoinMeeting = "upcoming_join_room"     // 独立tab upcoming模块点击入会
    case calendarPrompt = "calendar_reminder"           // 日程会议入会提醒
    case createNewMeeting = "plus_new_meeting"          // 创建新会议
    case joinNeo = "join_neo"                           // 会议号加入单品会议，需要设置 Nickname
    case createNeo = "create_neo"                       // 创建单品会议
    case meetingBanner = "group_chat_banner"            // 会议横幅
    case landingPageLink = "landing_page_link"          // 网页落地页
    case msgLink = "msg_link"                           // IM消息
    case loginPage = "login_page"                       // 登录页
    case meetingTab = "meeting_tab"                     // 独立 tab 详情页
    case meetingLinkJoin = "meeting_link_join"          // 通过IM中会议ID引导入会
    case calendarMeetingNow = "calendar_meeting_now"    // 日历首页开启即时会议
    case calendarJoinMeeting = "calendar_join_meeting"  // 日历首页加入会议
    case widgetCreateMeeting = "widget_create_meeting"  // 小组件创建会议
    case widgetJoinMeeting = "widget_join_Meeting"      // 小组件加入会议
    case widgetOpenTab = "widget_open_tab"              // 小组件视频会议打开tab首页
    case openPlatform = "open_platform"                 // 通过openPlatform接口打开
    case interview = "interview"                        // 通过interview接口打开
    case imNotice = "im_notice"                         // 通过Feed页通知栏
    case eventCard = "event_card"                       // 通过事件卡片
    case myAI = "my_ai"                                 // 通过myAI
    case handoff = "handoff"                            // 通过Handoff继续会议

    public var description: String {
        return self.rawValue
    }
}
