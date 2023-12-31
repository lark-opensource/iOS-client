// Warning: Do Not Edit It!
// Created by EEScaffold, if you want to edit it please check the manual of EEScaffold
// Toolchains For EE
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

#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif
import UIKit
import UniverseDesignIcon
import UniverseDesignColor
import RustPB
import LarkModel
import Foundation
import LarkRichTextCore

public final class Resources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "LarkBaseKeyboard.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.LarkBaseKeyboardBundle, compatibleWith: nil) ?? UIImage()
    }
    public static let failed = Resources.image(named: "failed")
    public static let loading = Resources.image(named: "loading")

    public static let hashTag_bottombar = UDIcon.hashtagOutlined
    public static let picture_bottombar_selected = UDIcon.imageOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    public static let picture_bottombar = UDIcon.imageOutlined.ud.withTintColor(UIColor.ud.iconN3)
    public static let at_bottombar = UDIcon.atOutlined.ud.withTintColor(UIColor.ud.iconN3)
    public static let at_bottombar_selected = UDIcon.atOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    public static let canvas_bottomBar_icon = UDIcon.pencilkitOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    public static let canvas_bottomBar_selected_icon = UDIcon.pencilkitOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    public static let emoji_bottombar_selected = UDIcon.emojiOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    public static let emoji_bottombar = UDIcon.emojiOutlined.ud.withTintColor(UIColor.ud.iconN3)
    public static let font_bottombar = Resources.image(named: "font_bottombar").ud.withTintColor(UIColor.ud.iconN3)
    public static let font_bottombar_selected = Resources.image(named: "font_bottombar").ud.withTintColor(UIColor.ud.colorfulBlue)
    public static let sent_light = UDIcon.sendColorful.ud.withTintColor(UIColor.ud.colorfulBlue)
    public static let sent_shadow = Resources.image(named: "sent_shadow")
    public static let todo_bottombar = UDIcon.tabTodoOutlined.ud.withTintColor(UIColor.ud.iconN2)
    public static let todo_bottombar_selected = UDIcon.tabTodoOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    static let inline_icon_placeholder = UDIcon.getIconByKey(.linkCopyOutlined, size: CGSize(width: 16, height: 16))
    static let small_video_icon = UDIcon.getIconByKey(.videoFilled, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
}

extension Resources {
    public typealias DocInfo = (iconType: RustPB.Basic_V1_Doc.TypeEnum, fileName: String)
    public static let messageFont: UIFont = UIFont.ud.body0
    public static let localDocsPrefix: String = LarkModel.localDocsPrefix
    public static let customKey = "customKey"
    public static let customTitle = LarkRichTextCore.Resources.customTitle

    public static func docIconOriginKey(type: RustPB.Basic_V1_Doc.TypeEnum, filename: String, customKey: String) -> String {
        let docsIconType = DocsIconType(docType: type)
        let encodeFilename = filename.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if customKey.isEmpty {
            return Resources.localDocsPrefix + docsIconType.rawValue + "?file=\(encodeFilename)"
        }
        return Resources.localDocsPrefix + docsIconType.rawValue + "?file=\(encodeFilename)&\(Self.customKey)=\(customKey)"
    }

    public static func parseDocInfoBy(originKey: String) -> DocInfo? {
        if !originKey.hasPrefix(localDocsPrefix) { return nil }
        guard let url = URL(string: originKey),
            let pathComponent = url.pathComponents.last,
            let docsIconType = DocsIconType(rawValue: pathComponent),
            let fileName = url.queryParameters["file"]?.removingPercentEncoding else { return nil }
        return (RustPB.Basic_V1_Doc.TypeEnum(docsIconType: docsIconType), fileName)
    }
}

/// 字体相关
extension Resources {
    public static let arrow_goback_fontbar = Resources.image(named: "arrow_goback_fontbar")
    public static let bold_fontbar = Resources.image(named: "bold_fontbar").ud.withTintColor(UIColor.ud.iconN2)
    public static let italic_fontbar = Resources.image(named: "italic_fontbar").ud.withTintColor(UIColor.ud.iconN2)
    public static let strikethrough_fontbar = Resources.image(named: "strikethrough_fontbar").ud.withTintColor(UIColor.ud.iconN2)
    public static let underline_fontbar = Resources.image(named: "underline_fontbar").ud.withTintColor(UIColor.ud.iconN2)

    public static let bold_fontbar_selected = Resources.image(named: "bold_fontbar").ud.withTintColor(UIColor.ud.colorfulBlue)
    public static let italic_fontbar_selected = Resources.image(named: "italic_fontbar").ud.withTintColor(UIColor.ud.colorfulBlue)
    public static let strikethrough_fontbar_selected = Resources.image(named: "strikethrough_fontbar").ud.withTintColor(UIColor.ud.colorfulBlue)
    public static let underline_fontbar_selected = Resources.image(named: "underline_fontbar").ud.withTintColor(UIColor.ud.colorfulBlue)
}
