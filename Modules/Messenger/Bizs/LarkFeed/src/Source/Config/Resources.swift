//
//  Resources.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/7.
//

import Foundation
import UIKit
import LarkUIKit
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignTheme
import LarkAppResources
import LarkFeedBase

#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif

// swiftlint:disable identifier_name
let SelfBundle: Bundle = {
    if let url = Bundle.main.url(forResource: "Frameworks/LarkFeed", withExtension: "framework") {
        return Bundle(url: url)!
    } else {
      // 单测会有问题，所以DEBUG模式不动
      #if DEBUG
        return Bundle(for: BundleConfig.self)
      #else
        return Bundle.main
      #endif
    }
}()

let LarkFeedBundle = Bundle(url: SelfBundle.url(forResource: "LarkFeed", withExtension: "bundle")!)!
// swiftlint:enable identifier_name

final public class Resources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "LarkFeed.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: LarkFeedBundle, compatibleWith: nil) ?? UIImage()
    }

    static let conversation_plus_light = UDIcon.moreAddOutlined.ud.withTintColor(UIColor.ud.iconN1)

    static let feed_avatar_inner_border = LarkFeedBase.Resources.LarkFeedBase.urgentBorderImage
    public static let feed_box_avatar = Resources.image(named: "feed_box_avatar")
    static let feed_done_icon = UDIcon.getIconByKey(.doneOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let feed_label_icon = UDIcon.getIconByKey(.labelChangeOutlined, size: CGSize(width: 18, height: 18))
        .ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    public static let feed_read_icon = UDIcon.getIconByKey(.feedReadOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.T400 & UIColor.ud.T500)
    static public let feed_unread_icon = UDIcon.getIconByKey(.feedUnreadOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconDisabled)
    public static let feed_draft_icon = UDIcon.getIconByKey(.editContinueOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulRed)

    static let badge_at_icon = UDIcon.getIconByKey(.atOutlined, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let badge_urgent_icon = UDIcon.getIconByKey(.buzzFilled, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)

    static let sidebar_filtertab_message = UDIcon.getIconByKey(.chatOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_message_selected = UDIcon.getIconByKey(.chatOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.textLinkHover)
    static let sidebar_filtertab_p2pchat = UDIcon.getIconByKey(.singleChatOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_p2pchat_selected = UDIcon.getIconByKey(.singleChatOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.textLinkHover)
    static let sidebar_filtertab_mute = UDIcon.getIconByKey(.alertsOffOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_mute_selected = UDIcon.getIconByKey(.alertsOffOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.textLinkHover)
    static let sidebar_filtertab_done = UDIcon.getIconByKey(.chatDoneOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_done_selected = UDIcon.getIconByKey(.chatDoneOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.textLinkHover)
    static let sidebar_filtertab_at = UDIcon.getIconByKey(.atOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_at_selected = UDIcon.getIconByKey(.atOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.textLinkHover)
    static let sidebar_filtertab_chatSecret = UDIcon.getIconByKey(.chatSecretOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_chatSecret_selected = UDIcon.getIconByKey(.chatSecretOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.textLinkHover)
    static let sidebar_filtertab_group = UDIcon.getIconByKey(.groupOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_group_selected = UDIcon.getIconByKey(.groupOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.textLinkHover)
    static let sidebar_filtertab_chatTopic = UDIcon.getIconByKey(.chatTopicOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_chatTopic_selected = UDIcon.getIconByKey(.chatTopicOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.textLinkHover)
    static let sidebar_filtertab_robot = UDIcon.getIconByKey(.robotOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_robot_selected = UDIcon.getIconByKey(.robotOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.textLinkHover)
    static let sidebar_filtertab_later = UDIcon.getIconByKey(.laterOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_later_selected = UDIcon.getIconByKey(.laterOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.textLinkHover)
    static let sidebar_filtertab_unread = UDIcon.getIconByKey(.chatUnreadOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_unread_selected = UDIcon.getIconByKey(.chatUnreadOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.textLinkHover)
    static let sidebar_filtertab_doc = UDIcon.getIconByKey(.spaceOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_doc_selected = UDIcon.getIconByKey(.spaceOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.textLinkHover)
    static let sidebar_filtertab_helpdesk = UDIcon.getIconByKey(.helpdeskOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_helpdesk_selected = UDIcon.getIconByKey(.helpdeskOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.textLinkHover)
    static let sidebar_filtertab_expand = UDIcon.getIconByKey(.expandDownFilled, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_setting = UDIcon.getIconByKey(.listSettingOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_msgThread = UDIcon.getIconByKey(.threadChatOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_msgThread_selected = UDIcon.getIconByKey(.threadChatOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.textLinkHover)
    static let icon_setting_outlined_ipad = UDIcon.getIconByKey(.settingOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN1)
    static let filter_menu = UDIcon.getIconByKey(.slideBoldOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.iconN1)
    static let icon_side_fold = UDIcon.getIconByKey(.sideFoldOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.iconN1)
    static let icon_side_expand = UDIcon.getIconByKey(.sideExpandOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.iconN1)
    static let filter_close = UDIcon.getIconByKeyNoLimitSize(.closeBoldOutlined).ud.withTintColor(UDMessageColorTheme.imFeedIconPriSelected)

    static let sidebar_filtertab_unreadOverDays = UDIcon.getIconByKey(.chatHistoryOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_unreadOverDays_selected = UDIcon.getIconByKey(.chatHistoryOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.textLinkHover)
    static let sidebar_filtertab_cal = UDIcon.getIconByKey(.calendarOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_cal_selected = UDIcon.getIconByKey(.calendarOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.textLinkHover)

    static let sidebar_filtertab_meeting = UDIcon.getIconByKey(.videoOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_meeting_selected = UDIcon.getIconByKey(.videoOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.textLinkHover)

    static let send_message_failed = UDIcon.getIconByKey(.warningOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulRed)
    static public let sending_message = Resources.image(named: "sending_message")

    static let secret_chat_normal = UDIcon.getIconByKey(.chatSecretOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1) // note: 好像没有用上
    static let secret_chat_selected = UDIcon.getIconByKey(.chatSecretFilled, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulBlue) // note: 好像没有用上

    static let quickSwitcher_toTop = UDIcon.getIconByKey(.setTopOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let quickSwitcher_top = UDIcon.getIconByKey(.setTopCancelOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)

    static let shortcut_expand_more_icon = UDIcon.getIconByKey(.expandDownFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)

    // HeaderStatus
    static let status_group = UDIcon.getIconByKey(.switchOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3) // note: 好像没有用上
    static let status_alert_off = UDIcon.getIconByKey(.alertsOffOutlined, size: CGSize(width: 20, height: 20))
    static let status_onLine = UDIcon.getIconByKey(.computerOutlined, size: CGSize(width: 20, height: 20))
    static let status_net_error = UDIcon.getIconByKey(.errorColorful, size: CGSize(width: 16, height: 16))

    // Filter
    static let filter_setting = UDIcon.getIconByKey(.moreBoldOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3)

    // Context Menu
    static let feed_done_contextmenu = UDIcon.getContextMenuIconBy(key: .doneOutlined).ud.withTintColor(UIColor.ud.iconN1)
    static let feed_pin_contextmenu = UDIcon.getContextMenuIconBy(key: .setTopOutlined).ud.withTintColor(UIColor.ud.iconN1)
    static let feed_unpin_contextmenu = UDIcon.getContextMenuIconBy(key: .setTopCancelOutlined).ud.withTintColor(UIColor.ud.iconN1)
    static let flag_contextmenu = UDIcon.getContextMenuIconBy(key: .flagOutlined).ud.withTintColor(UIColor.ud.iconN1)
    static let unflag_contextmenu = UDIcon.getContextMenuIconBy(key: .flagUnavailableOutlined).ud.withTintColor(UIColor.ud.iconN1)
    static let label_contextmenu = UDIcon.getContextMenuIconBy(key: .labelCustomOutlined).ud.withTintColor(UIColor.ud.iconN1)
    static let team_contextmenu = UDIcon.getContextMenuIconBy(key: .communityTabOutlined).ud.withTintColor(UIColor.ud.iconN1)
    static let delete_label_feed_contextmenu = UDIcon.getContextMenuIconBy(key: .noOutlined).ud.withTintColor(UIColor.ud.iconN1)
    static let feed_create_scene_contextmenu = UDIcon.getContextMenuIconBy(key: .sepwindowOutlined).ud.withTintColor(UIColor.ud.iconN1)
    static let minimumMode_close = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN2)
    static let pinNotifyClock = UDIcon.getIconByKey(.bellOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
    static let pinNotifyClockClose = UDIcon.getIconByKey(.alertsOffOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
    static let clearUnreadBaged = UDIcon.getIconByKey(.clearUnreadOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
    static let chatForbidden = UDIcon.getIconByKey(.chatForbiddenOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
    static let chatUnforbidden = UDIcon.getIconByKey(.chatOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)

    public static let feed_at_all_border = LarkFeedBase.Resources.LarkFeedBase.atAllImage
    public static let feed_at_me_border = LarkFeedBase.Resources.LarkFeedBase.atMeImage
    static let feed_team_more = Resources.image(named: "feed_team_more")

    static let feed_right_arrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 13, height: 13)).ud.withTintColor(UIColor.ud.iconN3)
    static let feed_alerts_off = UDIcon.getIconByKey(.alertsOffOutlined, size: CGSize(width: 14, height: 14)).ud.withTintColor(UIColor.ud.iconN3)

    static let icon_visible_lock_outlined = UDIcon.getIconByKey(.visibleLockOutlined).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let icon_visible_outlined = UDIcon.getIconByKey(.visibleOutlined).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)

    static let labelCustomOutlined = UDIcon.labelChangeOutlined.ud.withTintColor(UIColor.ud.colorfulTurquoise)

    static let addMiddleOutlined = UDIcon.getIconByKey(.addOutlined).ud.withTintColor(UIColor.ud.iconN2)

    static let expandDownFilled = UDIcon.getIconByKey(.expandDownFilled).ud.withTintColor(UIColor.ud.N600)

    static let icon_addOutlined = UDIcon.getIconByKey(.addOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN2)
    static let icon_listCheckOutlined = UDIcon.getIconByKey(.doneOutlined).ud.withTintColor(UIColor.ud.illustrationBlueE)

    static let icon_setting_outlined = UDIcon.getIconByKey(.settingOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let icon_setting_outlined_disable = UDIcon.getIconByKey(.settingOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconDisabled)
    static let gray_num_badge_back = AppResources.gray_num_badge_back
    static let red_dot_badge_back = AppResources.red_dot_badge_back
    static let feed_tab_icon = UDIcon.getIconByKey(.tabChatFilled, iconColor: UIColor.ud.iconN3, size: CGSize(width: 22, height: 22))
    static let left_method_normal_icon = Resources.image(named: "left_method_normal_icon")
    static let left_method_select_icon = Resources.image(named: "left_method_select_icon")
}
