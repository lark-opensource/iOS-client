//
//  Resources.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/2/13.
//

import UIKit
import Foundation
import LarkLocalizations
import UniverseDesignIcon
import UniverseDesignEmpty
import LarkIllustrationResource

public final class Resources {
    public static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkThreadBundle, compatibleWith: nil) ?? UIImage()
    }
    // thread chat
    static let threadMessageComment = UDIcon.getIconByKey(.replyCnOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 18, height: 18))
    static let threadMessageSendLoading = Resources.image(named: "send_loading")
    static let rightMaskOfSegment = Resources.image(named: "rightMaskOfSegment")
    static let threadMessageSendFail = Resources.image(named: "send_fail")
    //udicon 使用colorful的图片的时候，在这里直接定义uiimage的时候似乎无法适配darkmode，所以写成block，在给imageview赋值时再取
    static let thread_following: (() -> UIImage) = {
        return UDIcon.getIconByKey(.resolveColorful, size: CGSize(width: 18, height: 18))
    }
    static let empty_onboarding = LarkIllustrationResource.Resources.imSpecializedGuidePosting
    static let thread_close = UDIcon.getIconByKey(.noOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 14, height: 14))
    static let threadReplyTriangle = Resources.image(named: "threadReplyTriangle")
    static let thread_announcement_announcement_icon = UDIcon.getIconByKey(.boardsFilled, iconColor: UIColor.ud.colorfulYellow, size: CGSize(width: 12, height: 12))
    static let feed_at_all_border = Resources.image(named: "feed_at_all_border")
    static let feed_at_me_border = Resources.image(named: "feed_at_me_border")
    static let thread_new = Resources.image(named: "thread_chat_new")
    static let thread_chat_new_highlight = Resources.image(named: "thread_chat_new_highlight")
    static let replyThreadError = UDEmptyType.noWifi.defaultImage()

    static let thread_member_icon = UDIcon.getIconByKey(.groupOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 14, height: 14))
    static let thread_header_share = UDIcon.getIconByKey(.shareOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 16, height: 16))
    static let thread_tabbar_shadow = UDIcon.getIconByKey(.chatTopicFilled, iconColor: UIColor.ud.iconDisabled, size: CGSize(width: 22, height: 22))
    static let thread_tabbar_light = UDIcon.getIconByKey(.chatTopicFilled, iconColor: UIColor.ud.colorfulBlue, size: CGSize(width: 22, height: 22))
    static let thread_chat_drag = Resources.image(named: "thread_chat_drag")
    static let thread_chat_release = Resources.image(named: "thread_chat_release")
    static let thread_chat_forward = UDIcon.getIconByKey(.forwardOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 18, height: 18))

    // menu
    static let thread_delete = UDIcon.getIconByKey(.recallOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
    static let menu_pin = UDIcon.getIconByKey(.pinOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
    static let menu_unPin = UDIcon.getIconByKey(.unpinOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
    static let menu_top = UDIcon.getIconByKey(.setTopOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 22))
    static let menu_cancelTop = UDIcon.getIconByKey(.setTopCancelOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 22))
    static let menu_shareTopic = UDIcon.getIconByKey(.shareOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
    static let thread_menu_close = UDIcon.getIconByKey(.noOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
    static let thread_menu_repon = UDIcon.getIconByKey(.yesOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
    static let thread_more = UDIcon.getIconByKey(.moreOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 16, height: 16))
    static let thread_foward = UDIcon.getIconByKey(.forwardOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
    static let replyInThreadFoward = UDIcon.getIconByKey(.forwardComOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
    static let thread_dislike_topic = Resources.image(named: "thread_dislike_topic")
    static let thread_dislike_group = Resources.image(named: "thread_dislike_group")
    static let thread_dislike_author = UDIcon.getIconByKey(.withdrawcohostOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
    static let check_select = Resources.image(named: "check_select")
    static let check_selected = Resources.image(named: "check_selected")
    static let subserbe_help = UDIcon.getIconByKey(.maybeOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 15, height: 15))
    static let menu_todo = UDIcon.getIconByKey(.tabTodoOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 20, height: 20))

    static let subscribe = UDIcon.getIconByKey(.subscribeAddOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 20, height: 20))
    static let unsubscribe = UDIcon.getIconByKey(.subscribeCancelOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 20, height: 20))
    static let noticeIcon = UDIcon.getIconByKey(.alertsOffOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 20, height: 20))
    static let muteNoticeIcon = UDIcon.getIconByKey(.bellOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 20, height: 20))
    // thread detail
    static let subtitle_arrow = Resources.image(named: "subtitle_arrow")
    static let thread_detail_follow = UDIcon.getIconByKey(.subscribeAddOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
    //udicon 使用colorful的图片的时候，在这里直接定义uiimage的时候似乎无法适配darkmode，所以写成block，在给imageview赋值时再取
    static let thread_detal_following: (() -> UIImage) = {
        return UDIcon.getIconByKey(.resolveColorful, size: CGSize(width: 20, height: 20))
    }

    static let scene_icon = Resources.image(named: "scene_icon")

    static let thread_detail_nav_more = UDIcon.getIconByKey(.moreBoldOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
    static let thread_detail_recall = Resources.image(named: "thread_detail_recall")
    static let thread_detail_reedite = UDIcon.getIconByKey(.rightOutlined, iconColor: UIColor.ud.colorfulBlue, size: CGSize(width: 16, height: 16))

    // thread home
    static let thread_home_right_arrow = UDIcon.getIconByKey(.expandRightFilled, iconColor: UIColor.ud.iconN2, size: CGSize(width: 8, height: 8))
    static let thread_home_create_topic = UDIcon.getIconByKey(.editOutlined, iconColor: UIColor.ud.iconN1) // note: 没有被用上
    static let thread_recommend_group_avatar_bg = Resources.image(named: "thread_recommend_group_avatar_bg")
    static let create_guide = Resources.image(named: "create_guide")

    //newTopic
    static let new_topic_close = UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let new_topic_arrow = UDIcon.getIconByKey(.rightOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 16, height: 16))
    static let new_at_reply_arrow = Resources.image(named: "new_at_reply_arrow")

    //translate
    static let thread_translate_arrow = Resources.image(named: "thread_translate_arrow")

    // suspend (multitasking)
    static let suspend_icon_topic = UDIcon.getIconByKey(.chatTopicOutlined, iconColor: UIColor.ud.iconN1)
    static let suspend_icon_group = UDIcon.getIconByKey(.groupOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 20, height: 20)).withRenderingMode(.alwaysOriginal)
    static let navigation_close_light = UDIcon.closeSmallOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill).withRenderingMode(.alwaysOriginal)
}
