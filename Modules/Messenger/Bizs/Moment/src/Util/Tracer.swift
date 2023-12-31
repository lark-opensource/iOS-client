//
//  Tracer.swift
//  Moment
//
//  Created by liluobin on 2021/3/15.
//

import Foundation
import UIKit
import LKCommonsTracker
import Homeric
import AnimatedTabBar
import LarkTab
import LarkProfile

final class Tracer {
    enum FeedPageViewSource: String {
        case detail = "detail_page"
        case larkTab = "lark_tab"
    }

    enum FeedCardViewSource: String {
        case feed = "feed_page"
        case profile = "community_profile"
    }

    enum NotificationInteraction: String {
        case interaction = "notification_interaction"
        case emoji = "notification_emoji"
    }

    enum NotificationCellType: String {
        case unknown = "unknown"
        case postMention = "post_mention"
        case commentMention = "comment_mention"
        case postReply = "post_reply"
        case commentReply = "comment_reply"
        case follow = "follow"
        case postReaction = "post_reaction"
        case commentReaction = "comment_reaction"
    }

    enum SendPostType: String {
        case inputBox = "feed_input_box"
        case sendBtn = "feed_send_btn"
    }

    enum ReplySource: String {
        case detail = "detail_page"
        case feed = "feed_page"
        case profile = "community_profile"
    }

    enum ContentType: String {
        case post
        case comment
    }

    enum ActionType: String {
        case btn = "btn"
        case long = "long_click"
        case quick = "quick_click"
        case inputBox = "input_box"
    }

    enum ReactionSource: String {
        case btn = "btn"
        case long = "long_click"
        case reaction_list = "reaction_list"
    }

    enum FollowSource: String {
        case detail = "detail_page"
        case notification = "notification_message"
        case profile = "community_profile"
        case follwer = "follwer_page"
        case following = "following_page"
    }

    enum PrfileSource: String {
        case feed = "feed_profile_btn"
        case profile = "lark_profile"
    }

    enum LarkPrfileSource: String {
        case feed = "feed_page"
        case detail = "detail_page"
        case notification = "notification_page"
        case profile = "community_profile"
        case reaction = "reaction_page"
        case categoryDetail = "category_page"
        case unknown = "unknown"
    }

    /// 统计社区主feed的页面曝光
    static func trackCommunitFeedPageView(source: FeedPageViewSource) {
        Tracker.post(TeaEvent(Homeric.COMMUNITY_FEED_PAGE_VIEW, params: ["source": source.rawValue]))
    }

    /// 统计对动态卡片的点击
    static func trackCommunityFeedCardClick(postID: String, source: FeedCardViewSource) {
        Tracker.post(TeaEvent(Homeric.COMMUNITY_FEED_CARD_CLICK, params: [
            "source": source.rawValue,
            "post_id": postID
        ]))
    }
    /// 统计动态详情页的曝光
    static func trackCommunityDetailPageView(postID: String, source: MomentsDetialPageSource) {
        Tracker.post(TeaEvent(Homeric.COMMUNITY_DETAIL_PAGE_VIEW, params: [
            "source": source.rawValue,
            "post_id": postID
        ]))
    }

    /// 统计动态详情页的曝光
    static func trackCommunityTabNotification(type: NotificationInteraction) {
        Tracker.post(TeaEvent(Homeric.COMMUNITY_TAB_NOTIFICATION, params: [
            "to_page": type.rawValue
        ]))
    }

    /// 通知列表页曝光
    static func trackCommunityNotificationPageView(type: NotificationInteraction) {
        Tracker.post(TeaEvent(Homeric.COMMUNITY_NOTIFICATION_PAGE_VIEW, params: [
            "type": type.rawValue
        ]))
    }

    /// 通知列表页单条消息曝光
    static func trackCommunityNotificationCardView(_ type: String) {
        guard !type.isEmpty else {
            return
        }
        Tracker.post(TeaEvent(Homeric.COMMUNITY_NOTIFICATION_INTERACTION_CARD_VIEW, params: [
            "type": type
        ]))
    }

    /// 统计通知列表中各种消息类型的点击次数
    static func trackCommunityNotificationEntryClick(type: NotificationCellType) {
        Tracker.post(TeaEvent(Homeric.COMMUNITY_NOTIFICATION_ENTRY_CLICK, params: [
            "type": type.rawValue
        ]))
    }

    /// 统计点击发布动态按钮的次数
    static func trackCommunitySendPostClick(source: SendPostType) {
        Tracker.post(TeaEvent(Homeric.COMMUNITY_TAB_SEND_POST_CLICK, params: [
            "type": source.rawValue
        ]))
    }

    /// 统计帖子编辑页的曝光量
    static func trackCommunitySendPostPageView(source: String) {
        Tracker.post(TeaEvent(Homeric.COMMUNITY_SEND_POST_PAGE_VIEW, params: [
            "source": source
        ]))
    }

    /// 统计在帖子编辑页点击发送帖子按钮的数量
    static func trackCommunitySendPost() {
        Tracker.post(TeaEvent(Homeric.COMMUNITY_TAB_SEND_POST))
    }

    /// 统计发起回复行为触发量
    static func trackCommunityTabReply(action: ActionType,
                                       contentType: ContentType,
                                       source: ReplySource,
                                       postID: String?,
                                       commentID: String?) {
        var params: [String: String] = [:]
        params["action"] = action.rawValue
        params["type"] = contentType.rawValue
        params["source"] = source.rawValue
        if let postID = postID {
            params["post_id"] = postID
        }
        if let commentID = commentID {
            params["comment_id"] = commentID
        }
        Tracker.post(TeaEvent(Homeric.COMMUNITY_TAB_REPLY, params: params))
    }

    /// 统计点击回复发送按钮的数量
    static func trackCommunityTabReplySend(action: ActionType,
                                       contentType: ContentType,
                                       source: ReplySource,
                                       postID: String?,
                                       commentID: String?) {
        var params: [String: String] = [:]
        params["action"] = action.rawValue
        params["type"] = contentType.rawValue
        params["source"] = source.rawValue
        if let postID = postID {
            params["post_id"] = postID
        }
        if let commentID = commentID {
            params["comment_id"] = commentID
        }
        Tracker.post(TeaEvent(Homeric.COMMUNITY_TAB_REPLY_SEND, params: params))
    }

    /// 统计发送的reaction数量
    static func trackCommunityTabReaction(reaction: ReactionSource,
                                       contentType: ContentType,
                                       source: MomentContextScene,
                                       postID: String?,
                                       commentID: String?,
                                       action: Bool) {
        var params: [String: String] = [:]
        params["reaction_action"] = reaction.rawValue
        params["type"] = contentType.rawValue
        params["action"] = action ? "on" : "off"
        params["source"] = Self.transformMomentContextSceneToStr(source)
        if let postID = postID {
            params["post_id"] = postID
        }
        if let commentID = commentID {
            params["comment_id"] = commentID
        }
        Tracker.post(TeaEvent(Homeric.COMMUNITY_TAB_REACTION, params: params))
    }

    /// 统计关注按钮的点击量
    static func trackCommunityTabFollow(source: FollowSource,
                                        action: Bool,
                                        followId: String) {
        var params: [String: String] = [:]
        params["source"] = source.rawValue
        params["follow_uid"] = followId
        params["action"] = action ? "on" : "off"
        Tracker.post(TeaEvent(Homeric.COMMUNITY_TAB_FOLLOW, params: params, md5AllowList: ["follow_uid"]))
    }

    /// 统计分享按钮的点击量
    static func trackCommunityTabShare(source: MomentContextScene,
                                       postID: String) {
        var sourceStr = ""
        switch source {
        case .feed:
            sourceStr = "feed_page"
        case .postDetail:
            sourceStr = "detail_page"
        case .profile:
            sourceStr = "community_profile"
        case .categoryDetail:
            sourceStr = "category_detail"
        case .unknown, .hashTagDetail:
            break
        }
        var params: [String: String] = [:]
        params["source"] = sourceStr
        params["post_id"] = postID
        Tracker.post(TeaEvent(Homeric.COMMUNITY_TAB_SHARE, params: params))
    }

    /// 统计选择分享对象后在预览页面的分享发送按钮点击量
    static func trackCommunityTabShareSend(success: Bool,
                                           postID: String) {
        var params: [String: String] = [:]
        params["action"] = success ? "on" : "off"
        params["post_id"] = postID
        Tracker.post(TeaEvent(Homeric.COMMUNITY_TAB_SHARE_SEND, params: params))
    }

    /// 统计在社区中打开lark profile页面的次数
    static func trackCommunityEnterLarkProfile(source: LarkPrfileSource?) {
        guard let source = source else {
            return
        }
        Tracker.post(TeaEvent(Homeric.COMMUNITY_ENTER_LARK_PROFILE, params: [
            "source": source.rawValue
        ]))
    }

    /// 统计进入社区profile页面的次数
    static func trackCommunityProfileView(source: PrfileSource) {
        Tracker.post(TeaEvent(Homeric.COMMUNITY_ENTER_COMMUNITY_PROFILE_VIEW, params: [
            "source": source.rawValue
        ]))
    }

    static func transformMomentSceneToPrfileSource(_ sence: MomentContextScene) -> LarkPrfileSource {
        switch sence {
        case .feed:
            return .feed
        case .postDetail:
            return .detail
        case .profile:
            return .profile
        case .categoryDetail:
            return .categoryDetail
        case .unknown, .hashTagDetail:
            return .unknown
        }
    }

    static func transformMomentContextSceneToStr(_ sence: MomentContextScene) -> String {
        var sourceStr = ""
        switch sence {
        case .feed:
            sourceStr = "feed_page"
        case .postDetail:
            sourceStr = "detail_page"
        case .profile:
            sourceStr = "community_profile"
        case .categoryDetail:
            sourceStr = "category_detail"
        case .unknown, .hashTagDetail:
            break
        }
        return sourceStr
    }

    static func transformDetailSourceToPageSource(_ source: String?) -> MomentsDetialPageSource {
        guard let source = source  else {
            return .shareChat
        }
        if source == MomentsDetialPageSource.shareChat.rawValue {
            return .shareChat
        } else if source == MomentsDetialPageSource.pushBot.rawValue {
            return .pushBot
        }
        return .shareChat
    }
}

//新埋点，后面之前的老埋点会被下掉
final class MomentsTracer {
    struct ProfileInfo {
        let profileUserId: String
        let isFollow: Bool?
        let isNickName: Bool
        let isNickNameInfoTab: Bool
        init(profileUserId: String,
             isFollow: Bool? = nil,
             isNickName: Bool,
             isNickNameInfoTab: Bool = false) {
            self.profileUserId = profileUserId
            self.isFollow = isFollow
            self.isNickName = isNickName
            self.isNickNameInfoTab = isNickNameInfoTab
        }

        func getTracerInfo() -> [String: String] {
            var info = ["profile_user_id": profileUserId, "is_nickname": isNickName ? "true" : "false"]
            if let isFollow = self.isFollow {
                info += ["is_follow": isFollow ? "true" : "false"]
            }
            return info
        }

        func getTracerTabInfo() -> [String: String] {
            return ["tab_type": isNickNameInfoTab ? "personal_information" : "interactive_content",
                    "is_nickname": isNickName ? "true" : "false"]
        }

    }
    enum PageIdInfo {
        case tabInfo(RawData.PostTab?)
        case pageId(String?)
        var pageId: String {
            switch self {
            case .pageId(let id):
                return id ?? "none"
            case .tabInfo(let tab):
                return categoryId(tab)
            }
        }
    }

    enum CommonParamsKeys: String {
        case circle_id
        case post_id
        case category_id
        case page_id
        case page_type
    }

    enum PageType {
        case tabInfo(RawData.PostTab?)
        case recommendTab//用在点击“置顶动态”等情况，不易拿到RawData.PostTab但可以断定为“推荐页”时
        case category(String)//只用在板块页面，拿不到RawData.PostTab时
        case hashtag(String)
        case moments_profile

        var rawValue: String {
            switch self {
            case .tabInfo(let info):
                return pageType(info)
            case .recommendTab:
                return "1"
            case .category:
                return "3"
            case .hashtag:
                return "5"
            case .moments_profile:
                return "6"
            }
        }

        var getCategoryId: String {
            switch self {
            case .tabInfo(let info):
                return categoryId(info)
            case .recommendTab:
                return "1"
            case .category(let categoryId):
                return categoryId
            default:
                return "none"
            }
        }

        var getHashtagId: String {
            switch self {
            case .hashtag(let hashTagId):
                return hashTagId
            default:
                return "none"
            }
        }

        //有板块id返回板块id，否则返回hashtagid，都没有返回none
        var getPageId: String {
            return getCategoryId == "none" ? getHashtagId : getCategoryId
        }
    }

    //点击更多...按钮的页面
    enum MenuViewPageType: String {
        //1:「feed页内点击帖子 •••按钮」后展示页面;
        case feed = "1"
        //2:「帖子详情页内点击帖子 •••按钮」后展示页面;
        case detailPost = "2"
        //3:「帖子详情页内点击评论 •••按钮」后展示页面（仅PC端）
        case detailComment = "3"
        //4:「profile页内点击帖子 •••按钮」后展示页面;"
        case profile = "4"
    }

    enum PageDetail: String {
        case category_comment
        case category_post
        case category_recommend
        case hashtag_hot
        case hashtag_new
        case hashtag_recommend
    }

    fileprivate static func pageType(_ tabInfo: RawData.PostTab?) -> String {
        guard let tabInfo = tabInfo else {
            return "none"
        }
        let pageType: Int
        if tabInfo.isRecommendTab {
            pageType = 1
        } else if tabInfo.isFollowTab {
            pageType = 2
        } else {
            pageType = 3
        }
        return "\(pageType)"
    }

    fileprivate static func categoryId(_ tabInfo: RawData.PostTab?) -> String {
        guard let tabInfo = tabInfo else {
            return "none"
        }
        if tabInfo.isCategoryTab {
            return tabInfo.id
        } else if tabInfo.isRecommendTab {
            return "1"
        }
        return "none"
    }

    /// 统计feed的页面曝光
    static func trackFeedPageView(circleId: String? = nil,
                                  type: PageType,
                                  detail: PageDetail?,
                                  porfileInfo: ProfileInfo? = nil) {
        let circleId: String = circleId ?? "none"
        let pageDetail: String = detail?.rawValue ?? "none"
        var params = [CommonParamsKeys.circle_id.rawValue: circleId,
                      CommonParamsKeys.page_id.rawValue: type.getPageId,
                      CommonParamsKeys.post_id.rawValue: "none",
                      "page_detail": pageDetail,
                      "page_type": type.rawValue]
        if let porfileInfo = porfileInfo {
            if !porfileInfo.isNickName {
                params += porfileInfo.getTracerInfo()

            } else {
                params += porfileInfo.getTracerTabInfo()
            }
        }
        Tracker.post(TeaEvent(Homeric.MOMENTS_FEED_PAGE_VIEW, params: params))
    }

    enum FeedPageViewClickType {
        case from_category
        case post_press
        case comment_press
        case follow
        case follow_cancel
        case follow_page
        case followed_page
        case category
        case notification(Int)
        case moments_profile
        case other_profile
        case post
        case reaction
        case comment
        case share
        case more
        case post_edit
        case reaction_press
        case top
        case category_setting
        case hashtag
        case slide
        case personal_information

        var rawValue: String {
            switch self {
            case .from_category:
                return "from_category"
            case .post_press:
                return "post_press"
            case .comment_press:
                return "comment_press"
            case .follow:
                return "follow"
            case .follow_cancel:
                return "follow_cancel"
            case .follow_page:
                return "follow_page"
            case .followed_page:
                return "followed_page"
            case .category:
                return "category"
            case .notification:
                return "notification"
            case .moments_profile:
                return "moments_profile"
            case .other_profile:
                return "other_profile"
            case .post:
                return "post"
            case .reaction:
                return "reaction"
            case .comment:
                return "comment"
            case .share:
                return "share"
            case .more:
                return "more"
            case .post_edit:
                return "post_edit"
            case .reaction_press:
                return "reaction_press"
            case .top:
                return "top"
            case .category_setting:
                return "category_setting"
            case .hashtag:
                return "hashtag"
            case .slide:
                return "slide"
            case .personal_information:
                return "personal_information_description"
            }
        }

        var target: String {
            switch self {
            case .from_category, .category, .hashtag:
                return "moments_feed_page_view"
            case .follow_page, .followed_page:
                return "moments_follow_page_view"
            case .notification:
                return "moments_notification_page_view"
            case .moments_profile:
                return "moments_profile_view"
            case .other_profile:
                return "profile_main_view"
            case .post, .top:
                return "moments_detail_page_view"
            case .reaction, .slide, .follow, .follow_cancel, .personal_information:
                return "none"
            case .comment:
                return "moments_detail_page_view"
            case .share:
                return "public_multi_select_share_view"
            case .more:
                return "moments_post_more_view"
            case .post_edit:
                return "moments_edit_page_view"
            case .post_press, .comment_press, .reaction_press:
                return "moments_msg_menu_view"
            case .category_setting:
                return "moments_category_setting_view"
            }
        }
    }

    //统计feed页面点击
    static func trackFeedPageViewClick(_ clickType: FeedPageViewClickType,
                                       circleId: String? = nil,
                                       postId: String? = nil,
                                       type: PageType?,
                                       detail: PageDetail?,
                                       profileInfo: ProfileInfo? = nil) {
        let pageDetail: String = detail?.rawValue ?? "none"
        var params: [String: Any] = [CommonParamsKeys.circle_id.rawValue: circleId ?? "none",
                                     CommonParamsKeys.post_id.rawValue: postId ?? "none",
                                     CommonParamsKeys.page_id.rawValue: type?.getPageId ?? "none",
                                     "click": clickType.rawValue,
                                     "page_detail": pageDetail,
                                     "page_type": type?.rawValue ?? "none",
                                     "target": clickType.target]
        switch clickType {
        case .notification(let badgeCount):
            params["badge_count"] = badgeCount
        default:
            break
        }
        if let profileInfo = profileInfo {
            if profileInfo.isNickName {
                params += profileInfo.getTracerTabInfo()
            } else {
                params += profileInfo.getTracerInfo()
            }
        }
        Tracker.post(TeaEvent(Homeric.MOMENTS_FEED_PAGE_CLICK, params: params, md5AllowList: ["profile_user_id"]))
    }

    /// 统计帖子详情页面曝光
    static func trackDetailPageView(entity: RawData.PostEntity) {
        let isFollowed = entity.user?.isCurrentUserFollowing ?? false
        let categoryId: String = entity.post.categoryIds.first ?? "none"
        Tracker.post(TeaEvent(Homeric.MOMENTS_DETAIL_PAGE_VIEW, params: [CommonParamsKeys.circle_id.rawValue: entity.circleId,
                                                                         CommonParamsKeys.post_id.rawValue: entity.postId,
                                                                         CommonParamsKeys.page_id.rawValue: categoryId,
                                                                         "is_follow": isFollowed ? "true" : "false",
                                                                         "show_status": "success",
                                                                         "fail_type": "none"]))
    }

    /// 统计帖子详情页面曝光(展示失败时)
    static func trackDetailPageViewWhenFail(postId: String?, circleId: String?) {
        if postId == nil || circleId == nil {
            return
        }
        Tracker.post(TeaEvent(Homeric.MOMENTS_DETAIL_PAGE_VIEW, params: [CommonParamsKeys.circle_id.rawValue: circleId,
                                                                         CommonParamsKeys.post_id.rawValue: postId,
                                                                         CommonParamsKeys.page_id.rawValue: "none",
                                                                         "is_follow": "none",
                                                                         "show_status": "fail",
                                                                         "fail_type": "other"]))
    }

    enum DetailPageClickType {
        case other_profile
        case follow(String)
        case follow_cancel(String)
        case category
        case reaction
        case comment
        case reply_comment
        case post_press
        case comment_press
        case reaction_press
        case share
        case more
        case input_emoji
        case input_picture
        case tumbsdown(Bool)

        var rawValue: String {
            switch self {
            case .other_profile:
                return "other_profile"
            case .follow:
                return "follow"
            case .follow_cancel:
                return "follow_cancel"
            case .category:
                return "category"
            case .reaction:
                return "reaction"
            case .comment:
                return "comment"
            case .reply_comment:
                return "reply_comment"
            case .post_press:
                return "post_press"
            case .comment_press:
                return "comment_press"
            case .reaction_press:
                return "reaction_press"
            case .share:
                return "share"
            case .more:
                return "more"
            case .input_emoji:
                return "input_emoji"
            case .input_picture:
                return "input_picture"
            case .tumbsdown:
                return "thumbsdown"
            }
        }

        var target: String {
            switch self {
            case .other_profile:
                return "profile_main_view"
            case .follow:
                return "none"
            case .follow_cancel:
                return "none"
            case .category:
                return "moments_feed_page_view"
            case .reaction, .comment, .reply_comment:
                return "none"
            case .post_press, .comment_press, .reaction_press:
                return "moments_msg_menu_view"
            case .share:
                return "moments_share_select_view"
            case .more:
                return "moments_post_more_view"
            case .input_emoji:
                return "public_emoji_panel_select_view"
            case .input_picture:
                return "moments_image_send_view"
            case .tumbsdown:
                return "none"
            }
        }
    }

    enum NotificationPageClickType {
        case otherProfile
        case followMsg
        case follow
        case followCancel
        case postMention
        case commentMention
        case postReply
        case commentReply
        case postReaction
        case commentReaction
        case others

        var rawValue: String {
            switch self {
            case .otherProfile:
                return "other_profile"
            case .followMsg:
                return "follow_msg"
            case .follow:
                return "follow"
            case .followCancel:
                return "follow_cancel"
            case .postMention:
                return "post_mention"
            case .commentMention:
                return "comment_mention"
            case .postReply:
                return "post_reply"
            case .commentReply:
                return "comment_reply"
            case .postReaction:
                return "post_reaction"
            case .commentReaction:
                return "comment_reaction"
            case .others:
                return "others"
            }
        }

        var target: String {
            switch self {
            case .otherProfile, .followMsg:
                return "profile_main_view"
            case .follow, .followCancel:
                return "none"
            case .postMention, .commentMention, .postReply,
                 .commentReply, .postReaction, .commentReaction:
                return "moments_detail_page_view"
            case .others:
                return "moments_feed_page_view"
            }
        }
    }

    enum FollowPageClickType {
        case otherProfile
        case follow(String)
        case followCancel(String)
        case momentsProfile

        var rawValue: String {
            switch self {
            case .otherProfile:
                return "other_profile"
            case .momentsProfile:
                return "moments_profile"
            case .follow:
                return "follow"
            case .followCancel:
                return "follow_cancel"
            }
        }

        var target: String {
            switch self {
            case .otherProfile:
                return "profile_main_view"
            case .follow, .followCancel:
                return "none"
            case .momentsProfile:
                return "moments_feed_page_view"
            }
        }
    }

    /// 统计帖子详情页面点击事件
    static func trackDetailPageClick(_ clickType: DetailPageClickType,
                                     circleId: String? = nil,
                                     postId: String? = nil,
                                     pageIdInfo: PageIdInfo? = nil) {
        var params: [String: Any] = [CommonParamsKeys.circle_id.rawValue: circleId ?? "none",
                                     CommonParamsKeys.post_id.rawValue: postId ?? "none",
                                     CommonParamsKeys.page_id.rawValue: pageIdInfo?.pageId ?? "none",
                                     "target": clickType.target,
                                     "click": clickType.rawValue]
        switch clickType {
        case .follow(let id), .follow_cancel(let id):
            params["follow_user_id"] = id
        case .tumbsdown(let tumbsdown):
            params["status"] = tumbsdown ? "add" : "remove"
        default:
            break
        }
        Tracker.post(TeaEvent(Homeric.MOMENTS_DETAIL_PAGE_CLICK, params: params, md5AllowList: ["follow_user_id"]))
    }

    static func detailPageMenuView(circleId: String? = nil,
                                   postId: String? = nil,
                                   pageIdInfo: PageIdInfo,
                                   pageType: MenuViewPageType) {
        let params: [String: Any] = [CommonParamsKeys.circle_id.rawValue: circleId ?? "none",
                                     CommonParamsKeys.post_id.rawValue: postId ?? "none",
                                     CommonParamsKeys.page_id.rawValue: pageIdInfo.pageId,
                                     CommonParamsKeys.page_type.rawValue: pageType.rawValue]
        Tracker.post(TeaEvent(Homeric.MOMENTS_MSG_MENU_VIEW, params: params))
    }

    static func detailPageMenuClick(clickType: PostMoreClickType,
                                    circleId: String? = nil,
                                    postId: String? = nil,
                                    pageIdInfo: PageIdInfo,
                                    pageType: MenuViewPageType) {
        let params: [String: Any] = [CommonParamsKeys.circle_id.rawValue: circleId ?? "none",
                                     CommonParamsKeys.post_id.rawValue: postId ?? "none",
                                     CommonParamsKeys.page_id.rawValue: pageIdInfo.pageId,
                                     CommonParamsKeys.page_type.rawValue: pageType.rawValue,
                                     "click": clickType.rawValue,
                                     "target": clickType.target,
                                     "button_status": clickType.buttonStatus]
        Tracker.post(TeaEvent(Homeric.MOMENTS_MSG_MENU_CLICK, params: params))
    }

    static func trackPostMoreView(circleId: String? = nil,
                                  postId: String? = nil,
                                  pageIdInfo: PageIdInfo,
                                  pageType: MenuViewPageType) {
        let params: [String: Any] = [CommonParamsKeys.circle_id.rawValue: circleId ?? "none",
                                     CommonParamsKeys.post_id.rawValue: postId ?? "none",
                                     CommonParamsKeys.page_id.rawValue: pageIdInfo.pageId,
                                     CommonParamsKeys.page_type.rawValue: pageType.rawValue]
        Tracker.post(TeaEvent(Homeric.MOMENTS_POST_MORE_VIEW, params: params))
    }

    enum TranslateButtonStatus: String {
        case translate
        case show_original_text
        case switch_languages
    }

    enum PostMoreClickType {
        case translateButton(TranslateButtonStatus)

        var rawValue: String {
            switch self {
            case .translateButton:
                return "translate_button"
            }
        }

        var target: String {
            switch self {
            case .translateButton:
                return "none"
            }
        }

        var buttonStatus: String {
            switch self {
            case .translateButton(let status):
                return status.rawValue
            }
        }
    }

    static func trackPostMoreClick(clickType: PostMoreClickType,
                                   circleId: String? = nil,
                                   postId: String? = nil,
                                   pageIdInfo: PageIdInfo,
                                   pageType: MenuViewPageType) {
        let params: [String: Any] = [CommonParamsKeys.circle_id.rawValue: circleId ?? "none",
                                     CommonParamsKeys.post_id.rawValue: postId ?? "none",
                                     CommonParamsKeys.page_id.rawValue: pageIdInfo.pageId,
                                     CommonParamsKeys.page_type.rawValue: pageType.rawValue,
                                     "target": clickType.target,
                                     "click": clickType.rawValue,
                                     "button_status": clickType.buttonStatus]
        Tracker.post(TeaEvent(Homeric.MOMENTS_POST_MORE_CLICK, params: params))
    }

    static func trackProfileMomentTabClick(userID: String) {
        var params: [AnyHashable: Any] = [:]
        params["click"] = "moments_tab"

        if let map = LarkProfileTracker.userMap[userID],
           let contactType = map["contact_type"] {
            params["contact_type"] = contactType
        }
        params["to_user_id"] = userID
        params["target"] = "moments_profile_view"
        Tracker.post(TeaEvent(Homeric.PROFILE_MAIN_CLICK, params: params, md5AllowList: ["to_user_id"]))
    }

    //统计公司圈tab被点击
    static func trackNavigationClick(tabType: TabType,
                                           badge: BadgeType?,
                                           isReminder: Bool,
                                           circleId: String? = nil,
                                           pageType: PageType? = nil) {
        let target = "moments_feed_page_view"
        var location = "none"
        var order: String = "none"
        var badgeNumer = 0
        var badgeType = "none"
        switch tabType {
        case .mainTab(let index):
            location = "primary"
            order = "\(index + 1)"
        case .quickTab(let index):
            location = "quick"
            order = "\(index + 1)"
        default:
            break
        }
        if let badge = badge {
            switch badge {
            case .number(let badge):
                badgeNumer = badge
                badgeType = "red_number"
            case .dot:
                badgeType = "red_dot"
            default:
                break
            }
        }
        let params: [String: Any] = ["click": "moments",
                                     CommonParamsKeys.circle_id.rawValue: circleId ?? "none",
                                     CommonParamsKeys.page_id.rawValue: pageType?.getPageId ?? "none",
                                     "location": location,
                                     "page_type": pageType?.rawValue ?? "none",
                                     "target": target,
                                     "order": order,
                                     "badge_number": badgeNumer,
                                     "badge_type": badgeType,
                                     "is_reminder": isReminder ? "true" : "false"]
        Tracker.post(TeaEvent(Homeric.MOMENTS_NAVIGATION_CLICK, params: params))
    }

    enum SettingDetailClickType {
        case notice(Bool)
    }

    static func trackSettingDetailClick(type: SettingDetailClickType) {
        var click: String = ""
        let target = "none"
        switch type {
        case .notice(let enable):
            if enable {
                click = "moments_on_notice"
            } else {
                click = "moments_off_notice"
            }
        default:
            break
        }
        Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: ["click": click, "target": target]))
    }

    /// 统计通知的曝光
    static func trackNotificationPageViewWith(isInteraction: Bool, circleId: String?) {
        let params: [String: Any] = [CommonParamsKeys.circle_id.rawValue: circleId ?? "none",
                                     CommonParamsKeys.post_id.rawValue: "none",
                                     CommonParamsKeys.page_id.rawValue: "none",
                                     "notification_type": isInteraction ? "interaction" : "emoji"]
        Tracker.post(TeaEvent(Homeric.MOMENTS_NOTIFICATION_PAGE_VIEW, params: params))
    }

    /// 统计通知的点击
    static func trackNotificationPageClickWith(type: NoticeList.SourceType,
                                               followUserId: String? = nil,
                                               clickType: NotificationPageClickType,
                                               circleId: String? = nil,
                                               postId: String? = nil,
                                               pageIdInfo: PageIdInfo? = nil) {
        var params = [CommonParamsKeys.circle_id.rawValue: circleId ?? "none",
                      CommonParamsKeys.post_id.rawValue: postId ?? "none",
                      CommonParamsKeys.page_id.rawValue: pageIdInfo?.pageId ?? "none",
                      "notification_type": type == .message ? "interaction" : "emoji",
                      "click": clickType.rawValue,
                      "target": clickType.target]
        if let followUserId = followUserId {
            params.updateValue(followUserId, forKey: "follow_user_id")
            Tracker.post(TeaEvent(Homeric.MOMENTS_NOTIFICATION_PAGE_CLICK, params: params, md5AllowList: ["follow_user_id"]))
        } else {
            Tracker.post(TeaEvent(Homeric.MOMENTS_NOTIFICATION_PAGE_CLICK, params: params))
        }
    }

    static func trackMomentsEditPageViewWith(circleId: String? = nil,
                                              postId: String? = nil,
                                              pageIdInfo: PageIdInfo? = nil) {
        let params = [CommonParamsKeys.circle_id.rawValue: circleId ?? "none",
                      CommonParamsKeys.post_id.rawValue: postId ?? "none",
                      CommonParamsKeys.page_id.rawValue: pageIdInfo?.pageId ?? "none"]
        Tracker.post(TeaEvent(Homeric.MOMENTS_EDIT_PAGE_VIEW, params: params))
    }

    static func trackMomentsEditPageClickWith(circleId: String? = nil,
                                               postId: String? = nil,
                                               pageIdInfo: PageIdInfo? = nil) {
        let params = [CommonParamsKeys.circle_id.rawValue: circleId ?? "none",
                      CommonParamsKeys.post_id.rawValue: postId ?? "none",
                      CommonParamsKeys.page_id.rawValue: pageIdInfo?.pageId ?? "none",
                      "click": "post_send",
                      "target": "moments_feed_page_view"]
        Tracker.post(TeaEvent(Homeric.MOMENTS_EDIT_PAGE_CLICK, params: params))
    }

    static func trackMomentsFollowPageClickWith(circleId: String? = nil,
                                               postId: String? = nil,
                                               pageIdInfo: PageIdInfo? = nil,
                                               isFollowUsers: Bool,
                                               type: FollowPageClickType) {
        var params = [CommonParamsKeys.circle_id.rawValue: circleId ?? "none",
                      CommonParamsKeys.post_id.rawValue: postId ?? "none",
                      CommonParamsKeys.page_id.rawValue: pageIdInfo?.pageId ?? "none",
                      "click": type.rawValue,
                      "target": type.target,
                      "page_type": isFollowUsers ? "follow" : "followed"]
        var followUserId: String = ""
        switch type {
        case .follow(let userID):
            followUserId = userID
        case .followCancel(let userID):
            followUserId = userID
        default: break
        }
        if !followUserId.isEmpty {
            params["follow_user_id"] = followUserId
            Tracker.post(TeaEvent(Homeric.MOMENTS_FOLLOW_PAGE_CLICK, params: params, md5AllowList: [
            "follow_user_id"]))
        } else {
            Tracker.post(TeaEvent(Homeric.MOMENTS_FOLLOW_PAGE_CLICK, params: params))
        }
    }

    static func trackMomentsFollowPageViewWith(circleId: String? = nil,
                                               postId: String? = nil,
                                               pageIdInfo: PageIdInfo? = nil,
                                               isFollowUsers: Bool) {
        let params = [CommonParamsKeys.circle_id.rawValue: circleId ?? "none",
                      CommonParamsKeys.post_id.rawValue: postId ?? "none",
                      CommonParamsKeys.page_id.rawValue: pageIdInfo?.pageId ?? "none",
                      "page_type": isFollowUsers ? "follow" : "followed"]
        Tracker.post(TeaEvent(Homeric.MOMENTS_FOLLOW_PAGE_VIEW, params: params))
    }

}

final class MomentsFeedPageShowClickTracker {
    private var displayPostIds: Set<String> = Set()
    private var postCircleIds: [String: String] = [:]
    var pageType: MomentsTracer.PageType
    var pageDetail: MomentsTracer.PageDetail?

    init(pageType: MomentsTracer.PageType, pageDetail: MomentsTracer.PageDetail?) {
        self.pageType = pageType
        self.pageDetail = pageDetail
    }

    func insert(postId: String, cirleId: String) {
        self.displayPostIds.insert(postId)
        postCircleIds[postId] = cirleId
    }

    func remove(postId: String) {
        self.displayPostIds.remove(postId)
        postCircleIds.removeValue(forKey: postId)
    }

    func trackCommunityFeedCardView() {
        let detail: String = pageDetail?.rawValue ?? "none"
        for postId in displayPostIds {
            let circleId: String = self.postCircleIds[postId] ?? "none"
            Tracker.post(TeaEvent(Homeric.MOMENTS_FEED_PAGE_SHOW_CLICK, params: [
                MomentsTracer.CommonParamsKeys.circle_id.rawValue: circleId,
                MomentsTracer.CommonParamsKeys.post_id.rawValue: postId,
                MomentsTracer.CommonParamsKeys.page_id.rawValue: pageType.getPageId,
                "page_type": pageType.rawValue,
                "page_detail": detail
            ]))
        }
        // 上报完成 移除元素
        displayPostIds.removeAll()
        postCircleIds.removeAll()
    }
}
