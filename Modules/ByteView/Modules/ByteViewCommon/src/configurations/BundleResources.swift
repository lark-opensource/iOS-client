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

//swiftlint:disable all
public final class BundleResources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.ByteViewCommonBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    public final class ByteViewCommon {
        public final class Avatar {
            public static let interviewer = BundleResources.image(named: "Interviewer")
            public static let guest = BundleResources.image(named: "guest")
            public static let pstn = BundleResources.image(named: "pstn")
            public static let sip = BundleResources.image(named: "sip")
            public static let unknown = BundleResources.image(named: "unknown")
        }
        public final class Common {
            public static let ConnectFailWiFi = BundleResources.image(named: "ConnectFailWiFi")
            public static let NoNetwork = BundleResources.image(named: "NoNetwork")
            public static let Robot = BundleResources.image(named: "Robot")
            public static let ScrollToBottom = BundleResources.image(named: "ScrollToBottom")
            public static let ServerError = BundleResources.image(named: "ServerError")
            public static let iconDeviceDisabled = BundleResources.image(named: "iconDeviceDisabled")
        }
    }

}
//swiftlint:enable all
