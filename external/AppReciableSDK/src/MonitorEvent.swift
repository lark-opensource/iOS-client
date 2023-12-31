//
//  MonitorEvent.swift
//  AppReciableSDK
//
//  Created by qihongye on 2020/7/31.
//

import Foundation

// swiftlint:disable identifier_name
public enum Biz: Int, CustomDebugStringConvertible {
    case Unknown = 0
    case Messenger
    case Search
    case Calendar
    case Docs
    case Driver
    case Mail
    case OpenPlatform
    case UserGrowth
    case VideoConference // vc视频会议
    case Moments
    case Core
    case Todo

    public var debugDescription: String {
        switch self {
        case .Unknown:
            return "Unknown"
        case .Messenger:
            return "Messenger"
        case .Calendar:
            return "Calendar"
        case .Search:
            return "Search"
        case .Docs:
            return "Docs"
        case .Driver:
            return "Driver"
        case .Mail:
            return "Mail"
        case .OpenPlatform:
            return "OpenPlatform"
        case .UserGrowth:
            return "UserGrowth"
        case .VideoConference:
            return  "VideoConference"
        case .Moments:
            return  "Moments"
        case .Core:
            return "Core"
        case .Todo:
            return "Todo"
        }
    }
}

public enum Scene: Int, CustomDebugStringConvertible {
    case Unknown = 0
    case Feed
    case Chat
    case Group
    case Profile
    case Schedule
    case Detail
    case Favorite
    case Pin
    case MeetingView
    case Setting
    case Search
    case CalDiagram
    case CalEventEdit
    case CalEventDetail
    case CalBot
    case Playground
    case Contact
    case Picker
    case Thread
    case Scaner
    case OnBoarding
    case UGCenter
    case Invite
    case Share
    case UGNoticeCenter
    case Feelgood
    case DyResource
    case VCPreview // vc视频会议之入会preview场景
    case VCOnTheCall // vc视频会议之会中场景
    case VCCalling // vc视频会议之入会前呼叫场景
    case MoHome // 新增feed流
    case MoPost // 新增帖子
    case MoProfile // profile
    case MoNotification // 通知
    case MinutesList // 妙记列表
    case MinutesDetail // 详情
    case MinutesRecorder // 录音
    case MinutesPodcast // 播客
    case ImageViewer // 图片查看器
    case MailFMP    //首页
    case MailRead   //读信模块
    case MailSearch //搜索模块
    case MailDraft  //草稿，写信模块
    case TodoCenter          // 任务中心
    case TodoDetail          // 查看任务详情
    case TodoCreate          // 新建任务
    case TodoComment         // 任务评论
    case TodoListInChat      // 会话内任务列表
    case DarkMode
    case Forward
    case Moments // 公司圈场景
    case GroupAvatar // 群头像
    case ProfileAvatar // Profile 头像
    case LarkLive // 直播
    case LarkLiveFloat // 直播小窗
    case SecretChat // 密聊
    case MoFeed // 公司圈新版feed流，包括首页、Hashtag、Category和Profile的feed流
    case MailContentSearch //邮件内搜索
    case MailNetwork // 59邮件网络相关
    case MailAccount // 邮箱账号模块
    case MailStability = 10099 // 邮箱业务工程稳定性相关
    case MailBlankCheck = 10100 // 邮箱业务白屏检测相关

    public var debugDescription: String {
        switch self {
        case .Unknown:
            return "Unknown"
        case .Feed:
            return "Feed"
        case .Chat:
            return "Chat"
        case .Group:
            return "Group"
        case .Profile:
            return "Profile"
        case .Schedule:
            return "Schedule"
        case .Detail:
            return "Detail"
        case .Favorite:
            return "Favorite"
        case .Pin:
            return "Pin"
        case .MeetingView:
            return "MeettingView"
        case .Setting:
            return "Setting"
        case .Search:
            return "Search"
        case .CalDiagram:
            return "CalDiagram"
        case .CalEventEdit:
            return "CalEventEdit"
        case .CalEventDetail:
            return "CalEventDetail"
        case .CalBot:
            return "CalBot"
        case .Playground:
            return "Playground"
        case .Contact:
            return "Contact"
        case .Picker:
            return "Picker"
        case .Thread:
            return "Thread"
        case .Scaner:
            return "Scaner"
        case .OnBoarding:
            return "OnBoarding"
        case .UGCenter:
            return "UGCenter"
        case .Invite:
            return "Invite"
        case .Share:
            return "Share"
        case .UGNoticeCenter:
            return "UGNoticeCenter"
        case .Feelgood:
            return "Feelgood"
        case .DyResource:
            return "DyResource"
        case .VCPreview:
            return "VCPreview"
        case .VCOnTheCall:
            return "VCOnTheCall"
        case .VCCalling:
            return "VCCalling"
        case .MoHome:
            return "MoHome"
        case .MoPost:
            return "MoPost"
        case .MoProfile:
            return "MoProfile"
        case .MoNotification:
            return "MoNotification"
        case .MinutesList:
            return "MinutesList"
        case .MinutesDetail:
            return "MinutesDetail"
        case .MinutesRecorder:
            return "MinutesRecorder"
        case .MinutesPodcast:
            return "MinutesPodcast"
        case .ImageViewer:
            return "ImageViewer"
        case .MailFMP:
            return "MailFMP"
        case .MailRead:
            return "MailRead"
        case .MailSearch:
            return "MailSearch"
        case .MailDraft:
            return "MailDraft"
        case .MailAccount:
            return "MailAccount"
        case .TodoCenter:
            return "TodoCenter"
        case .TodoDetail:
            return "TodoDetail"
        case .TodoCreate:
            return "TodoCreate"
        case .TodoComment:
            return "TodoComment"
        case .TodoListInChat:
            return "TodoListInChat"
        case .DarkMode:
            return "DarkMode"
        case .Forward:
            return "Forward"
        case .Moments:
            return "Moments"
        case .GroupAvatar:
            return "GroupAvatar"
        case .ProfileAvatar:
            return "ProfileAvatar"
        case .LarkLive:
            return "LarkLive"
        case .LarkLiveFloat:
            return "LarkLiveFloat"
        case .SecretChat:
            return "SecretChat"
        case .MoFeed:
            return "MoFeed"
        case .MailContentSearch:
            return "MailContentSearch"
        case .MailNetwork:
            return "MailNetwork"
        case .MailStability:
            return "MailStability"
        case .MailBlankCheck:
            return "MailBlankCheck"
        }
    }
}

public protocol ReciableEventable {
    var eventKey: String { get }
}

public enum Event: String, ReciableEventable {
    /// Messenger
    case switchTab = "switch_tab_cost"
    case messageOnScreen = "message_on_screen"
    case messageSend = "message_send"
    case receiveMessage = "receive_message"
    case feedFirstPaint = "feed_first_paint"
    case firstFeedMeaningfulPaint = "first_feed_meaningful_paint"
    case feedLoadMore = "feed_load_more"
    case firstLoginFeedLoad = "first_login_feed_load"
    case enterChat = "enter_chat"
    case loadMoreMessageTime = "load_more_message_time"
    case enterProfile = "enter_profile"
    case searchTime = "search_time"
    case searchTimeFirst = "search_time_first"
    case imageLoad = "image_load"
    case atUserList = "at_user_list"
    case enterStickerSet = "enter_sticker_set"
    case enterChatSetting = "enter_chat_setting"
    case enterPin = "enter_pin"
    case translateMessage = "translate_message"
    case shareOperation = "share_operation"
    case enterPicker = "enter_picker"
    case addContacts = "add_contacts"
    case enterFavorite = "enter_favorite"
    case scanerReady = "scaner_ready"
    case showInviteMember = "show_invite_member"
    case inviteMemberAction = "invite_member_action"
    case showExternalContacts = "show_external_contacts"
    case showMyGroup = "show_my_group"
    case showBotContacts = "show_bot_contacts"
    case showOncallContacts = "show_oncall_contacts"
    case showAddressBook = "show_address_book"
    case switchFeedType = "switch_feed_type"
    case feedBoxAction = "feed_box_action"
    case shortCutAction = "shortcut_action"
    case showChatMembers = "show_chat_memebers"
    case chatMembersAction = "chat_memebers_action"
    case openImageViewer = "open_imageviewer"
    // 相册
    case galleryLoad = "gallery_load"
    // 图片上传
    case imageUpload = "image_upload"
    // 转发消息
    case forwardMessage = "forward_message"
    // 合并转发
    case mergeForwardMessage = "merge_forward_message"
    // 逐条转发
    case batchTransmitMessage = "batch_transmit_message"
    // Reaction上屏
    case showReaction = "show_reaction"
    /// Calendar
    case switchDiagram = "cal_switch_diagram"
    case addFullEvent = "cal_add_full_event"
    case editEvent = "cal_edit_event"
    case checkEvent = "cal_check_event"
    case replyRsvp = "cal_reply_rsvp"
    case shareEvent = "cal_share_event"
    case deleteEvent = "cal_delete_event"
    case enterVideo = "cal_enter_video"
    case enterMeeting = "cal_enter_meeting"
    case enterMinutes = "cal_enter_minutes"
    case checkAttendee = "cal_check_attendee"
    case saveEvent = "cal_save_event"

    case calendarDiagram = "cal_diagram"
    case calendarBotCard = "cal_bot_card"
    case calendarEventDetail = "cal_event_detail"
    case calendarEventCreate = "cal_event_create"

    /// UG OnBoarding
    case getSourceEvent = "ug_get_source_event" // 获取投放来源 , 仅移动端在使用
    case dynamicFlowEvent = "ug_dynamic_flow_event" // 调用GET_DYNAMIC_FLOW接口，用于统计接口cost， 接口错误
    case dynamicReportFlow = "ug_dynamic_report_flow" // 调用REPORT_FLOW_EVENT接口 ，用于统计接口cost， 接口错误
    case dynamicFlowUnmatchedData = "ug_dynamic_flow_unmatched_data" // 接口返回的数据 不符合预期
    case dynamicFlowAbnormalExit = "ug_dynamic_flow_abnormal_exit" // 动态流程异常退出
    /// UG banner
    case ugBannerFetch = "ug_banner_fetch" // 调用GET_BANNERS接口，用于统计接口cost， 接口错误
    case ugBannerSetStatus = "ug_banner_set_status" // 调用SET_BANNER_STATUS接口，用于统计接口cost， 接口错误
    case ugBannerBizError = "ug_banner_biz_error" // banner 业务自定义异常错误
    /// UG Guide
    case ug_get_user_guide = "ug_get_user_guide" // 调用GET_USER_GUIDE_REQUEST接口，用于统计接口cost， 接口错误
    case ugPostUserConsumingGuide = "ug_post_user_consuming_guide" // 调用GET_USER_GUIDE_REQUEST接口，用于统计接口cost， 接口错误
    case ugGuideBizError = "ug_guide_biz_error" // 调用GET_USER_GUIDE_REQUEST接口，用于统计接口cost， 接口错误
    case ugGuideTryLock = "ug_guide_try_lock" // 调用GET_USER_GUIDE_REQUEST接口，用于统计接口cost， 接口错误
    /// UG Dynamic Resource
    case ugFetchDyResource = "ug_fetch_dy_resource"  // 获取动态资源数据接口
    case ugDyResourceGenerateImg = "ug_dy_resource_generate_img"  // 动态生成图片
    /// UGCenter
    case ugCenterInitFetch = "ugcenter_init_fetch" // 调用ugcenter初始化接口，用于统计接口cost， 接口错误
    case ugCenterResFetch = "ugcenter_resource_fetch" // 调用ugcenter拉取资源数据，用于统计接口cost， 接口错误
    case ugCenterReportEvent = "ugcenter_report_event" // 调用ugcenter 上报接口，用于统计接口cost， 接口错误
    case ugCenterBizError = "ugcenter_biz_error"  // ug_center 业务自定义异常错误
    /// UG FeelGood
    case ugMagicTrigger = "ug_magic_trigger_event" // 上报feelgood接口
    case ugMagicWillOpen = "ug_magic_will_open" // 准备打开问卷
    case ugMagicDidOpen = "ug_magic_did_open" // 打开了问卷
    case ugMagicOpenTotalCost = "ug_magic_open_total_cost" // 上报接口，到打开问卷的全链路耗时
    case ugMagicIntercept = "ug_magic_intercept" // 拦截问卷展示
    /// 联系人-通讯录 （mobile）
    case contactOptLocalFetch = "contact_opt_local_fetch"                // 读取本地通讯录
    case contactOptFetchRecUser = "contact_opt_onboarding_fetch_rec_user" // 获取推荐用户
    case contactOptFetchContactList = "contact_opt_contact_list_fetch"    //拉取通讯录列表
    /// 联系人-新的联系人
    case contactOptFetchApplications = "contact_opt_contact_applications_fetch" // 调用拉取新的好友请求列表接口，用于统计接口cost， 接口错误
    case contactOptApproveApplication = "contact_opt_approve_friend_fetch" // 调用同意好友申请接口，用于统计接口cost， 接口错误
    /// 联系人-外部联系人
    case contactOptExternalFetch = "contact_opt_external_fetch" // 调用拉取外部联系人列表接口，用于统计接口cost， 接口错误
    case contactOptExternalDel = "contact_opt_external_delete" // 调用删除拉取外部联系人接口，用于统计接口cost， 接口错误
    /// invite
    case memberOrientationInvite = "member_orientation_invite" // 成员定向邀请
    case memberOrientationGetInviteInfo = "member_nondirection_get_invite_info" //成员非定向邀请获取邀请信息
    case memberOrientationLoadQrcode = "member_nondirection_load_qrcode" // 成员非定向邀请加载二维码
    case memberOrientationSaveOrShareQr = "member_nondirection_get_save_or_share_qr" //成员非定向邀请获取保存/分享的二维码图片
    case memberOrientationSaveQrPermisson = "member_nondirection_save_qr_permisson" // 成员非定向邀请申请保存二维码权限
    case memberOrientationCopy = "member_nondirection_copy" // 成员非定向邀请拷贝
    case memberOrientationShare = "member_nondirection_share" // 成员非定向邀请分享

    /// 添加外部联系人
    case externalOrientationGetInviteInfo = "external_nondirection_get_invite_info" // 外部非定向邀请获取邀请信息
    case externalOrientationLoadQrcode = "external_nondirection_load_qrcode" // 外部非定向邀请加载二维码
    case externalOrientationSaveOrShareQr = "external_nondirection_get_save_or_share_qr" // 外部非定向邀请获取保存/分享的二维码图片
    case externalOrientationSaveQrPermisson = "external_nondirection_save_qr_permisson" // 外部非定向邀请申请保存二维码权限
    case externalOrientationCopy = "external_nondirection_copy" // 外部非定向邀请拷贝
    case externalOrientationShare = "external_nondirection_share"// 外部非定向邀请分享
    case externalOrientationSearch = "external_orientation_search" // 外部定向搜索联系人
    case externalOrientationInvite = "external_orientation_invite" //外部定向邀请

    /// 家校版本的添加成员
    case parentOrientationGetInactiveInfo = "parent_nondirection_get_inactive_info" // 家校非定向邀请获取未激活信息
    case parentOrientationInviteInfo = "parent_nondirection_get_invite_info" // 家校非定向邀请获取邀请信息
    case parentOrientationLoadQrcode = "parent_nondirection_load_qrcode" //家校非定向邀请加载二维码
    case parentOrientationSaveOrShareQr = "parent_nondirection_get_save_or_share_qr" // 家校非定向邀请获取保存/分享的二维码图片
    case parentOrientationSaveQrPermisson = "parent_nondirection_save_qr_permisson" // 家校非定向邀请申请保存二维码权限
    case parentOrientationCopy = "parent_nondirection_copy" // 家校非定向邀请拷贝
    case parentOrientationShare = "parent_nondirection_share" // 家校非定向邀请分享
    case ugShareComponent = "ug_share_component" // 第三方分享面板展示

    // VideoConference
    case vc_enter_preview_total = "vc_enter_preview_total" // 打开视频会议预览页面，包括网络请求
    case vc_enter_preview_pure = "vc_enter_preview_pure" // 打开视频会议预览页面，统计不包括网络耗时
    case vc_enter_onthecall_total = "vc_enter_onthecall_total" // 加入视频会议,进入会中耗时,包括网络请求
    case vc_enter_onthecall_pure = "vc_enter_onthecall_pure" // 加入视频会议,进入会中，统计不包括网络耗时
    case vc_enter_calling = "vc_enter_calling" // 用户点击呼叫按钮到呼叫页面在屏幕上可见之间的耗时
    case vc_rtc_connect_time = "vc_rtc_connect_time" // 端上调用joinChannel至收到远端首祯音频帧或视频帧的耗时
    case vc_open_camera_time = "vc_open_camera_time" // 用户点击打开摄像头到本地视频流首帧回调之间的耗时
    case vc_enter_chat_window = "vc_enter_chat_window" // 点击聊天 到 IM 消息上屏

    // minutes
    case minutes_enter_list_time = "minutes_enter_list_time" // 打开妙记列表页面，包括网络请求
    case minutes_enter_detail_time = "minutes_enter_detail_time" // 打开妙记详情页面，统计包括网络耗时
    case minutes_enter_recorder_time = "minutes_enter_recorder_time" // 打开妙记录音页面，统计包括网络耗时
    case minutes_enter_podcast_time = "minutes_enter_podcast_time" // 打开妙记播客页面，统计包括网络耗时
    case minutes_audio_finish_upload_time = "minutes_audio_finish_upload_time" // 用户点击停止录音按钮到录音上传完成 之间的耗时
    case minutes_audio_text_displayed = "minutes_audio_text_displayed" // 用户发出语音 到 转化文字显示到屏幕上耗时
    case minutes_load_list_error = "minutes_load_list_error" //Minutes列表页加载数据失败
    case minutes_load_detail_error = "minutes_load_detail_error" //Minutes详情页加载数据失败
    case minutes_edit_detail_error = "minutes_edit_detail_error" // minutes 编辑详情页失败
    case minutes_media_play_error = "minutes_media_play_error" //媒体播放失败
    case minutes_create_audio_record_error = "minutes_create_audio_record_error" //录音启动失败
    case minutes_upload_audio_data_error = "minutes_upload_audio_data_error" //录音上传失败
    case minutes_load_podcast_error = "minutes_load_podcast_error" //播客详情页数据加载失败
    case minutes_enter_edit_mode_time = "minutes_enter_edit_mode_time" // 妙记，用户点击编辑说话人菜单 到 推荐说话人列表展示之前的耗时

    case larklive_home_display = "larklive_home_display"  // 点击一个新的直播链接到页面出现的时间
    case larklive_url_load_time = "larklive_url_load_time"  // 直播页面加载耗时
    case larklive_home_ready = "larklive_home_ready"  // 点击一个新的直播链接到页面加载完成的时间
    case larklive_home_fail = "larklive_home_fail" // 点击一个新的直播链接到页面加载失败的时间
    case larklive_appreciable_first_frame = "larklive_appreciable_first_frame"  // 点击一个新的直播链接到视频首帧出现的时间
    case larklive_network = "larklive_network" //用户点击到网络请求耗时
    case larklive_pullstream = "larklive_pullstream" //网络请求到拉流耗时
    case larklive_liveinfo = "larklive_liveinfo" //live_info 请求耗时
    case larklive_streamconfig = "larklive_streamconfig" //streamconfig请求耗时
    case larklive_streaminfo = "larklive_streaminfo" //stream_info 请求耗时
    case larklive_player_play = "larklive_player_play" //播放器拉流耗时（拉流首帧时长）
    case larklive_playback_url_load_time = "larklive_playback_url_load_time" // 回播页面加载耗时
    case larklive_playback_home_ready = "larklive_playback_home_ready" // 点击一个新的回播链接到页面加载完成的时间
    case larklive_playback_home_failed = "larklive_playback_home_failed" // 点击一个新的回播链接到页面加载失败的时间
    case larklive_playback_appreciable_first_frame = "larklive_playback_appreciable_first_frame"  // 点击一个新的回播链接到视频首帧出现的时间
    case larklive_playback_network = "larklive_playback_network" //用户点击到网络请求耗时
    case larklive_playback_pullstream = "larklive_playback_pullstream" //网络请求到拉流耗时
    case larklive_playback_liveinfo = "larklive_playback_liveinfo" //live_info 请求耗时
    case larklive_playback_playbackinfo = "larklive_playback_playbackinfo" //playback_info 请求耗时
    case larklive_playback_player_play = "larklive_playback_player_play" //播放器拉流耗时（拉流首帧时长）

    /// moments(公司圈) 埋点
    case showFeed = "show_feeds"
    case refreshFeed = "refresh_feeds"
    case loadMoreFeed = "load_more_feeds"
    case showDetail = "show_detail"
    case showProfile = "show_profile"
    case showNotification = "show_notification"
    case momentsShowHomePage = "moments_show_home_page"
    case momentsUploadVideo = "moments_upload_video"
    case momentsShowHashtagPage = "moments_show_hashtag_page"
    case momentsShowCategoryPage = "moments_show_category_page"
    case momentsSendPost = "moments_send_post"
    case momentsSendComment = "moments_send_comment"
    case momentsShowPublishPage = "moments_show_publish_page"
    case momentsShowProfile = "moments_show_profile"

    /// Mail埋点
    case mailFmpLoad = "mail_fmp_load"
    case mailLabelListLoad = "mail_label_list_load"
    case mailThreadListLoad = "mail_thread_list_load"
    case mailThreadMarkAllRead = "mail_thread_mark_all_read"
    case mailThreadChooseAll = "mail_thread_choose_all"
    case mailMessageListLoad = "mail_message_list_load"
    case mailMessageImageLoad = "mail_message_image_load"
    case mailMessageAttachmentLoad = "mail_message_attachment_download"
    case mailSearchListLoad = "mail_search_result_load"
    case mailSearchListLoadMore = "mail_search_result_next_page_load"
    case mailDraftCreate = "mail_draft_create_draft"
    case mailDraftSave = "mail_draft_save_draft"
    case mailDraftSendDraft = "mail_draft_send_draft"
    case mailDraftContactSearch = "mail_draft_contact_search"
    case mailDraftUploadImage = "mail_draft_add_image"
    case mailDraftUploadAttachment = "mail_draft_add_attachment"
    case mailDraftUploadLargeAttachment = "mail_draft_add_large_attachment"
    case mailThreadAction = "mail_thread_action"
    case mailLabelManageAction = "mail_label_manage_action"
    case mailReceivedMessage = "mail_received_message"
    case mailNetworkRecord = "mail_network_record"
    case mailLabelUnreadCount = "mail_label_unread_count"
    case mailStabilityAssert = "mail_stability_assert"
    case mailBlankCheck = "mail_blank_check"

    /// Todo
    case todoCenterColdLaunch = "todo_center_cold_launch"
    case todoCenterSwitchFilter = "todo_center_switch_filter"
    case todoCenterLoadMore = "todo_center_load_more"
    case todoDetailLoad = "todo_detail_load"
    case todoDetailLoadSource = "todo_detail_load_source"
    case todoDetailEditRecordLoad = "todo_detail_edit_record_load"
    case todoDetailEditRecordLoadMore = "todo_detail_edit_record_load_more"
    case todoCreate = "todo_create"
    case todoCommentLoadFirstPage = "todo_comment_load_first_page"
    case todoCommentSend = "todo_comment_send"
    case todoCommentDelete = "todo_comment_delete"
    case todoCommentReactionAdd = "todo_comment_reaction_add"
    case todoCommentReactionDelete = "todo_comment_reaction_delete"
    case todoInChatLoadFirstPage = "todo_inchat_load_first_page"
    case todoInChatLoadMore = "todo_inchat_load_more"
    case taskListColdLaunch = "task_list_cold_launch"

    // Audio
    case audioPlay = "audio_play"
    case audioRecord = "audio_record"
    case audioRecognition = "audio_recognition"

    // Video
    case videoPlay = "video_play"

    // File
    case fileDownload = "file_download"

    public var eventKey: String {
        return self.rawValue
    }
}

public enum ErrorType: Int, CustomDebugStringConvertible {
    case Other = -1
    case Unknown
    case Network
    case SDK

    public var debugDescription: String {
        switch self {
        case .Unknown, .Other:
            return "Unknown"
        case .Network:
            return "Network"
        case .SDK:
            return "SDK"
        }
    }
}

public enum ErrorLevel: Int, CustomDebugStringConvertible {
    case Fatal = 1
    case Exception

    public var debugDescription: String {
        switch self {
        case .Fatal:
            return "Fetal"
        case .Exception:
            return "Exception"
        }
    }
}
// swiftlint:enable identifier_name
