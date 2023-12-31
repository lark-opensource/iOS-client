// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation
import UIKit

extension UIImage {
    /// 对主端dynamic的封装，支持传入可选型image
    static func icon_dynamic(lightImage: UIImage?, darkImage: UIImage?) -> UIImage? {
        guard let lightImg = lightImage,
              let darkImg = darkImage else {
            return lightImage
        }
        return UIImage.dynamic(
            light: lightImg,
            dark: darkImg
        )
    }
}

@IBDesignable
public final class IBIconImageView: FontImageView {
    @IBInspectable
    dynamic public var iconName: String = "" {
        willSet {
            iconDrawable = Icon(named: newValue)
        }
    }
}

public final class IBIconButton: UIButton {
    @IBInspectable
    dynamic public var iconName: String = "" {
        willSet {
            let iconDrawable = Icon(named: newValue)

            let image = iconDrawable.fontImage(of: frame.size.width, color: nil)?.withRenderingMode(.alwaysTemplate)
            self.setImage(image, for: .normal)
        }
    }
}

public final class ShapeIconImageView: ShapeImageView {
    public convenience init(icon: Icon, tintColor: UIColor? = UIColor.ud.primaryOnPrimaryFill) {
        self.init(iconDrawable: icon, tintColor: tintColor)
    }

    public var icon: Icon? {
        didSet {
            self.iconDrawable = icon
        }
    }
}

public extension UIImage {
    @available(*, deprecated, renamed: "UIImage.dynamicIcon")
    static func normal(_ icon: Icon, dimension: CGFloat) -> UIImage? {
        return icon.fontImage(of: dimension, color: UIColor.ud.primaryOnPrimaryFill)
    }
}

public extension UIImage {
    @available(*, deprecated, renamed: "UIImage.dynamicIcon")
    static func icon(_ icon: Icon, dimension: CGFloat, color: UIColor? = UIColor.ud.primaryOnPrimaryFill) -> UIImage? {
        return icon.fontImage(of: dimension, color: color)
    }

    static func dynamicIcon(_ icon: Icon, dimension: CGFloat, color: UIColor) -> UIImage? {
        return icon.fontImage(of: dimension, color: color)?.ud.withTintColor(color)
    }

    static func dynamicIcon(_ icon: Icon, size: CGSize, color: UIColor) -> UIImage? {
        return icon.fontImage(of: size, color: color)?.ud.withTintColor(color)
    }

    static func dynamicShapeIcon(_ icon: Icon, width: CGFloat, color: UIColor) -> UIImage? {
        return icon.shapeImage(ofWidth: width, color: color)?.ud.withTintColor(color)
    }

    static func dynamicShapeIcon(_ icon: Icon, height: CGFloat, color: UIColor) -> UIImage? {
        return icon.shapeImage(ofHeight: height, color: color)?.ud.withTintColor(color)
    }
}

public extension UIButton {
    func setDynamicIcon(_ icon: Icon, dimension: CGFloat, color: UIColor, for state: UIControl.State) {
        var image: UIImage? = UIImage()
        if #available(iOS 13.0, *), color.isDynamic {
            image = UIImage.icon_dynamic(lightImage: icon.fontImage(of: dimension, color: color.alwaysLight),
                                      darkImage: icon.fontImage(of: dimension, color: color.alwaysDark))
        } else {
            image = icon.fontImage(of: dimension, color: color)
        }
        setImage(image?.withRenderingMode(.alwaysOriginal), for: state)
    }

    func setDynamicIcon(_ icon: Icon, size: CGSize, color: UIColor, for state: UIControl.State) {
        var image: UIImage? = UIImage()
        if #available(iOS 13.0, *), color.isDynamic {
            image = UIImage.icon_dynamic(lightImage: icon.fontImage(of: size, color: color.alwaysLight),
                                      darkImage: icon.fontImage(of: size, color: color.alwaysDark))
        } else {
            image = icon.fontImage(of: size, color: color)
        }
        setImage(image?.withRenderingMode(.alwaysOriginal), for: state)
    }

    func setDynamicShapeIcon(_ icon: Icon, width: CGFloat, color: UIColor, for state: UIControl.State) {
        var image: UIImage? = UIImage()
        if #available(iOS 13.0, *), color.isDynamic {
            image = UIImage.icon_dynamic(lightImage: icon.shapeImage(ofWidth: width, color: color.alwaysLight),
                                      darkImage: icon.shapeImage(ofWidth: width, color: color.alwaysDark))
        } else {
            image = icon.shapeImage(ofWidth: width, color: color)
        }
        setImage(image?.withRenderingMode(.alwaysOriginal), for: state)
    }

    func setDynamicShapeIcon(_ icon: Icon, height: CGFloat, color: UIColor, for state: UIControl.State) {
        var image: UIImage? = UIImage()
        if #available(iOS 13.0, *), color.isDynamic {
            image = UIImage.icon_dynamic(lightImage: icon.shapeImage(ofHeight: height, color: color.alwaysLight),
                                      darkImage: icon.shapeImage(ofHeight: height, color: color.alwaysDark))
        } else {
            image = icon.shapeImage(ofHeight: height, color: color)
        }
        setImage(image?.withRenderingMode(.alwaysOriginal), for: state)
    }
}

/** A list with available icon glyphs from the icon font. */
@objc public enum Icon: Int, CaseIterable {
    case adsMobile
    case adsMobileAvatarCircle
    case aFrame1564573
    case aIconFileLinkExcelOutlined2x
    case aIconFileLinkPptOutlined2x
    case iconArrowDownOutlined
    case iconArrowUpOutlined
    case iconArrowDown
    case iconCcmRenameOutlined
    case iconCloseSmallOutlined
    case iconCopyOutlined
    case iconDeleteTrashOutlined
    case iconDown
    case iconEditOutlined1
    case iconEllipsis
    case iconEmojiOutlined
    case iconFileFolderColorful
    case iconFilterOutlined1
    case iconHou15s
    case iconInfoOutlined
    case iconLeftOutlined
    case iconMagnifyOutlined
    case iconMaybeOutlined
    case iconMemberAddOutlined
    case iconMinifyOutlined
    case iconMore1
    case iconMoreCloseOutlined
    case iconNext
    case iconPre
    case iconQian15s
    case iconQuote
    case iconRedoOutlined
    case iconRefresh
    case iconReplyCnFilled
    case iconReplyCnOutlined
    case iconSearchOutlined
    case iconSepwindowOutlined
    case iconShareOutlined
    case iconSharedspaceColorful
    case iconStopBold
    case iconSubtitlesFilled
    case iconSubtitlesOutlined
    case iconTimeOutlined
    case iconTranslateCancelThin
    case iconTranslateOutlined
    case iconUndoOutlined
    case iconUp
    case iconUpRoundOutlined
    case iconVideoOffFilled
    case iconZoomIn
    case iconZoomOut
    case play
    case stop
}

extension Icon: IconDrawable {
    /** The icon font's family name. */
    public static var familyName: String {
        return "iconfont_minutes"
    }

    /** The icon font's total count of available icons. */
    public static var count: Int {
        return 53
    }

    /** The icon font's path. */
    public var path: CGPath? {
        return Iconfont.fontNameCGPathMapper[name]
    }

    /**
     Creates a new instance with the specified icon name.
     If there is no valid name recognised, this initializer falls back to the first available icon.

     - parameter iconName: The icon name to use for the new instance.
     */
    public init(named iconName: String) {
        switch iconName.lowercased() {
        case "a-DSMobile": self = .adsMobile
        case "a-DSMobile-Avatar-Circle": self = .adsMobileAvatarCircle
        case "a-Frame1564573": self = .aFrame1564573
        case "a-icon_file-link-excel_outlined2x": self = .aIconFileLinkExcelOutlined2x
        case "a-icon_file_link-ppt_outlined2x": self = .aIconFileLinkPptOutlined2x
        case "icon_arrow-down_outlined": self = .iconArrowDownOutlined
        case "icon_arrow-up_outlined": self = .iconArrowUpOutlined
        case "icon_arrow_down": self = .iconArrowDown
        case "icon_ccm-rename_outlined": self = .iconCcmRenameOutlined
        case "icon_close-small_outlined": self = .iconCloseSmallOutlined
        case "icon_copy_outlined": self = .iconCopyOutlined
        case "icon_delete-trash_outlined": self = .iconDeleteTrashOutlined
        case "icon_down": self = .iconDown
        case "icon_edit_outlined-1": self = .iconEditOutlined1
        case "icon_ellipsis": self = .iconEllipsis
        case "icon_emoji_outlined": self = .iconEmojiOutlined
        case "icon_file-folder_colorful": self = .iconFileFolderColorful
        case "icon_filter_outlined-1": self = .iconFilterOutlined1
        case "icon_hou15s": self = .iconHou15s
        case "icon_info_outlined": self = .iconInfoOutlined
        case "icon_left_outlined": self = .iconLeftOutlined
        case "icon_magnify_outlined": self = .iconMagnifyOutlined
        case "icon_maybe_outlined": self = .iconMaybeOutlined
        case "icon_member-add_outlined": self = .iconMemberAddOutlined
        case "icon_minify_outlined": self = .iconMinifyOutlined
        case "icon_more-1": self = .iconMore1
        case "icon_more-close_outlined": self = .iconMoreCloseOutlined
        case "icon_next": self = .iconNext
        case "icon_pre": self = .iconPre
        case "icon_qian15s": self = .iconQian15s
        case "icon_quote": self = .iconQuote
        case "icon_redo_outlined": self = .iconRedoOutlined
        case "icon_refresh": self = .iconRefresh
        case "icon_reply-cn_filled": self = .iconReplyCnFilled
        case "icon_reply-cn_outlined": self = .iconReplyCnOutlined
        case "icon_search_outlined": self = .iconSearchOutlined
        case "icon_sepwindow_outlined": self = .iconSepwindowOutlined
        case "icon_share_outlined": self = .iconShareOutlined
        case "icon_sharedspace_colorful": self = .iconSharedspaceColorful
        case "icon_stop-bold": self = .iconStopBold
        case "icon_subtitles_filled": self = .iconSubtitlesFilled
        case "icon_subtitles_outlined": self = .iconSubtitlesOutlined
        case "icon_time_outlined": self = .iconTimeOutlined
        case "icon_translate-cancel-thin": self = .iconTranslateCancelThin
        case "icon_translate_outlined": self = .iconTranslateOutlined
        case "icon_undo_outlined": self = .iconUndoOutlined
        case "icon_up": self = .iconUp
        case "icon_up-round_outlined": self = .iconUpRoundOutlined
        case "icon_video-off_filled": self = .iconVideoOffFilled
        case "icon_zoom-in": self = .iconZoomIn
        case "icon_zoom-out": self = .iconZoomOut
        case "play": self = .play
        case "stop": self = .stop
        default: self = Icon(rawValue: 0)!
        }
    }

    /** The icon's name. */
    public var name: String {
        switch self {
        case .adsMobile: return "a-DSMobile"
        case .adsMobileAvatarCircle: return "a-DSMobile-Avatar-Circle"
        case .aFrame1564573: return "a-Frame1564573"
        case .aIconFileLinkExcelOutlined2x: return "a-icon_file-link-excel_outlined2x"
        case .aIconFileLinkPptOutlined2x: return "a-icon_file_link-ppt_outlined2x"
        case .iconArrowDownOutlined: return "icon_arrow-down_outlined"
        case .iconArrowUpOutlined: return "icon_arrow-up_outlined"
        case .iconArrowDown: return "icon_arrow_down"
        case .iconCcmRenameOutlined: return "icon_ccm-rename_outlined"
        case .iconCloseSmallOutlined: return "icon_close-small_outlined"
        case .iconCopyOutlined: return "icon_copy_outlined"
        case .iconDeleteTrashOutlined: return "icon_delete-trash_outlined"
        case .iconDown: return "icon_down"
        case .iconEditOutlined1: return "icon_edit_outlined-1"
        case .iconEllipsis: return "icon_ellipsis"
        case .iconEmojiOutlined: return "icon_emoji_outlined"
        case .iconFileFolderColorful: return "icon_file-folder_colorful"
        case .iconFilterOutlined1: return "icon_filter_outlined-1"
        case .iconHou15s: return "icon_hou15s"
        case .iconInfoOutlined: return "icon_info_outlined"
        case .iconLeftOutlined: return "icon_left_outlined"
        case .iconMagnifyOutlined: return "icon_magnify_outlined"
        case .iconMaybeOutlined: return "icon_maybe_outlined"
        case .iconMemberAddOutlined: return "icon_member-add_outlined"
        case .iconMinifyOutlined: return "icon_minify_outlined"
        case .iconMore1: return "icon_more-1"
        case .iconMoreCloseOutlined: return "icon_more-close_outlined"
        case .iconNext: return "icon_next"
        case .iconPre: return "icon_pre"
        case .iconQian15s: return "icon_qian15s"
        case .iconQuote: return "icon_quote"
        case .iconRedoOutlined: return "icon_redo_outlined"
        case .iconRefresh: return "icon_refresh"
        case .iconReplyCnFilled: return "icon_reply-cn_filled"
        case .iconReplyCnOutlined: return "icon_reply-cn_outlined"
        case .iconSearchOutlined: return "icon_search_outlined"
        case .iconSepwindowOutlined: return "icon_sepwindow_outlined"
        case .iconShareOutlined: return "icon_share_outlined"
        case .iconSharedspaceColorful: return "icon_sharedspace_colorful"
        case .iconStopBold: return "icon_stop-bold"
        case .iconSubtitlesFilled: return "icon_subtitles_filled"
        case .iconSubtitlesOutlined: return "icon_subtitles_outlined"
        case .iconTimeOutlined: return "icon_time_outlined"
        case .iconTranslateCancelThin: return "icon_translate-cancel-thin"
        case .iconTranslateOutlined: return "icon_translate_outlined"
        case .iconUndoOutlined: return "icon_undo_outlined"
        case .iconUp: return "icon_up"
        case .iconUpRoundOutlined: return "icon_up-round_outlined"
        case .iconVideoOffFilled: return "icon_video-off_filled"
        case .iconZoomIn: return "icon_zoom-in"
        case .iconZoomOut: return "icon_zoom-out"
        case .play: return "play"
        case .stop: return "stop"
        default: return ""
        }
    }

    /** The icon's unicode. */
    public var unicode: String {
        switch self {
        case .adsMobile: return "\u{E71D}"
        case .adsMobileAvatarCircle: return "\u{E727}"
        case .aFrame1564573: return "\u{E70E}"
        case .aIconFileLinkExcelOutlined2x: return "\u{E603}"
        case .aIconFileLinkPptOutlined2x: return "\u{E602}"
        case .iconArrowDownOutlined: return "\u{E71A}"
        case .iconArrowUpOutlined: return "\u{E735}"
        case .iconArrowDown: return "\u{E678}"
        case .iconCcmRenameOutlined: return "\u{E738}"
        case .iconCloseSmallOutlined: return "\u{E72E}"
        case .iconCopyOutlined: return "\u{E712}"
        case .iconDeleteTrashOutlined: return "\u{E710}"
        case .iconDown: return "\u{E721}"
        case .iconEditOutlined1: return "\u{E724}"
        case .iconEllipsis: return "\u{E72D}"
        case .iconEmojiOutlined: return "\u{E722}"
        case .iconFileFolderColorful: return "\u{E70F}"
        case .iconFilterOutlined1: return "\u{E72C}"
        case .iconHou15s: return "\u{E656}"
        case .iconInfoOutlined: return "\u{E71B}"
        case .iconLeftOutlined: return "\u{E72B}"
        case .iconMagnifyOutlined: return "\u{E66D}"
        case .iconMaybeOutlined: return "\u{E739}"
        case .iconMemberAddOutlined: return "\u{E715}"
        case .iconMinifyOutlined: return "\u{E66C}"
        case .iconMore1: return "\u{E72F}"
        case .iconMoreCloseOutlined: return "\u{E73A}"
        case .iconNext: return "\u{E668}"
        case .iconPre: return "\u{E667}"
        case .iconQian15s: return "\u{E657}"
        case .iconQuote: return "\u{E718}"
        case .iconRedoOutlined: return "\u{E726}"
        case .iconRefresh: return "\u{E660}"
        case .iconReplyCnFilled: return "\u{E713}"
        case .iconReplyCnOutlined: return "\u{E720}"
        case .iconSearchOutlined: return "\u{E716}"
        case .iconSepwindowOutlined: return "\u{E66B}"
        case .iconShareOutlined: return "\u{E732}"
        case .iconSharedspaceColorful: return "\u{E736}"
        case .iconStopBold: return "\u{E661}"
        case .iconSubtitlesFilled: return "\u{E731}"
        case .iconSubtitlesOutlined: return "\u{E730}"
        case .iconTimeOutlined: return "\u{E71E}"
        case .iconTranslateCancelThin: return "\u{E67D}"
        case .iconTranslateOutlined: return "\u{E71F}"
        case .iconUndoOutlined: return "\u{E711}"
        case .iconUp: return "\u{E717}"
        case .iconUpRoundOutlined: return "\u{E71C}"
        case .iconVideoOffFilled: return "\u{E737}"
        case .iconZoomIn: return "\u{E729}"
        case .iconZoomOut: return "\u{E72A}"
        case .play: return "\u{E734}"
        case .stop: return "\u{E733}"
        default: return ""
        }
    }
}
