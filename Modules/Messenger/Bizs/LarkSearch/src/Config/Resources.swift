//
//  Resources.swift
//  Module
//
//  Created by chengzhipeng-bytedance on 2018/3/15.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignIcon

final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: LarkSearchBundle, compatibleWith: nil) ?? UIImage()
    }

    static var contacts_search: UIImage { return Resources.image(named: "contacts_search") }
    static var doc_sharefolder_circle: UIImage { return UDIcon.getIconByKey(.fileRoundSharefolderColorful) }
    static let selected_view_right_arrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
    static var message_search: UIImage { return Resources.image(named: "message_search") }
    static var group_search: UIImage { return Resources.image(named: "group_search") }
    static var icon_file_folder_colorful: UIImage { return UDIcon.getIconByKey(.fileFolderColorful, size: CGSize(width: 40, height: 40)) }
    static var authorityTag: UIImage { return UDIcon.getIconByKey(.safeFilled, size: CGSize(width: 12, height: 12)) }

    static var goDoc: UIImage { return UDIcon.getIconByKey(.viewinchatOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1) }
    static var imageDownloading: UIImage { return Resources.image(named: "imageDownloading") }
    static var imageDownloadFail: UIImage { return Resources.image(named: "imageDownloadFail") }
    static var listFilterOutlined: UIImage { return UDIcon.getIconByKey(.listFilterOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.textCaption) }
    static var gifTag: UIImage { return Resources.image(named: "gifTag") }
    static var box_avatar: UIImage { return Resources.image(named: "box_avatar") }

    static var icon_down_outlined: UIImage { return UDIcon.getIconByKey(.downOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN2) }
    static var personal_card: UIImage { return UDIcon.getIconByKey(.groupCardOutlined) }
    static var see_more: UIImage { return UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3) }
    static var search_contact: UIImage { return UDIcon.getIconByKey(.memberOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3) }
    static var search_group: UIImage { return Resources.image(named: "search_group") }
    static var search_message: UIImage { return Resources.image(named: "search_message") }
    static var search_topic: UIImage { return UDIcon.getIconByKey(.chatTopicOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3) }
    static var search_thread: UIImage { return Resources.image(named: "search_thread") }
    static var search_docs: UIImage { return UDIcon.getIconByKey(.docOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3) }
    static var search_wiki: UIImage { return UDIcon.getIconByKey(.wikiOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3) }
    static var search_box: UIImage { return UDIcon.getIconByKey(.chatboxOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3) }
    static var search_oncall: UIImage { return UDIcon.getIconByKey(.helpdeskOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3) }
    static var search_app: UIImage { return UDIcon.getIconByKey(.appOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3) }
    static var search_external: UIImage { return UDIcon.getIconByKey(.externalOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3) }
    static var search_calendar: UIImage { return UDIcon.getIconByKey(.calendarOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3) }
    static var tab_more: UIImage { return UDIcon.getIconByKey(.moreOutlined).ud.withTintColor(UIColor.ud.iconN3) }
    static var icon_search_20: UIImage { return UDIcon.getIconByKey(.searchOutlineOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3) }

    static var search_clear_history: UIImage { return UDIcon.getIconByKey(.deleteTrashOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3) }
    static var icon_right_outlined: UIImage { return UDIcon.getIconByKey(.rightOutlined) }
    static var url_link: UIImage { return Resources.image(named: "url_link") }

    static var search_icon_event_lark: UIImage { return Resources.image(named: "search_icon_event_lark") }
    static var search_icon_event_google: UIImage { return Resources.image(named: "search_icon_event_google") }

    static var app_history: UIImage { return UDIcon.appOutlined.ud.withTintColor(UIColor.ud.iconN2) }
    static var calendar_history: UIImage { return UDIcon.calendarLineOutlined.ud.withTintColor(UIColor.ud.iconN2) }
    static var help_history: UIImage { return UDIcon.helpdeskOutlined.ud.withTintColor(UIColor.ud.iconN2) }
    static var message_history: UIImage { return UDIcon.chatOutlined.ud.withTintColor(UIColor.ud.iconN2) }
    static var chat_history: UIImage { return Resources.image(named: "chat_history") }
    static var more_history: UIImage { return UDIcon.externalOutlined.ud.withTintColor(UIColor.ud.iconN2) }
    static var space_history: UIImage { return UDIcon.spaceOutlined.ud.withTintColor(UIColor.ud.iconN3) }
    static var wiki_history: UIImage { return UDIcon.wikiOutlined.ud.withTintColor(UIColor.ud.iconN2) }
    static var external_default: UIImage { return Resources.image(named: "external_default") }
    static var chat_filter_close: UIImage { return UDIcon.getIconByKey(.closeSmallOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN3) }
    static var thread_type_close: UIImage { return UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1) }
    static var thread_type_selected: UIImage { return Resources.image(named: "thread_type_selected") }
    static var thread_type_noSelected: UIImage { return Resources.image(named: "thread_type_noSelected") }
    static var topic_history: UIImage { return UDIcon.chatTopicOutlined.ud.withTintColor(UIColor.ud.iconN2) }
    static var thread_history: UIImage { return Resources.image(named: "thread_history") }
    static var lan_Trans_Icon: UIImage { return Resources.image(named: "lan_Trans_Icon") }

    static let time_zone = UDIcon.getIconByKey(.timeFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconDisabled)
    static var more_Tab_menu_icon: UIImage { return UDIcon.getIconByKey(.menuOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2) }
}
