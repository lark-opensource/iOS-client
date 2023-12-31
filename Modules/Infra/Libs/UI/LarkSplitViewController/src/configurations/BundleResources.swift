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

public final class Resources {
    public static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkSplitViewControllerBundle, compatibleWith: nil) ?? UIImage()
    }

    public static let enterFullScreen = Resources.image(named: "icon_global_screenmax_nor").ud.withTintColor(UIColor.ud.iconN1)
    public static let leaveFullScreen = Resources.image(named: "icon_global_screenmin_nor").ud.withTintColor(UIColor.ud.iconN1)
    public static let back = Resources.image(named: "icon_global_back_nor")
    public static let colorMap = Resources.image(named: "split_pan_handle_color_map")
}
