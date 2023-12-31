//
//  Resources.swift
//  LarkUIKit
//
//  Created by liuwanlin on 2017/12/14.
//  Copyright © 2017年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignEmpty
#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif

public final class Resources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "LarkUIKit.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.LarkUIKitBundle, compatibleWith: nil) ?? UIImage()
    }
    public static let navigation_back_white_light = UDIcon.leftOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    public static let navigation_back_light = UDIcon.leftOutlined.ud.withTintColor(UIColor.ud.iconN1)
    public static let navigation_close_light = UDIcon.closeSmallOutlined.ud.withTintColor(UIColor.ud.iconN1)
    public static let navigation_close_outlined = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN1)
    public static let navigation_new_scene = image(named: "navigation_new_scene")

    // single
    static let closeAlert = UDIcon.getIconByKey(.moreCloseOutlined, size: CGSize(width: 26, height: 26)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let close_guide = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.iconN3)
    static let loading = image(named: "loading")

    // TextField
    static let search_icon = UDIcon.getIconByKey(.searchOutlineOutlined, size: CGSize(width: 14, height: 14)).ud.withTintColor(UIColor.ud.iconN3)

    // EmptyDataView
    static let empty_data_icon = UDEmptyType.imDefault.defaultImage()

    // Work description
    private static func getWorkDescriptionIcon(_ type: UDIconType) -> UIImage {
        return UDIcon.getIconByKey(type, iconColor: UIColor.ud.iconN3, size: CGSize(width: 16, height: 16))
    }
    public static let default_description_small = Resources.getWorkDescriptionIcon(.chatNewsOutlined)

    public static let add_description = UDIcon.getIconByKey(.moreAddOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)

    // LoadFailPlaceholderView
    public static let load_fail = UDEmptyType.loadingFailure.defaultImage()

    /// Contact
    public static let invite_member_no_search_result = UDEmptyType.searchFailed.defaultImage()
    public static let address_book_load_fail = UDEmptyType.loadingFailure.defaultImage()

    // Search
    public static let conversation_search_light = UDIcon.searchOutlineOutlined.ud.withTintColor(UIColor.ud.iconN1)

    /// checkbox
    public static let checkBox_disabled_unchecked = Resources.image(named: "checkBox_disabled_unchecked")
    public static let checkBox_unchecked = Resources.image(named: "checkBox_unchecked")
    public static let checkBox_list_selected = Resources.image(named: "checkBox_list_selected")
    public static let checkBox_list_disabled_unselected = Resources.image(named: "checkBox_list_disabled_unselected")
    public static let checkBox_multi_checked = Resources.image(named: "checkBox_multi_checked")
    public static let checkBox_multi_disabled_checked = Resources.image(named: "checkBox_multi_disabled_checked")
    public static let checkBox_single_checked = Resources.image(named: "checkBox_single_checked")
    public static let checkBox_single_disabled_checked = Resources.image(named: "checkBox_single_disabled_checked")
    public static let checkBox_square_enable_checked = Resources.image(named: "checkBox_square_enable_checked")
    public static let checkBox_square_enable_unchecked = Resources.image(named: "checkBox_square_enable_unchecked")

    /// numberbox
    public static let numberBox_unchecked = Resources.image(named: "numberBox_unchecked")

    /// Breadcrumb
    public static let breadcrumbNext = image(named: "breadcrumb_next")
    public static let refreshDrag = UDIcon.getIconByKey(.arrowDownOutlined, size: CGSize(width: 14, height: 14))
    public static let refreshRelease = UDIcon.getIconByKey(.arrowUpOutlined, size: CGSize(width: 14, height: 14))
    
    /// RichTextImageView
    public static let imageLoading = Resources.image(named: "image_loading")
}
