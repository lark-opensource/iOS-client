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

// swiftlint:disable all
final class BundleResources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkBadgeBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    	final class LarkBadge {
		static let cal_new = BundleResources.image(named: "cal_new")
		static let edit = BundleResources.image(named: "edit")

        static let more_strong = BundleResources.image(named: "badge_inbox_more_icon")
        static let more_middle = BundleResources.image(named: "badge_done_more_icon")
        static let more_weak = BundleResources.image(named: "badge_inbox_mute_more_icon")
	}

}
//swiftlint:enable all
