//
//  FeedTeaTrack.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/7/16.
//

import UIKit
import Foundation
import Homeric
import LKCommonsTracker
import RustPB
import LarkSDKInterface
import LarkPerf
import LarkModel
import LKCommonsLogging

/// Feed TEA 打点
final public class FeedTeaTrack {
    // 使用快捷键切换右侧消息分组
    static func trackNextFilterTab() {
        Tracker.post(TeaEvent(Homeric.PUBLIC_KEYBOARD_SHORTCUT_CLICK, params: ["feature": "next_feed_tab"]))
    }

    // 使用快捷键切换左侧消息分组
    static func trackerLastFilterTab() {
        Tracker.post(TeaEvent(Homeric.PUBLIC_KEYBOARD_SHORTCUT_CLICK, params: ["feature": "last_feed_tab"]))
    }

    /// 操作Feed已完成
    static func trackDoneFeed(_ preview: FeedPreview, _ isClick: Bool, _ isContextMenu: Bool) {
        var badge = "none"
        if preview.basicMeta.unreadCount > 0 { badge = preview.basicMeta.isRemind ? "number" : "dot" }
        let calltype = isClick ? "click" : isContextMenu ? "contextmenu" : "shortcutkey"
        let source = isClick ? "feedClick" : isContextMenu ? "feedContextMenu" : "feedSlide"
        let params = ["chat_type": preview.chatSubType,
                      "chat_id": preview.id,
                      "badge": badge,
                      "calltype": calltype,
                      "source": source]
        Tracker.post(TeaEvent(Homeric.CHAT_DONE,
                              category: "chat",
                              params: params))
    }

    /// Tabbar点击/双击
    static func trackFeedTap(_ isSingle: Bool) {
        Tracker.post(TeaEvent(Homeric.ICON_FEED_CLICK,
                              params: ["clicktype": isSingle ? "single" : "double"]))
    }

    /// 点击Search Bar跳转SearchVC
    static func trackSearchTap() {
        Tracker.post(TeaEvent(Homeric.ICON_SEARCH_CLICK))
    }

    /// 跳转会话盒子
    public static func trackClickChatbox() {
        Tracker.post(TeaEvent(Homeric.CLICK_CHATBOX))
    }

    /// 通过首页加号进入建群的页面
    static func trackCreateNewGroup() {
        Tracker.post(TeaEvent(Homeric.GROUP_CREATE_VIEW))
    }

    /// Feed下拉加载更多展示菊花
    static func trackFeedLoadingMore() {
        Tracker.post(TeaEvent(Homeric.FEED_LOADING_MORE))
    }

    /// 用户在首页点击扫一扫
    static func trackScan() {
        Tracker.post(TeaEvent(Homeric.SCAN_QRCODE_CONTACTS,
                              params: ["origination": "chat_tab_scan",
                                       "source": "im_add_panel"
                              ]))
    }

    /// Feed + 邀请有奖入口展示  0：无奖  1：有奖
    static func trackReferTenantEnterView(rewardNewTenant: Int) {
        Tracker.post(TeaEvent(Homeric.REFER_TENANT_ENTER_VIEW, params: ["reward_new_tenant": rewardNewTenant]))
    }

    // 点击 feed 流搜索旁 + 号→点击「添加团队成员」
    static func trackInviteMemberInFeedMenu() {
        Tracker.post(TeaEvent(Homeric.ADD_PEOPLE_ENTRY_FEED_MEMBER_CLICK, params: [:]))
    }

    // MARK: - 会话盒子

    // MARK: - 置顶

    /// 从置顶进入chat
    static func trackEnterFromShortCut(chatID: String, type: String, subType: String) {
        trackShortcut(eventName: Homeric.SHORTCUT_CHAT_VIEW, chatID: chatID, type: type, subType: subType)
    }

    /// 添加新置顶
    static func trackAddShortCut(chatID: String, type: String, subType: String) {
        trackShortcut(eventName: Homeric.SHORTCUT_CHAT_ADD, chatID: chatID, type: type, subType: subType)
    }

    /// 删除置顶
    static func trackRemoveShortCut(chatID: String, type: String, subType: String) {
        trackShortcut(eventName: Homeric.SHORTCUT_CHAT_REMOVE, chatID: chatID, type: type, subType: subType)
    }

    /// 收起/展开置顶区
    static func trackShorcutFold(type: ShortcutExpandCollapseType) {
        var event = ""
        var source = ""
        switch type {
        case .expandByClick:
            event = Homeric.SHORTCUT_FOLD
            source = "cilck_button"
        case .collapseByClick:
            event = Homeric.SHORTCUT_UNFOLD
            source = "cilck_button"
        case .expandByScroll:
            event = Homeric.SHORTCUT_FOLD
            source = "drag"
        case .collapseByScroll:
            event = Homeric.SHORTCUT_UNFOLD
            source = "hide"
        case .none:
            break
        @unknown default:
            break
        }

        if !event.isEmpty && !source.isEmpty {
            Tracker.post(TeaEvent(event, category: "Feed", params: ["source": source]))
        }
    }

    /// 私有公用置顶埋点逻辑
    private static func trackShortcut(eventName: String, chatID: String, type: String, subType: String) {
        guard !eventName.isEmpty else {
            assertionFailure("trackShortcut eventName should not be empty!")
            return
        }
        let params: [String: Any] = ["call_type": "click", "type": type, "sub_type": subType, "chat_id": chatID]
        Tracker.post(TeaEvent(eventName, category: "Feed", params: params))
    }

    /// feed页面loading的时间
    static func trackSyncTimeInterval(isLaunching: Bool, interval: CFTimeInterval) {
        FeedContext.log.info("feedlog/monitor/launch/loadFeed. interval: \(interval), isLaunching: \(isLaunching)")
        if isLaunching, AppStartupMonitor.shared.isBackgroundLaunch == true {
            return
        }
        var dict: [String: Any] = [:]
        // 三端统一的打点
        dict = ["islaunching": isLaunching ? "1" : "0",
                "timelong": Int(interval * 1000)]
        Tracker.post(TeaEvent(Homeric.FEED_LOADING_TIME_NEW, params: dict))
        // ios 端的打点
        dict = ["isluanching": isLaunching ? 1 : 0,
                "interval": Float(interval)]
        Tracker.post(TeaEvent(Homeric.FEED_LOADING_TIME, params: dict))
        ColdStartup.shared?.reportForAppReciableFirstFeed(interval * 1000)
    }

    /// 启动到第一次loading结束
    static func trackFirstLoadingFinished() {
        guard AppStartupMonitor.shared.isBackgroundLaunch != true, AppStartupMonitor.shared.isFastLogin == true else { return
        }
        let total = LarkProcessInfo.sinceStart()
        FeedContext.log.info("feedlog/monitor/launch/firstLoadingFinished. total: \(total)")
        Tracker.post(TeaEvent(Homeric.FEED_COLD_START_LOADING_END,
                              params: ["timelong": total]))
        ColdStartup.shared?.reportForAppReciable(.eventTypefirstFeedMeaningfulPaint, total)
    }

    // MARK: 带筛选器的feed
    // 用户点击各分组tab的行为
    static func trackFilterTabClick(filterType: Feed_V1_FeedFilter.TypeEnum) {
        let type = FiltersModel.tabName(filterType)
        Tracker.post(TeaEvent(Homeric.FEED_GROUPING_TAB_CLICK,
                              params: ["feed_type": type]))
    }

    // 用户左右滑动分组筛选项
    static func trackFilterTabSlide() {
        Tracker.post(TeaEvent(Homeric.FEED_GROUPING_TAB_SLIDE))
    }

    // 点击“小电脑”的动作
    static func trackFilterPcClick() {
        Tracker.post(TeaEvent(Homeric.FEED_GROUPING_PC_CLICK))
    }

    // 在各个分组下点击会话的行为 (_ preview: FeedPreview)
    static func trackFilterChatClick(preview: FeedPreview, from: UIViewController) {
        guard let vc = from as? FeedListViewController else { return }
        let type = FiltersModel.tabName(vc.listViewModel.filterType)
        Tracker.post(TeaEvent(Homeric.FEED_CHAT_CLICK,
                              params: ["feed_type": type, "feed_id": preview.id]))
    }

    // 点击该入口后展示页面的曝光数
    static func trackFilterEditView(source: String) {
        guard !source.isEmpty else { return }
        Tracker.post(TeaEvent(Homeric.FEED_GROUPING_EDIT_VIEW,
                              params: ["source": source]))
    }

    // 该页面点击取消的行为
    static func trackFilterEditClose() {
        Tracker.post(TeaEvent(Homeric.FEED_GROUPING_EDIT_CLOSE))
    }

    // 该页面点击保存的行为
    static func trackFilterEditSave(_ list: String) {
        Tracker.post(TeaEvent(Homeric.FEED_GROUPING_EDIT_SAVE,
                              params: ["feed_type_list": list,
                                       "feed_type_number": list.count]))
    }

    // 在编辑页打开或关闭消息筛选器
    static func trackFilterEditOpen(status: Bool) {
        Tracker.post(TeaEvent(Homeric.FEED_GROUPING_EDIT_FILTER_TOGGLE,
                              params: ["status": status ? "on" : "off"]))
    }

    // MARK: - 团队加入卡片

    // 移动端主动加入团队成功后切换身份通知卡片推送的时间点
    static func trackTeamJoinActiveAlertCardShow() {
        Tracker.post(TeaEvent(Homeric.MOBILE_SWITCH_TEAM_NOTICE_CARD_ACTIVELY_SHOW))
    }

    // 移动端主动加入团队成功后切换身份通知卡片点击的时间点
    static func trackTeamJoinActiveAlertCardClick(alertClickType: String) {
        Tracker.post(TeaEvent(Homeric.MOBILE_SWITCH_TEAM_NOTICE_CARD_ACTIVELY_CLICK,
                              params: ["ug_click_type": alertClickType]))
    }

    // 移动端被邀请加入团队成功后切换身份通知卡片推送的时间点
    static func trackTeamJoinInviteAlertCardShow() {
        Tracker.post(TeaEvent(Homeric.MOBILE_SWITCH_TEAM_NOTICE_CARD_PASSIVELY_SHOW))
    }

    // 移动端被邀请加入团队成功后切换身份通知卡片点击的时间点
    static func trackTeamJoinInviteAlertCardClick(alertClickType: String) {
        Tracker.post(TeaEvent(Homeric.MOBILE_SWITCH_TEAM_NOTICE_CARD_PASSIVELY_CLICK,
                              params: ["ug_click_type": alertClickType]))
    }

    // 移动端切换团队功能引导气泡展示的时间点
    static func trackTeamJoinBubbleShow() {
        Tracker.post(TeaEvent(Homeric.MOBILE_SWITCH_TEAM_GUIDANCE_SHOW))
    }

    // 移动端切换团队功能引导气泡点击知道了的时间点
    static func trackTeamJoinBubbleClose() {
        Tracker.post(TeaEvent(Homeric.MOBILE_SWITCH_TEAM_GUIDANCE_CLICK))
    }
    //无网提示
    static func trackNetworkUnavailableView() {
        var trackerParams: [String: String] = ["network_error_type": "unavailable"]
        Tracker.post(TeaEvent(Homeric.PUBLIC_NETWORK_BANNER_VIEW,
                              params: trackerParams))
    }
    //网络错误提示
    static func trackNetworkUnconnectedView() {
        var trackerParams: [String: String] = ["network_error_type": "unconnected"]
        Tracker.post(TeaEvent(Homeric.PUBLIC_NETWORK_BANNER_VIEW,
                              params: trackerParams))
    }
    //网络错误点击
    static func trackNetworkUnavailableClick() {
        var trackerParams: [String: String] = ["click": "network_check"]
        Tracker.post(TeaEvent(Homeric.PUBLIC_NETWORK_BANNER_CLICK,
                              params: trackerParams))
    }
    //无网点击
    static func trackNetworkUnconnectedClick() {
        var trackerParams: [String: String] = ["click": "network_setting"]
        Tracker.post(TeaEvent(Homeric.PUBLIC_NETWORK_BANNER_CLICK,
                              params: trackerParams))
    }

    // MARK: - 标签
    static func creatLabelConfirmClick(labelId: Int64) {
        var trackerParams: [String: String] = ["click": "create", "label_id": String(labelId), "target": "none"]
        Tracker.post(TeaEvent("feed_create_label_click", params: trackerParams))
    }

    static func editLabelView(labelId: Int64) {
        var trackerParams: [String: String] = ["label_id": String(labelId)]
        Tracker.post(TeaEvent("feed_edit_label_view", params: trackerParams))
    }

    static func editLabelCancelClick(labelId: Int64) {
        var trackerParams: [String: String] = ["label_id": String(labelId),
                                               "click": "cancel",
                                               "target": "feed_create_label_view"]
        Tracker.post(TeaEvent("feed_edit_label_click", params: trackerParams))
    }

    static func editLabelConfirmClick(labelId: Int64, isChanged: Bool) {
        let nameChange = isChanged ? "true" : "false"
        var trackerParams: [String: String] = ["label_id": String(labelId),
                                               "click": "confirm",
                                               "target": "none",
                                               "is_name_change": nameChange]
        Tracker.post(TeaEvent("feed_edit_label_click", params: trackerParams))
    }

    static func selectLabelConfirmClick(changType: String) {
        var trackerParams: [String: String] = ["click": "confirm",
                                               "target": "none",
                                               "change": changType]
        Tracker.post(TeaEvent("feed_mobile_label_setting_click", params: trackerParams))
    }

    static func selectLabelCreateClick() {
        var trackerParams: [String: String] = ["click": "create_label",
                                               "target": "feed_create_label_view"]
        Tracker.post(TeaEvent("feed_mobile_label_setting_click", params: trackerParams))
    }
}

extension FeedPreview {
    public var chatSubType: String {
        switch basicMeta.feedPreviewPBType {
        case .chat:
            if preview.chatData.isMeeting {
                return "meeting"
            } else {
                if preview.chatData.chatterType == .bot {
                    return "single_bot"
                }
                switch preview.chatData.chatType {
                case .group:
                    return "group"
                case .p2P:
                    return "single"
                case .topicGroup:
                    return "topicGroup"
                @unknown default:
                    return "unknown"
                }
            }
        case .myAi:
            return "myai"
        case .email, .emailRootDraft: return "mail"
        case .docFeed:
            switch preview.docData.docType {
            case .unknown:
                return "unknown"
            case .doc:
                return "doc"
            case .sheet:
                return "sheet"
            case .bitable:
                return "bitable"
            case .mindnote:
                return "mindnote"
            case .file:
                return "file"
            case .slide:
                return "slide"
            case .docx:
                return "docx"
            case .wiki:
                return "wiki"
            case .folder:
                return "folder"
            case .catalog:
                return "catalog"
            case .slides:
                return "slides"
            case .shortcut:
                return "shortcut"
            @unknown default:
                return "unknown"
            }
        case .thread, .msgThread: return "thread"
        case .box: return "box"
        case .openapp: return "openapp"
        case .topic: return "topic"
        case .subscription: return "subscription"
        case .unknownEntity: return "unknown"
        @unknown default: return "unknown"
        }
    }

    public var chatTotalType: String {
        switch basicMeta.feedPreviewPBType {
        case .chat:
            return "chat"
        case .myAi:
            return "myai"
        case .email, .emailRootDraft:
            return "mail"
        case .docFeed:
            return "space"
        case .thread, .msgThread:
            return "thread"
        case .box:
            return "box"
        case .openapp:
            return "openapp"
        case .topic:
            return "topic"
        case .subscription:
            return "subscription"
        case .unknownEntity:
            return "unknown"
        @unknown default:
            return "unknown"
        }
    }
}
