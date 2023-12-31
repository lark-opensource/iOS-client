//Warning: Do Not Edit It!
//Created by EEScaffold, if you want to edit it please check the manual of EEScaffold
//Toolchains For EE, be fast
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

//swiftlint:disable all
class BundleResources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.MinutesFoundationBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    class MinutesFoundation {
        static let failure = BundleResources.image(named: "failure")
        static let success = BundleResources.image(named: "success")
        static let warning = BundleResources.image(named: "warning")
    }

}
//swiftlint:enable all
