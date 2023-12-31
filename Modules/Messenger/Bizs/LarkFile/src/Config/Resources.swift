//
//  Resources.swift
//  LarkFile
//
//  Created by ChalrieSu on 2018/6/28.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignEmpty

final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkFileBundle, compatibleWith: nil) ?? UIImage()
    }

    static let file_download_close = UDIcon.getIconByKey(.closeFilled, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulRed)
    static let file_download_finish = UDIcon.getIconByKey(.yesFilled, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulBlue)

    static let load_fail = UDEmptyType.loadingFailure.defaultImage()
    static let member_select_cancel = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN2)
    static let read_status_arrow = UDIcon.getIconByKey(.upOutlined, size: CGSize(width: 13, height: 13)).ud.withTintColor(UIColor.ud.iconN3)
    static let navigation_close_light = UDIcon.getIconByKey(.closeOutlined).ud.withTintColor(UIColor.ud.iconN1)
    static let empty_page = UDEmptyType.noFile.defaultImage()
    static let more = UDIcon.moreOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let icon_item_grid = UDIcon.getIconByKey(.bordersOutlined).ud.withTintColor(UIColor.ud.iconN1)
    static let icon_item_list = UDIcon.getIconByKey(.disorderListOutlined).ud.withTintColor(UIColor.ud.iconN1)
    static let icon_folder = UDIcon.getIconByKey(.fileFolderColorful, size: CGSize(width: 70, height: 70))
    static let video_icon = UDIcon.getIconByKey(.videoFilled, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)

    static let arrow = UDIcon.getIconByKey(.expandRightFilled, size: CGSize(width: 10, height: 10)).ud.withTintColor(UIColor.ud.iconN1)

    static let fileZip = UDIcon.getIconByKey(.fileZipColorful, size: CGSize(width: 60, height: 60))
}
