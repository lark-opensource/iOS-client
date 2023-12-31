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
import UIKit
import Foundation
import UniverseDesignIcon
/// Resources
public final class Resources {
    /// image
    public static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkEmotionKeyboardBundle, compatibleWith: nil) ?? UIImage()
    }
    /// Highlighted background
    public static let emojiHighlightedBg = image(named: "emoji_bg_highlighted")
    /// DeleteIcon
    public static let keyboardDeleteIcon = UDIcon.deleteOutlined.ud.withTintColor(UIColor.ud.iconN2)
    /// DeleteButtonContainer
    public static let keyboardDeleteButtonContainer = Resources.image(named: "keyboard_delete_container")
    /// emoji
    public static let emoji = Resources.image(named: "emoji")
    /// more icon
    public static let reactionMore = UDIcon.getIconByKey(.moreAddOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
    /// more icon
    public static let sheetMenuMore = UDIcon.getIconByKey(.moreOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
    /// raction
    public static let reactionImage = UDIcon.getIconByKey(.emojiOutlined, size: CGSize(width: 32, height: 32)).ud.withTintColor(UIColor.ud.iconN3)

    public static let addEmoji = Resources.image(named: "addEmoji")
    public static let emotion_setting = UDIcon.settingOutlined.ud.withTintColor(UIColor.ud.iconN2)
    public static let stickerEmoji = Resources.image(named: "stickerEmoji")
    static let addStickerIcon = Resources.image(named: "emotion_empty_addsticker_icon")
}
