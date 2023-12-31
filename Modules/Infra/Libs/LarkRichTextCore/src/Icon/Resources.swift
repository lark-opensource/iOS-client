//
//  Resources.swift
//  Module
//
//  Created by chengzhipeng-bytedance on 2018/3/15.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

// swiftlint:disable all

import Foundation
import UIKit
#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif
import UniverseDesignIcon
import RustPB

public final class Resources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "LarkRichTextCore.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.LarkRichTextCoreBundle, compatibleWith: nil) ?? UIImage()
    }

    private static let defaultIconSize = CGSize(width: 48, height: 48)

    // wiki-doc
    public static let icon_Wiki_bitable_circle = UDIcon.getIconByKey(.fileRoundBitableColorful, size: defaultIconSize)
    // public static let icon_Wiki_circle = Resources.image(named: "icon_Wiki_circle")
    public static let icon_Wiki_unknow_circle = UDIcon.getIconByKey(.fileRoundUnknowColorful, size: defaultIconSize)
    public static let icon_Wiki_doc_circle = UDIcon.getIconByKey(.fileRoundDocColorful, size: defaultIconSize)
    public static let icon_Wiki_docx_circle = UDIcon.getIconByKey(.fileRoundDocxColorful, size: defaultIconSize)
    public static let icon_Wiki_mindnote_circle = UDIcon.getIconByKey(.fileRoundMindnoteColorful, size: defaultIconSize)
    public static let icon_Wiki_sheet_circle = UDIcon.getIconByKey(.fileRoundSheetColorful, size: defaultIconSize)
    public static let icon_Wiki_slide_circle = UDIcon.getIconByKey(.fileRoundSlideColorful, size: defaultIconSize)
    public static let icon_wiki_catalog_circle = Resources.image(named: "wiki_catalog_circle")

    public static let icon_Wiki_bitable_colorful = UDIcon.getIconByKey(.fileBitableColorful, size: defaultIconSize)
    // public static let icon_Wiki_circle = Resources.image(named: "icon_Wiki_circle")
    public static let icon_Wiki_unknow_colorful = UDIcon.getIconByKey(.fileUnknowColorful, size: defaultIconSize)
    public static let icon_Wiki_doc_colorful = UDIcon.getIconByKey(.fileDocColorful, size: defaultIconSize)
    public static let icon_Wiki_docx_colorful = UDIcon.getIconByKey(.fileDocxColorful, size: defaultIconSize)
    public static let icon_Wiki_mindnote_colorful = UDIcon.getIconByKey(.fileMindnoteColorful, size: defaultIconSize)
    public static let icon_Wiki_sheet_colorful = UDIcon.getIconByKey(.fileSheetColorful, size: defaultIconSize)
    public static let icon_Wiki_slide_colorful = UDIcon.getIconByKey(.fileSlideColorful, size: defaultIconSize)
    public static let icon_wiki_catalog_colorful = UDIcon.getIconByKey(.fileFolderColorful, size: defaultIconSize)
    // File
    public static func fileAeColorful(withSize size: CGSize) -> UIImage { UDIcon.getIconByKey(.fileAeColorful, size: size) }
    public static func fileAiColorful(withSize size: CGSize) -> UIImage { UDIcon.getIconByKey(.fileAiColorful, size: size) }
    public static func fileAndroidColorful(withSize size: CGSize) -> UIImage { UDIcon.getIconByKey(.fileAndroidColorful, size: size) }
    public static func fileAudioColorful(withSize size: CGSize) -> UIImage { UDIcon.getIconByKey(.fileAudioColorful, size: size) }
    public static func fileExcelColorful(withSize size: CGSize) -> UIImage { UDIcon.getIconByKey(.fileExcelColorful, size: size) }
    public static func fileImageColorful(withSize size: CGSize) -> UIImage { UDIcon.getIconByKey(.fileImageColorful, size: size) }
    public static func filePdfColorful(withSize size: CGSize) -> UIImage { UDIcon.getIconByKey(.filePdfColorful, size: size) }
    public static func filePptColorful(withSize size: CGSize) -> UIImage { UDIcon.getIconByKey(.filePptColorful, size: size) }
    public static func filePsColorful(withSize size: CGSize) -> UIImage { UDIcon.getIconByKey(.filePsColorful, size: size) }
    public static func fileSketchColorful(withSize size: CGSize) -> UIImage { UDIcon.getIconByKey(.fileSketchColorful, size: size) }
    public static func fileTextColorful(withSize size: CGSize) -> UIImage { UDIcon.getIconByKey(.fileTextColorful, size: size) }
    public static func fileVideoColorful(withSize size: CGSize) -> UIImage { UDIcon.getIconByKey(.fileVideoColorful, size: size) }
    public static func fileWordColorful(withSize size: CGSize) -> UIImage { UDIcon.getIconByKey(.fileWordColorful, size: size) }
    public static func fileZipColorful(withSize size: CGSize) -> UIImage { UDIcon.getIconByKey(.fileZipColorful, size: size) }
    public static func fileKeynoteColorful(withSize size: CGSize) -> UIImage { UDIcon.getIconByKey(.fileKeynoteColorful, size: size) }
    public static func fileEmlColorful(withSize size: CGSize) -> UIImage { UDIcon.getIconByKey(.fileEmlColorful, size: size) }
    public static func filePagesColorful(withSize size: CGSize) -> UIImage {UDIcon.getIconByKey(.filePagesColorful, size: size)}
    public static func fileNumbersColorful(withSize size: CGSize) -> UIImage {UDIcon.getIconByKey(.fileNumbersColorful, size: size)}
    public static func fileUnknowColorful(withSize size: CGSize) -> UIImage { UDIcon.getIconByKey(.fileUnknowColorful, size: size) }

    // wiki-drive
    // 以下 wiki drive icon 全部废弃，直接使用非 wiki 版本即可
    public static let icon_wiki_excel_circle = UDIcon.getIconByKey(.fileRoundExcelColorful, size: defaultIconSize)
    public static let icon_wiki_image_circle = UDIcon.getIconByKey(.fileRoundImageColorful, size: defaultIconSize)
    public static let icon_wiki_pdf_circle = UDIcon.getIconByKey(.fileRoundPdfColorful, size: defaultIconSize)
    public static let icon_wiki_ppt_circle = UDIcon.getIconByKey(.fileRoundPptColorful, size: defaultIconSize)
    public static let icon_wiki_txt_circle = UDIcon.getIconByKey(.fileRoundTextColorful, size: defaultIconSize)
    public static let icon_wiki_video_circle = UDIcon.getIconByKey(.fileRoundVideoColorful, size: defaultIconSize)
    public static let icon_wiki_word_circle = UDIcon.getIconByKey(.fileRoundWordColorful, size: defaultIconSize)
    public static let icon_wiki_zip_circle = UDIcon.getIconByKey(.fileRoundZipColorful, size: defaultIconSize)

    // space-drive
    public static let doc_ae_icon = UDIcon.getIconByKey(.fileRoundAeColorful, size: defaultIconSize)
    public static let doc_ai_icon = UDIcon.getIconByKey(.fileRoundAiColorful, size: defaultIconSize)
    public static let doc_android_icon = UDIcon.getIconByKey(.fileRoundAndroidColorful, size: defaultIconSize)
    public static let doc_bitable_icon = UDIcon.getIconByKey(.fileRoundBitableColorful, size: defaultIconSize)
    public static let doc_excel_icon = UDIcon.getIconByKey(.fileRoundExcelColorful, size: defaultIconSize)
    public static let doc_image_icon = UDIcon.getIconByKey(.fileRoundImageColorful, size: defaultIconSize)
    public static let doc_keynote_icon = UDIcon.getIconByKey(.fileRoundKeynoteColorful, size: defaultIconSize)
    public static let doc_pages_icon = UDIcon.getIconByKey(.fileRoundPagesColorful, size: defaultIconSize)
    public static let doc_numbers_icon = UDIcon.getIconByKey(.fileRoundNumbersColorful, size: defaultIconSize)
    public static let doc_music_icon = UDIcon.getIconByKey(.fileRoundAudioColorful, size: defaultIconSize)
    public static let doc_pdf_icon = UDIcon.getIconByKey(.fileRoundPdfColorful, size: defaultIconSize)
    public static let doc_ppt_icon = UDIcon.getIconByKey(.fileRoundPptColorful, size: defaultIconSize)
    public static let doc_ps_icon = UDIcon.getIconByKey(.fileRoundPsColorful, size: defaultIconSize)
    public static let doc_sketch_icon = UDIcon.getIconByKey(.fileRoundSketchColorful, size: defaultIconSize)
    public static let doc_txt_icon = UDIcon.getIconByKey(.fileRoundTextColorful, size: defaultIconSize)
    public static let doc_unknow_icon = UDIcon.getIconByKey(.fileRoundUnknowColorful, size: defaultIconSize)
    public static let doc_video_icon = UDIcon.getIconByKey(.fileRoundVideoColorful, size: defaultIconSize)
    public static let doc_word_icon = UDIcon.getIconByKey(.fileRoundWordColorful, size: defaultIconSize)
    public static let doc_zip_icon = UDIcon.getIconByKey(.fileRoundZipColorful, size: defaultIconSize)
    // space-doc
    public static let doc_sheet_icon = UDIcon.getIconByKey(.fileRoundSheetColorful, size: defaultIconSize)
    public static let doc_doc_icon = UDIcon.getIconByKey(.fileRoundDocColorful, size: defaultIconSize)
    public static let doc_mindnote_icon = UDIcon.getIconByKey(.fileRoundMindnoteColorful, size: defaultIconSize)
    public static let doc_slide_icon = UDIcon.getIconByKey(.fileRoundSlideColorful, size: defaultIconSize)
    public static let doc_slides_icon = UDIcon.getIconByKey(.wikiSlidesCircleColorful, size: defaultIconSize)
    public static let doc_docx_icon = UDIcon.getIconByKey(.fileRoundDocxColorful, size: defaultIconSize)
    // 大搜要求用一个特殊的圆形 folder icon，不使用 UD 内的方形 icon
    public static let doc_folder_icon = Resources.image(named: "doc_folder_circle")

    public static let at_bottombar = UDIcon.atOutlined.ud.withTintColor(UIColor.ud.iconN3)
    public static let at_bottombar_selected = UDIcon.atOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)

    public static let arrow_goback_fontbar = Resources.image(named: "arrow_goback_fontbar")
    public static let bold_fontbar = Resources.image(named: "bold_fontbar").ud.withTintColor(UIColor.ud.iconN2)
    public static let italic_fontbar = Resources.image(named: "italic_fontbar").ud.withTintColor(UIColor.ud.iconN2)
    public static let strikethrough_fontbar = Resources.image(named: "strikethrough_fontbar").ud.withTintColor(UIColor.ud.iconN2)
    public static let underline_fontbar = Resources.image(named: "underline_fontbar").ud.withTintColor(UIColor.ud.iconN2)

    public static let bold_fontbar_selected = Resources.image(named: "bold_fontbar").ud.withTintColor(UIColor.ud.colorfulBlue)
    public static let italic_fontbar_selected = Resources.image(named: "italic_fontbar").ud.withTintColor(UIColor.ud.colorfulBlue)
    public static let strikethrough_fontbar_selected = Resources.image(named: "strikethrough_fontbar").ud.withTintColor(UIColor.ud.colorfulBlue)
    public static let underline_fontbar_selected = Resources.image(named: "underline_fontbar").ud.withTintColor(UIColor.ud.colorfulBlue)

    public static let hashTag_bottombar = UDIcon.hashtagOutlined

    public static let todo_bottombar = UDIcon.tabTodoOutlined.ud.withTintColor(UIColor.ud.iconN2)
    public static let todo_bottombar_selected = UDIcon.tabTodoOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)

    public static let canvas_bottomBar_icon = UDIcon.pencilkitOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)

    public static let canvas_bottomBar_selected_icon = UDIcon.pencilkitOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)

    public static let sent_light = UDIcon.sendColorful.ud.withTintColor(UIColor.ud.colorfulBlue)

    public static let others_plus = UDIcon.moreAddOutlined.ud.withTintColor(UIColor.ud.iconN3)
    public static let others_close = UDIcon.moreCloseOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)

    public static let emotion_setting = UDIcon.settingOutlined.ud.withTintColor(UIColor.ud.iconN2)

    public static let loading = Resources.image(named: "loading")

    public static let expand_selected = UDIcon.expandOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    public static let expand = UDIcon.expandOutlined.ud.withTintColor(UIColor.ud.iconN3)

    // chat
    public static let goChatSettingArrow = UDIcon.getIconByKey(.expandRightFilled, size: CGSize(width: 10, height: 10)).ud.withTintColor(UIColor.ud.iconN1)

    //docUrlIcon
    static let docUrlIcon_doc_icon = UDIcon.getIconByKey(.fileLinkWordOutlined).ud.withTintColor(UIColor.ud.textLinkNormal)
    static let docUrlIcon_sheet_icon = UDIcon.getIconByKey(.fileLinkSheetOutlined).ud.withTintColor(UIColor.ud.textLinkNormal)
    static let docUrlIcon_bitable_icon = UDIcon.getIconByKey(.fileLinkBitableOutlined).ud.withTintColor(UIColor.ud.textLinkNormal)
    static let docUrlIcon_mindnote_icon = UDIcon.getIconByKey(.fileLinkMindnoteOutlined).ud.withTintColor(UIColor.ud.textLinkNormal)
    static let docUrlIcon_slide_icon = UDIcon.getIconByKey(.fileLinkSlideOutlined).ud.withTintColor(UIColor.ud.textLinkNormal)
    static let docUrlIcon_slides_icon = UDIcon.getIconByKey(.fileLinkSlidesOutlined).ud.withTintColor(UIColor.ud.textLinkNormal)
    static let docUrlIcon_file_icon = UDIcon.getIconByKey(.fileLinkOtherfileOutlined).ud.withTintColor(UIColor.ud.textLinkNormal)
    static let docUrlIcon_docx_icon = UDIcon.fileLinkDocxOutlined.ud.withTintColor(UIColor.ud.textLinkNormal)
    static let docUrlIcon_folder_icon = UDIcon.getIconByKey(.folderOutlined).ud.withTintColor(UIColor.ud.textLinkNormal)

    static let failed = Resources.image(named: "failed")

    // Keyboard
    public static let emoji_bottombar_selected = UDIcon.emojiOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    public static let emoji_bottombar = UDIcon.emojiOutlined.ud.withTintColor(UIColor.ud.iconN3)
    public static let customTitle = "customTitle"
}

// swiftlint:enable all
