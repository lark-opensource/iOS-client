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

#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif

//swiftlint:disable all
public final class BundleResources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "WebBrowser.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.WebBrowserBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    public class WebBrowser {
        static let icon_web_browser_rotation = BundleResources.image(named: "icon_web_browser_rotation")
        static let opweb_icon_close_filled = BundleResources.image(named: "opweb_icon_close_filled")
        static let opweb_icon_succeed_filled = BundleResources.image(named: "opweb_icon_succeed_filled")
        static let opweb_icon_file_no_support = BundleResources.image(named: "opweb_icon_file_no_support")
        public static let muti_task_web_icon = BundleResources.image(named: "muti_task_web_icon")
        public static let mutil_scene_web_icon = BundleResources.image(named: "mutil_scene_web_icon")
        public static let web_app_header_icon = BundleResources.image(named: "web_app_header_icon")
        public static let panel_infobg_icon = BundleResources.image(named: "panel_infobg_icon")
    }

}
//swiftlint:enable all
