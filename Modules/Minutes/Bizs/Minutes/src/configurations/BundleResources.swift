// Warning: Do Not Edit It!
// Created by EEScaffold, if you want to edit it please check the manual of EEScaffold
// Toolchains For EE, be fast
/*
*
*
*  ______ ______ _____        __
* |  ____|  ____|_   _|      / _|
* | |__  | |__    | |  _ __ | |_ _ __ __ _
* |  __| |  __|   | | | '_ \|  _| '__/ _` |
* | |____| |____ _| |_| | | | | | | | (_| |
* |______|______|_____|_| |_|_| |_|  \__,_|
*
*
*/

import Foundation
import UIKit

#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif

//swiftlint:disable all
final class BundleResources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "Minutes.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.MinutesBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    class Minutes {
        static let illustration_empty_neutral_no_contentempty = BundleResources.image(named: "illustration_empty_neutral_no_contentempty")
        static let minutes_audio = BundleResources.image(named: "minutes_audio")
        static let minutes_audio_colorful_dark = BundleResources.image(named: "minutes_audio_colorful_dark")
        static let minutes_audio_colorful_light = BundleResources.image(named: "minutes_audio_colorful_light")
        static let minutes_audio_floating_pause = BundleResources.image(named: "minutes_audio_floating_pause")
        static let minutes_audio_floating_pause_button = BundleResources.image(named: "minutes_audio_floating_pause_button")
        static let minutes_audio_floating_play_button = BundleResources.image(named: "minutes_audio_floating_play_button")
        static let minutes_comment_tip = BundleResources.image(named: "minutes_comment_tip")
        static let minutes_dark_adjust = BundleResources.image(named: "minutes_dark_adjust")
        static let minutes_feed_list_item_audio_width = BundleResources.image(named: "minutes_feed_list_item_audio_width")
        static let minutes_feed_list_item_text_width = BundleResources.image(named: "minutes_feed_list_item_text_width")
        static let minutes_feed_list_item_video_width = BundleResources.image(named: "minutes_feed_list_item_video_width")
        static let minutes_home_audio_record = BundleResources.image(named: "minutes_home_audio_record")
        static let minutes_home_cell_mask = BundleResources.image(named: "minutes_home_cell_mask")
        static let minutes_home_invalid = BundleResources.image(named: "minutes_home_invalid")
        static let minutes_home_myspace = BundleResources.image(named: "minutes_home_myspace")
        static let minutes_home_remove_selected = BundleResources.image(named: "minutes_home_remove_selected")
        static let minutes_home_remove_unselected = BundleResources.image(named: "minutes_home_remove_unselected")
        static let minutes_home_share = BundleResources.image(named: "minutes_home_share")
        static let minutes_info_collection_bg = BundleResources.image(named: "minutes_info_collection_bg")
        static let minutes_ipad_switcher = BundleResources.image(named: "minutes_ipad_switcher")
        static let minutes_loading_cycle = BundleResources.image(named: "minutes_loading_cycle")
        static let minutes_more_close = BundleResources.image(named: "minutes_more_close")
        static let minutes_more_details_clock = BundleResources.image(named: "minutes_more_details_clock")
        static let minutes_podcast_exit = BundleResources.image(named: "minutes_podcast_exit")
        static let minutes_podcast_floating_loading = BundleResources.image(named: "minutes_podcast_floating_loading")
        static let minutes_podcast_hou15s = BundleResources.image(named: "minutes_podcast_hou15s")
        static let minutes_podcast_icon = BundleResources.image(named: "minutes_podcast_icon")
        static let minutes_podcast_icon_dark = BundleResources.image(named: "minutes_podcast_icon_dark")
        static let minutes_podcast_loading_cycle = BundleResources.image(named: "minutes_podcast_loading_cycle")
        static let minutes_podcast_pause = BundleResources.image(named: "minutes_podcast_pause")
        static let minutes_podcast_play = BundleResources.image(named: "minutes_podcast_play")
        static let minutes_podcast_qian15s = BundleResources.image(named: "minutes_podcast_qian15s")
        static let minutes_refresh_outlined = BundleResources.image(named: "minutes_refresh_outlined")
        static let minutes_speak_language = BundleResources.image(named: "minutes_speak_language")
        static let minutes_speaker_canedit = BundleResources.image(named: "minutes_speaker_canedit")
        static let minutes_subtitle_audio = BundleResources.image(named: "minutes_subtitle_audio")
        static let minutes_summary_selected = BundleResources.image(named: "minutes_summary_selected")
        static let minutes_summary_unselected = BundleResources.image(named: "minutes_summary_unselected")
        static let minutes_telephone = BundleResources.image(named: "minutes_telephone")
        static let minutes_text = BundleResources.image(named: "minutes_text")
    }

}
//swiftlint:enable all
