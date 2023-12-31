//Warning: Do Not Edit It!
//Created by EEScaffold, if you want to edit it please check the manual of EEScaffold
//Toolchains For EE
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
// swiftlint:disable identifier_name
import UniverseDesignIcon
import UniverseDesignColor

final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkOCRBundle, compatibleWith: nil) ?? UIImage()
    }

    static let scanning = Resources.image(named: "scanningImage")
    static let guide1 = Resources.image(named: "guide1").ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let guide2 = Resources.image(named: "guide2").ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)

    static let closeIcon = UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)

    static let copyIcon = UDIcon.copyOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let forwardIcon = UDIcon.forwardOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let extractIcon = UDIcon.describeOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)

}
// swiftlint:enable identifier_name
