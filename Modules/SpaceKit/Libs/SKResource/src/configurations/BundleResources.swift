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
public final class BundleResources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "SKResource.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.SKResourceBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    public final class SKResource {
        public final class Bitable {
            public static let bitable_form_bg = BundleResources.image(named: "bitable_form_bg")
            public static let icon_bitable_checkbox_off = BundleResources.image(named: "icon_bitable_checkbox_off")
            public static let icon_bitable_checkbox_on = BundleResources.image(named: "icon_bitable_checkbox_on")
            public static let icon_bitable_selected = BundleResources.image(named: "icon_bitable_selected")
            public static let icon_bitable_unselected = BundleResources.image(named: "icon_bitable_unselected")
            public static let catalogue_divider = BundleResources.image(named: "catalogue_divider")
            public static let slider_thumb = BundleResources.image(named: "slider_thumb")
            public static let icon_add_colorful_blue = BundleResources.image(named: "icon_add_colorful_blue")
            public static let icon_add_colorful_gray = BundleResources.image(named: "icon_add_colorful_gray")
            public static let qr_left = BundleResources.image(named: "qr_left")
            public static let qr_right = BundleResources.image(named: "qr_right")
            public static let tooltip_caret = BundleResources.image(named: "tooltip_caret")
            public static let base_tooltip_caret_down = BundleResources.image(named: "base_tooltip_caret_down")
            public static let multilist_empty_bg = BundleResources.image(named: "multilist_empty_bg")
            public static let multilist_error_bg = BundleResources.image(named: "multilist_error_bg")
            public static let multilist_decoration_line = BundleResources.image(named: "multilist_decoration_line")
            public static let multilist_decoration_smile = BundleResources.image(named: "multilist_decoration_smile")
            public static let base_homepage_dashboard_empty = BundleResources.image(named: "homepage_dashboard_empty")
            public static let base_homepage_dashboard_chart_loading = BundleResources.image(named: "homepage_dashboard_chart_lodading")
            public static let base_homepage_dashboard_error = BundleResources.image(named: "homepage_dashboard_error")
            public static let homepage_dashboard_no_data = BundleResources.image(named: "homepage_dashboard_no_data")
        }
        public final class Common {
            public final class Close {
                public static let confirmClose = BundleResources.image(named: "confirmClose")
            }
            public final class Collaborator {
                public static let Selected = BundleResources.image(named: "Selected")
                public static let Unselected = BundleResources.image(named: "Unselected")
                public static let avatar_meeting = BundleResources.image(named: "avatar_meeting")
                public static let avatar_placeholder = BundleResources.image(named: "avatar_placeholder")
                public static let avatar_wiki_user = BundleResources.image(named: "avatar_wiki_user")
                public static let collaborator_icon_selected_disable = BundleResources.image(named: "collaborator_icon_selected_disable")
                public static let collaborators_form_remove = BundleResources.image(named: "collaborators_form_remove")
                public static let collaborators_remove = BundleResources.image(named: "collaborators_remove")
                public static let icon_close_outlinedV2 = BundleResources.image(named: "icon_close_outlinedV2")
                public static let icon_collaborator_organization_32 = BundleResources.image(named: "icon_collaborator_organization_32")
                public static let icon_organization_outlined = BundleResources.image(named: "icon_organization_outlined")
                public static let icon_tool_arrow_nor = BundleResources.image(named: "icon_tool_arrow_nor")
                public static let icon_tool_guide_nor = BundleResources.image(named: "icon_tool_guide_nor")
                public static let icon_usergroup = BundleResources.image(named: "icon_usergroup")
                public static let permission_icon_lock = BundleResources.image(named: "permission_icon_lock")
                public static let permission_optionArrow = BundleResources.image(named: "permission_optionArrow")
                public static let avatar_person = BundleResources.image(named: "avatar_person")
            }
            public final class Comment {
                public static let commentClose = BundleResources.image(named: "commentClose")
                public static let comment_delete = BundleResources.image(named: "comment_delete")
                public static let comment_reply_cn = BundleResources.image(named: "comment_reply_cn")
                public static let comment_reply_notCn = BundleResources.image(named: "comment_reply_notCn")
                public static let icon_comment_delete_img = BundleResources.image(named: "icon_comment_delete_img")
                public static let icon_comment_fail_img = BundleResources.image(named: "icon_comment_fail_img")
            }
            public final class Cover {
                public static let icon_image_outlined = BundleResources.image(named: "icon_image_outlined")
                public static let icon_move_selected_outlined = BundleResources.image(named: "icon_move-selected_outlined")
            }
            public final class Global {
                public static let icon_approval_outlined_nor = BundleResources.image(named: "icon_approval_outlined_nor")
                public static let icon_expand_right_nor = BundleResources.image(named: "icon_expand_right_nor")
                public static let icon_global_arrowdown_nor = BundleResources.image(named: "icon_global_arrowdown_nor")
                public static let icon_global_back_nor = BundleResources.image(named: "icon_global_back_nor")
                public static let icon_global_close_nor = BundleResources.image(named: "icon_global_close_nor")
                public static let icon_global_delete_nor = BundleResources.image(named: "icon_global_delete_nor")
                public static let icon_global_history_nor = BundleResources.image(named: "icon_global_history_nor")
                public static let icon_global_image_nor = BundleResources.image(named: "icon_global_image_nor")
                public static let icon_global_ipad_close_nor = BundleResources.image(named: "icon_global_ipad_close_nor")
                public static let icon_global_link_nor = BundleResources.image(named: "icon_global_link_nor")
                public static let icon_global_pause_nor = BundleResources.image(named: "icon_global_pause_nor")
                public static let icon_global_search_nor = BundleResources.image(named: "icon_global_search_nor")
                public static let icon_global_send_nor = BundleResources.image(named: "icon_global_send_nor")
                public static let icon_global_sheetapp_nor = BundleResources.image(named: "icon_global_sheetapp_nor")
                public static let icon_global_voice_nor = BundleResources.image(named: "icon_global_voice_nor")
            }
            public final class IG {
                public static let icon_toutiao_circle = BundleResources.image(named: "icon_toutiao_circle")
            }
            public final class Icon {
                public static let icon_actionsheet_favorites_on_20 = BundleResources.image(named: "icon_actionsheet_favorites_on_20")
                public static let icon_announce_outlined = BundleResources.image(named: "icon_announce_outlined")
                public static let icon_calendar_tittle_outlined = BundleResources.image(named: "icon_calendar_tittle_outlined")
                public static let icon_create_outlined = BundleResources.image(named: "icon_create_outlined")
                public static let icon_delete_trash_outlined_20 = BundleResources.image(named: "icon_delete_trash_outlined_20")
                public static let icon_doc_addicon_placeholder = BundleResources.image(named: "icon_doc_addicon_placeholder")
                public static let icon_doc_removeicon_nor = BundleResources.image(named: "icon_doc_removeicon_nor")
                public static let icon_done_outlined = BundleResources.image(named: "icon_done_outlined")
                public static let icon_down_outlined = BundleResources.image(named: "icon_down_outlined")
                public static let icon_more_outlined_20 = BundleResources.image(named: "icon_more_outlined_20")
                public static let icon_organization_wiki = BundleResources.image(named: "icon_organization_wiki")
                public static let icon_pop_quickaccessoff_nor_20 = BundleResources.image(named: "icon_pop_quickaccessoff_nor_20")
                public static let icon_replace_outlined = BundleResources.image(named: "icon_replace_outlined")
                public static let icon_right_outlined = BundleResources.image(named: "icon_right_outlined")
                public static let icon_sepwindow_outlined = BundleResources.image(named: "icon_sepwindow_outlined")
                public static let icon_sepwindow_outlined_20 = BundleResources.image(named: "icon_sepwindow_outlined_20")
                public static let icon_setting_inter_outlined = BundleResources.image(named: "icon_setting_inter_outlined")
                public static let icon_share_outlined_20 = BundleResources.image(named: "icon_share_outlined_20")
                public static let icon_slide_favorites_off_20 = BundleResources.image(named: "icon_slide_favorites_off_20")
                public static let icon_usergroup_wiki = BundleResources.image(named: "icon_usergroup_wiki")
            }
            public final class More {
                public static let icon_add_comment_outlined = BundleResources.image(named: "icon_add_comment_outlined")
                public static let icon_more_fullwidth_nor = BundleResources.image(named: "icon_more_fullwidth_nor")
            }
            public final class Onboarding {
                public static let triangle_up = BundleResources.image(named: "triangle_up")
            }
            public final class Other {
                public static let group_default = BundleResources.image(named: "group_default")
                public static let star = BundleResources.image(named: "star")
                public static let unsupport_file_apk = BundleResources.image(named: "unsupport_file_apk")
                public static let unsupport_file_unknown = BundleResources.image(named: "unsupport_file_unknown")
                public static let unsupport_file_zip = BundleResources.image(named: "unsupport_file_zip")
            }
            public final class Pop {
                public static let icon_pop_download_small_nor = BundleResources.image(named: "icon_pop_download_small_nor")
                public static let icon_pop_qq_small_nor = BundleResources.image(named: "icon_pop_qq_small_nor")
                public static let icon_pop_wechat_small_nor = BundleResources.image(named: "icon_pop_wechat_small_nor")
                public static let icon_pop_weibo_small_nor = BundleResources.image(named: "icon_pop_weibo_small_nor")
                public static let pop_feishu_im = BundleResources.image(named: "pop_feishu_im")
                public static let pop_feishudocs = BundleResources.image(named: "pop_feishudocs")
                public static let pop_moments_small = BundleResources.image(named: "pop_moments_small")
            }
            public final class ReactionPanel {
                public static let ReactionPanelEDIT = BundleResources.image(named: "ReactionPanelEDIT")
                public static let ReactionPanelRESOLVE = BundleResources.image(named: "ReactionPanelRESOLVE")
                public static let ReactionPanelTRANSLATE = BundleResources.image(named: "ReactionPanelTRANSLATE")
                public static let ReactionPanel_showmore = BundleResources.image(named: "ReactionPanel_showmore")
            }
            public final class Share {
                public static let icon_file_doc_illustration = BundleResources.image(named: "icon_file_doc_illustration")
                public static let icon_file_excel_illustration = BundleResources.image(named: "icon_file_excel_illustration")
                public static let icon_file_image_illustration = BundleResources.image(named: "icon_file_image_illustration")
                public static let icon_file_mindnote_illustration = BundleResources.image(named: "icon_file_mindnote_illustration")
                public static let icon_file_pdf_illustration = BundleResources.image(named: "icon_file_pdf_illustration")
                public static let icon_file_ppt_illustration = BundleResources.image(named: "icon_file_ppt_illustration")
                public static let icon_file_sheet_illustration = BundleResources.image(named: "icon_file_sheet_illustration")
                public static let icon_file_text_illustration = BundleResources.image(named: "icon_file_text_illustration")
                public static let icon_file_unknow_illustration = BundleResources.image(named: "icon_file_unknow_illustration")
                public static let icon_file_video_illustration = BundleResources.image(named: "icon_file_video_illustration")
                public static let icon_file_word_illustration = BundleResources.image(named: "icon_file_word_illustration")
                public static let icon_file_zip_illustration = BundleResources.image(named: "icon_file_zip_illustration")
            }
            public final class SideSeek {
                public static let icon_catalog_shadow = BundleResources.image(named: "icon_catalog_shadow")
            }
            public final class Thumbnail {
                public static let thumbnail_file_image = BundleResources.image(named: "thumbnail_file_image")
            }
            public final class Tips {
                public static let common_net_alert_warn = BundleResources.image(named: "common_net_alert_warn")
                public static let icon_tips_close = BundleResources.image(named: "icon_tips_close")
                public static let icon_tips_loading_nor = BundleResources.image(named: "icon_tips_loading_nor")
                public static let icon_tips_refresh_nor = BundleResources.image(named: "icon_tips_refresh_nor")
            }
            public final class Tool {
                public static let icon_expand_down_filled = BundleResources.image(named: "icon_expand_down_filled")
                public static let icon_expand_left_filled = BundleResources.image(named: "icon_expand_left_filled")
                public static let icon_link_record_outlined = BundleResources.image(named: "icon_link_record_outlined")
                public static let icon_tool_behind_nor = BundleResources.image(named: "icon_tool_behind_nor")
                public static let icon_tool_copy_nor = BundleResources.image(named: "icon_tool_copy_nor")
                public static let icon_tool_deletehistory_nor = BundleResources.image(named: "icon_tool_deletehistory_nor")
                public static let icon_tool_edit_nor = BundleResources.image(named: "icon_tool_edit_nor")
                public static let icon_tool_finish = BundleResources.image(named: "icon_tool_finish")
                public static let icon_tool_highlight_nor = BundleResources.image(named: "icon_tool_highlight_nor")
                public static let icon_tool_minus_nor = BundleResources.image(named: "icon_tool_minus_nor")
                public static let icon_tool_offlinefail = BundleResources.image(named: "icon_tool_offlinefail")
                public static let icon_tool_offlinesuccess = BundleResources.image(named: "icon_tool_offlinesuccess")
                public static let icon_tool_okr = BundleResources.image(named: "icon_tool_okr")
                public static let icon_tool_plus_nor = BundleResources.image(named: "icon_tool_plus_nor")
                public static let icon_tool_radiocheckbox_nor = BundleResources.image(named: "icon_tool_radiocheckbox_nor")
                public static let icon_tool_radiocheckbox_select_disable = BundleResources.image(named: "icon_tool_radiocheckbox_select_disable")
                public static let icon_tool_radiocheckbox_slt = BundleResources.image(named: "icon_tool_radiocheckbox_slt")
                public static let icon_tool_radiocheckbox_unselect_disable = BundleResources.image(named: "icon_tool_radiocheckbox_unselect_disable")
                public static let icon_tool_sharefolder = BundleResources.image(named: "icon_tool_sharefolder")
                public static let icon_tool_synching = BundleResources.image(named: "icon_tool_synching")
                public static let icon_tool_waitdownload = BundleResources.image(named: "icon_tool_waitdownload")
                public static let icon_tool_waituploading = BundleResources.image(named: "icon_tool_waituploading")
                public static let icon_wiki_scope_tag_nor = BundleResources.image(named: "icon_wiki_scope_tag_nor")
            }
            public final class Reminder {
                public static let reminder_close = BundleResources.image(named: "reminder_close")
                public static let reminder_next = BundleResources.image(named: "reminder_next")
                public static let reminder_previous = BundleResources.image(named: "reminder_previous")
            }
            public final class Search {
                public static let search_delete = BundleResources.image(named: "search_delete")
                public static let search_ico = BundleResources.image(named: "search_ico")
                public static let search_pulldown = BundleResources.image(named: "search_pulldown")
            }
        }
        public final class Doc {
            public static let docs_fileinfo_date = BundleResources.image(named: "docs_fileinfo_date")
            public static let docs_trianglesmall_blue = BundleResources.image(named: "docs_trianglesmall_blue")
        }
        public final class DocsApp {
            public static let checkMark = BundleResources.image(named: "checkMark")
            public static let refreshMask_bottom = BundleResources.image(named: "refreshMask_bottom")
            public static let refreshMask_top = BundleResources.image(named: "refreshMask_top")
            public static let my_ai_chatmode_entry = BundleResources.image(named: "my_ai_chatmode_entry")
        }
        public final class Drive {
            public static let drive_black_slide_bar = BundleResources.image(named: "drive_black_slide_bar")
            public static let drive_default_headPortrait = BundleResources.image(named: "drive_default_headPortrait")
            public static let drive_pdf_preview = BundleResources.image(named: "drive_pdf_preview")
            public static let drive_slide_bar = BundleResources.image(named: "drive_slide_bar")
            public static let icon_drive_areacomment_nor = BundleResources.image(named: "icon_drive_areacomment_nor")
        }
        public final class Mindnote {
            public static let mindnote_structure_icon_bilateralview = BundleResources.image(named: "mindnote_structure_icon_bilateralview")
            public static let mindnote_structure_icon_bilateralview_selected = BundleResources.image(named: "mindnote_structure_icon_bilateralview_selected")
            public static let mindnote_structure_icon_downview = BundleResources.image(named: "mindnote_structure_icon_downview")
            public static let mindnote_structure_icon_downview_selected = BundleResources.image(named: "mindnote_structure_icon_downview_selected")
            public static let mindnote_structure_icon_leftview = BundleResources.image(named: "mindnote_structure_icon_leftview")
            public static let mindnote_structure_icon_leftview_selected = BundleResources.image(named: "mindnote_structure_icon_leftview_selected")
            public static let mindnote_structure_icon_rightview = BundleResources.image(named: "mindnote_structure_icon_rightview")
            public static let mindnote_structure_icon_rightview_selected = BundleResources.image(named: "mindnote_structure_icon_rightview_selected")
        }
        public final class Sheet {
            public final class Keyboard {
                public static let sheet_kb_eight = BundleResources.image(named: "sheet_kb_eight")
                public static let sheet_kb_five = BundleResources.image(named: "sheet_kb_five")
                public static let sheet_kb_four = BundleResources.image(named: "sheet_kb_four")
                public static let sheet_kb_nine = BundleResources.image(named: "sheet_kb_nine")
                public static let sheet_kb_one = BundleResources.image(named: "sheet_kb_one")
                public static let sheet_kb_point = BundleResources.image(named: "sheet_kb_point")
                public static let sheet_kb_seven = BundleResources.image(named: "sheet_kb_seven")
                public static let sheet_kb_six = BundleResources.image(named: "sheet_kb_six")
                public static let sheet_kb_three = BundleResources.image(named: "sheet_kb_three")
                public static let sheet_kb_two = BundleResources.image(named: "sheet_kb_two")
                public static let sheet_kb_zero = BundleResources.image(named: "sheet_kb_zero")
                public static let sheet_kb_zerozero = BundleResources.image(named: "sheet_kb_zerozero")
            }
            public final class PickColor {
                public static let icon_check_color = BundleResources.image(named: "icon_check_color")
            }
        }
        public final class Space {
            public final class Create {
                public static let template_shadow_MindNote = BundleResources.image(named: "template_shadow_MindNote")
                public static let template_shadow_Sheet = BundleResources.image(named: "template_shadow_Sheet")
                public static let template_shadow_bitable = BundleResources.image(named: "template_shadow_bitable")
                public static let template_shadow_doc = BundleResources.image(named: "template_shadow_doc")
            }
            public final class DocsType {
                public static let icon_sharedspace = BundleResources.image(named: "icon_sharedspace")
                public static let icon_shortcut_left_bottom_tip = BundleResources.image(named: "icon_shortcut_left_bottom_tip")
            }
            public final class FileList {
                public static let empty_no_link = BundleResources.image(named: "empty_no_link")
                public static let icon_permisson_isv_tip = BundleResources.image(named: "icon_permisson_isv_tip")
                public static let listcell_delete = BundleResources.image(named: "listcell_delete")
                public static let listcell_restore = BundleResources.image(named: "listcell_restore")
                public final class Grid {
                    public static let grid_cell_fail = BundleResources.image(named: "grid_cell_fail")
                }
            }
            public final class Home {
                public static let new_home_ipad_cloud_driver_onboarding = BundleResources.image(named: "new_home_ipad_cloud_driver_onboarding")
                public static let new_home_personal_empty = BundleResources.image(named: "new_home_personal_empty")
            }
        }
    }

}
//swiftlint:enable all
