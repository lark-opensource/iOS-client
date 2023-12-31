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
        return UIImage(named: named, in: BundleConfig.LarkSuspendableBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    final class LarkSuspendable {
        static let icon_basket_dark = UDIcon.getIconByKey(.multitaskOutlined, size: CGSize(width: 36, height: 36)).ud.withTintColor(UIColor.ud.iconN2)
        static let icon_basket_light = UDIcon.getIconByKey(.multitaskOutlined, size: CGSize(width: 36, height: 36)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
        static let icon_chat_outlined = BundleResources.image(named: "icon_chat_outlined")
        static let icon_file_link_mindnote_outlined = BundleResources.image(named: "icon_file-link-mindnote_outlined")
        static let icon_file_link_sheet_outlined = BundleResources.image(named: "icon_file-link-sheet_outlined")
        static let icon_launcher = BundleResources.image(named: "launcher")
        static let icon_file_link_word_outlined = BundleResources.image(named: "icon_file-link-word_outlined")
        static let icon_googledrive_outlined = BundleResources.image(named: "icon_googledrive_outlined")
        static let icon_multitask_1_outlined = BundleResources.image(named: "icon_multitask-1_outlined")
        static let icon_multitask_2_outlined = BundleResources.image(named: "icon_multitask-2_outlined")
        static let icon_multitask_3_outlined = BundleResources.image(named: "icon_multitask-3_outlined")
        static let icon_multitask_4_outlined = BundleResources.image(named: "icon_multitask-4_outlined")
        static let icon_multitask_5_outlined = BundleResources.image(named: "icon_multitask-5_outlined")
        static let icon_multitask_outlined = UDIcon.multitaskOutlined.ud.withTintColor(UIColor.ud.iconN2)
        static let icon_unmultitask_outlined = UDIcon.unmultitaskOutlined.ud.withTintColor(UIColor.ud.iconN2)
        static let icon_task_1 = BundleResources.image(named: "icon_task_1")
        static let icon_task_2 = BundleResources.image(named: "icon_task_2")
        static let icon_task_3 = BundleResources.image(named: "icon_task_3")
        static let icon_task_4 = BundleResources.image(named: "icon_task_4")
        static let icon_task_5 = BundleResources.image(named: "icon_task_5")
        static let icon_task_6 = BundleResources.image(named: "icon_task_6")
        static let icon_task_7 = BundleResources.image(named: "icon_task_7")
        static let icon_task_8 = BundleResources.image(named: "icon_task_8")
        static let icon_task_9 = BundleResources.image(named: "icon_task_9")
        static let icon_suspend_1 = BundleResources.image(named: "icon_suspend_1")
        static let icon_suspend_2 = BundleResources.image(named: "icon_suspend_2")
        static let icon_suspend_3 = BundleResources.image(named: "icon_suspend_3")
        static let icon_suspend_4 = BundleResources.image(named: "icon_suspend_4")
        static let icon_suspend_5 = BundleResources.image(named: "icon_suspend_5")
        static let icon_suspend_6 = BundleResources.image(named: "icon_suspend_6")
        static let icon_suspend_7 = BundleResources.image(named: "icon_suspend_7")
        static let icon_suspend_8 = BundleResources.image(named: "icon_suspend_8")
        static let icon_suspend_9 = BundleResources.image(named: "icon_suspend_9")
    }

}
//swiftlint:enable all
