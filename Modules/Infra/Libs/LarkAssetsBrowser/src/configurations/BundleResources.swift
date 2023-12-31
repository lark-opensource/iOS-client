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
import Foundation
import UIKit
import UniverseDesignIcon
// swiftlint:disable all
public final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkAssetsBrowserBundle, compatibleWith: nil) ?? UIImage()
    }
    
    // Asset Browser
    static let savePhotoNormal = UDIcon.getIconByKey(.downloadOutlined, size: CGSize(width: 14, height: 14)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let savePhotoHighlight = UDIcon.getIconByKey(.downloadOutlined, size: CGSize(width: 14, height: 14)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let asset_video_begin_play = image(named: "asset_video_begin_play")
    static let asset_video_close = UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let asset_video_invalid = image(named: "asset_video_invalid")
    static let asset_video_loading = image(named: "asset_video_loading")
    static let asset_video_more = UDIcon.getIconByKey(.menuOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let asset_video_pause = UDIcon.getIconByKey(.pauseLivestreamOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let asset_video_play = UDIcon.getIconByKey(.playFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let asset_video_slider_dot = image(named: "asset_video_slider_dot")
    static let asset_video_slider_dot_pressed = image(named: "asset_video_slider_dot_pressed")
    static let asset_translate_animation_line = image(named: "asset_translate_animation_line")
    static let asset_translate_cancel_button = image(named: "asset_translate_cancel_button")

    // AssetsBrowser bottom tool bar icons.
    static let asset_photo_edit = UDIcon.getIconByKey(.editOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let asset_photo_lookup = UDIcon.getIconByKey(.photoAlbumFilled, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let asset_more = UDIcon.getIconByKey(.moreOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let new_save_photo = UDIcon.getIconByKey(.downloadOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let extractTextIcon = UDIcon.getIconByKey(.extractTextOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let translateIcon = UDIcon.getIconByKey(.translateOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)

    static let scanning = Resources.image(named: "scanningImage")

    // ImagePicker
    public static let image_picker_tick_blue = Resources.image(named: "tick_blue")
    public static let image_picker_small_video_icon = UDIcon.getIconByKey(.videoFilled, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    public static let image_picker_video_time_bg = Resources.image(named: "video_time_bg")
    public static let image_picker_video_icon = Resources.image(named: "video_icon")
    public static let down_arrow = UDIcon.getIconByKey(.expandDownFilled, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.iconN1)
    public static let tips_icon = image(named: "tips_icon")
    public static let close_icon = image(named: "close_icon")
    public static let add_icon = UDIcon.addOutlined.ud.withTintColor(UIColor.ud.iconN3)

    // StatusBar Notification
    static let photInCloud = image(named: "photo_in_cloud")

    // navigation
    public static let navigation_back_white_light = UDIcon.leftOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)

    // Photo Picker
    static let photoLibrary = UDIcon.albumOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let camera = UDIcon.cameraOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let smallPlay = UDIcon.getIconByKey(.videoFilled, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)

    // Assets Collection
    static let gifTag = image(named: "gifTag")
    static let imageDownloading = image(named: "imageDownloading")
    static let imageDownloadFail = image(named: "imageDownloadFail")
    static let emptyData = image(named: "emptyData")
    static let searchImageInChatInitPlaceHolder = image(named: "image_search")
    static let forward = UDIcon.getIconByKey(.forwardOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
    static let mergeForward = UDIcon.getIconByKey(.forwardComOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
    static let delete = UDIcon.getIconByKey(.deleteTrashOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
    static let download = UDIcon.getIconByKey(.downloadOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
    
    static let numberBox_unchecked = Resources.image(named: "numberBox_unchecked")
}
// swiftlint: enable all
