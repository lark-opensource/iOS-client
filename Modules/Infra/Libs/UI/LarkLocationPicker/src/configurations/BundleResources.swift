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
import UniverseDesignIcon

// swiftlint:disable all
final class BundleResources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkLocationPickerBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    	final class LarkLocationPicker {
		static let user_location = BundleResources.image(named: "user_location")
		static let location_icon = BundleResources.image(named: "location_icon")
		static let distance_icon = BundleResources.image(named: "distance_icon")
		static let location_center_selected = BundleResources.image(named: "location_center_selected")
		static let newEventLocationGray = UDIcon.localOutlined.ud.withTintColor(UIColor.ud.iconN3)
		static let checkbox_on = BundleResources.image(named: "checkbox_on")
		static let location_center_selected_clicked = BundleResources.image(named: "location_center_selected_clicked")
		static let location_center = BundleResources.image(named: "location_center")
		static let loading = BundleResources.image(named: "loading")
		static let search = UDIcon.searchOutlineOutlined.ud.withTintColor(UIColor.ud.iconN3)
		static let location_center_clicked = BundleResources.image(named: "location_center_clicked")
		static let search_clear = UDIcon.getIconByKey(.closeFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconDisabled)
            
        static let location_navigate = BundleResources.image(named: "location_navigate")
        static let location_navigate_clicked = BundleResources.image(named: "location_navigate_clicked")
        static let location_more = BundleResources.image(named: "more")
        static let location_more_highlight = BundleResources.image(named: "more_highlight")
        static let location_nav_back = BundleResources.image(named: "nav_back")
        static let location_nav_back_highlight = BundleResources.image(named: "nav_back_highlight")
        static let nav_back = UDIcon.showToolbarOutlined.ud.withTintColor(UIColor.ud.iconN1)
	}

}
//swiftlint:enable all
