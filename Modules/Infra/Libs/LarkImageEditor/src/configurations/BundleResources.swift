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
// swiftlint:disable all
import UniverseDesignIcon

public final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkImageEditorBundle, compatibleWith: nil) ?? UIImage()
    }

    // Image Edit
    public static let edit_line = UDIcon.penOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    public static let edit_mosaic = Resources.image(named: "image_edit_mosaic")
    public static let edit_text = UDIcon.text2Outlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    public static let edit_trim = UDIcon.rotateSliceOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)

    public static let edit_mosaic_icon = UDIcon.mosaicOutlined.ud.colorize(color: .ud.iconN1)
    public static let edit_text_icon = UDIcon.textOutlined.ud.colorize(color: .ud.iconN1)
    public static let edit_cut_icon = UDIcon.rotateSliceOutlined.ud.colorize(color: .ud.iconN1)
    public static let edit_draw_icon = UDIcon.penOutlined.ud.colorize(color: .ud.iconN1)
    public static let edit_tag_icon = UDIcon.markOutlined.ud.colorize(color: .ud.iconN1)

    public static let edit_shape_rect = UDIcon.rectangleOutlined.ud.colorize(color: .ud.iconN1)
    public static let edit_shape_circle = UDIcon.ellipseOutlined.ud.colorize(color: .ud.iconN1)
    public static let edit_shape_arrow = UDIcon.arrowOutlined.ud.colorize(color: .ud.iconN1)

    public static let edit_draw_pixelate = UDIcon.mosaicSmearOutlined.ud.colorize(color: .ud.iconN1)
    public static let edit_select_pixelate = UDIcon.mosaicBoxOutlined.ud.colorize(color: .ud.iconN1)

    public static let edit_aero = Resources.image(named: "image_edit_aero")
    public static let edit_blur = Resources.image(named: "image_edit_blur")

    public static let edit_text_bg_disable = Resources.image(named: "image_edit_text_bg").ud.colorize(color: .ud.iconN1)

    public static let edit_slider_min_v2 = Resources.image(named: "image_edit_slider_min").ud.colorize(color: .ud.primaryOnPrimaryFill)
    public static let edit_slider_max_v2 = Resources.image(named: "image_edit_slider_max").ud.colorize(color: .ud.primaryOnPrimaryFill)
    public static let edit_slider_v2 = Resources.image(named: "image_edit_slider_v2")

    public static let edit_delete = UDIcon.deleteTrashOutlined.ud.colorize(color: .ud.colorfulRed)
    public static let edit_delete_highlighted = UDIcon.deleteTrashOutlined.ud.colorize(color: .ud.primaryOnPrimaryFill)

    public static let edit_text_vertical = Resources.image(named: "image_edit_vertical").ud.colorize(color: .ud.lineDividerDefault)

    public static let edit_text_bg_enable = Resources.image(named: "image_edit_text_bg_highlight")

    public static let edit_cropper_free = UDIcon.customizeSizeOutlined.ud.colorize(color: .ud.iconN1)
    public static let edit_cropper_one_to_one = UDIcon.w1H1Outlined.ud.colorize(color: .ud.iconN1)
    public static let edit_cropper_three_to_four = UDIcon.w3H4Outlined.ud.colorize(color: .ud.iconN1)
    public static let edit_cropper_four_to_three = UDIcon.w4H3Outlined.ud.colorize(color: .ud.iconN1)
    public static let edit_cropper_nine_to_sixteen = UDIcon.w9H16Outlined.ud.colorize(color: .ud.iconN1)
    public static let edit_cropper_sixteen_to_nine = UDIcon.w16H9Outlined.ud.colorize(color: .ud.iconN1)

    public static let edit_cropper_rotate = UDIcon.rotateOutlined.ud.colorize(color: .ud.iconN1)
    public static let edit_cropper_reset = UDIcon.historyOutlined.ud.colorize(color: .ud.iconN1)

    public static let edit_line_highlight = UDIcon.penOutlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)
    public static let edit_mosaic_highlight = Resources.image(named: "image_edit_mosaic").ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)
    public static let edit_text_highlight = UDIcon.text2Outlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)
    public static let edit_trim_highlight = UDIcon.rotateSliceOutlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)
    public static let edit_tag_highlight = UDIcon.markOutlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)

    public static let edit_mosaic_icon_highlight = UDIcon.mosaicOutlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)
    public static let edit_text_icon_highlight = UDIcon.textOutlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)
    public static let edit_cut_icon_highlight = UDIcon.rotateSliceOutlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)
    public static let edit_draw_highlight = UDIcon.penOutlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)

    public static let edit_shape_rect_highlight = UDIcon.rectangleOutlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)
    public static let edit_shape_circle_highlight = UDIcon.ellipseOutlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)
    public static let edit_shape_arrow_highlight = UDIcon.arrowOutlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)

    public static let edit_draw_pixelate_highlight = UDIcon.mosaicSmearOutlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)
    public static let edit_select_pixelate_highlight = UDIcon.mosaicBoxOutlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)

    public static let edit_cropper_free_highlight = UDIcon.customizeSizeOutlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)
    public static let edit_cropper_one_to_one_highlight = UDIcon.w1H1Outlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)
    public static let edit_cropper_three_to_four_highlight = UDIcon.w3H4Outlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)
    public static let edit_cropper_four_to_three_highlight = UDIcon.w4H3Outlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)
    public static let edit_cropper_nine_to_sixteen_highlight = UDIcon.w9H16Outlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)
    public static let edit_cropper_sixteen_to_nine_highlight = UDIcon.w16H9Outlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)

    public static let edit_cropper_rotate_highlight = UDIcon.rotateOutlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)
    public static let edit_cropper_reset_highlight = UDIcon.historyOutlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)

    public static let edit_close = UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    public static let edit_back = UDIcon.leftOutlined.ud.colorize(color: .ud.primaryOnPrimaryFill)
    public static let edit_bottom_save = UDIcon.doneOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    public static let edit_bottom_save_highlight = UDIcon.doneOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    public static let edit_bottom_close = UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    public static let edit_revert = UDIcon.recallOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    public static let edit_revert_highlight = UDIcon.recallOutlined.ud.colorize(color: UIColor.ud.colorfulBlue, resizingMode: .stretch)
    public static let edit_slider = Resources.image(named: "image_edit_slider")
    public static let edit_slider_bg_light = Resources.image(named: "image_edit_slider_bg_light")
    public static let edit_slider_bg_dark = Resources.image(named: "image_edit_slider_bg_dark")
    public static let edit_slider_min = Resources.image(named: "image_edit_slider_min")
    public static let edit_slider_max = Resources.image(named: "image_edit_slider_max")
    public static let edit_rotate = UDIcon.rotateOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    public static let edit_rotate_highlight = UDIcon.rotateOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    public static let edit_send = UDIcon.sendColorful.ud.withTintColor(UIColor.ud.iconDisabled)
    public static let edit_send_highlight = UDIcon.sendColorful.ud.withTintColor(UIColor.ud.colorfulBlue)
    public static let edit_mosaic_effect = Resources.image(named: "image_edit_mosaic_effect")
    public static let edit_Gaussan_effect = Resources.image(named: "image_edit_Gaussan_effect")
    public static let edit_resize = Resources.image(named: "image_edit_resize")
    public static let edit_text_close = Resources.image(named: "image_edit_text_close")
    public static let edit_finger_select = Resources.image(named: "image_edit_finger_select")
    public static let edit_area_select = Resources.image(named: "image_edit_area_select")
    public static let edit_mosaic_close = Resources.image(named: "image_edit_mosaic_close")
    public static let edit_scan_animation_line = Resources.image(named: "image_edit_scan_animation_line")
    public static let edit_scan_cancel_icon = UDIcon.getIconByKey(.moreCloseOutlined, size: CGSize(width: 36, height: 36)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
}
// swiftlint:enable all
