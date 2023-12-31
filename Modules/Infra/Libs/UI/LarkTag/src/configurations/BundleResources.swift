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

final class BundleResources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkTagBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = Resources.image(named: "tabbar_conversation_shadow")
    */
    final class LarkTag {
        static let do_not_disturb = image(named: "do_not_disturb")
        static let oncall_offline = image(named: "oncall_offline")
        static let service = image(named: "service")
        static let crypto = image(named: "crypto")
        static let thread = image(named: "thread")
        static let special_focus_icon = UDIcon.getIconByKey(.collectFilled, iconColor: UIColor.ud.colorfulYellow, size: CGSize(width: 16, height: 16))
	}
}
