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
final class BundleResources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "ByteViewTab.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.ByteViewTabBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    class ByteViewTab {
        class Collection {
            static let collectionAI = BundleResources.image(named: "collectionAI")
            static let collectionAIBg = BundleResources.image(named: "collectionAIBg")
            static let collectionCalendar = BundleResources.image(named: "collectionCalendar")
            static let collectionCalendarBg = BundleResources.image(named: "collectionCalendarBg")
        }
        class EnterpriseCall {
            static let DeleteButtonBackground = BundleResources.image(named: "DeleteButtonBackground")
            static let DeleteButtonBackgroundHighlighted = BundleResources.image(named: "DeleteButtonBackgroundHighlighted")
        }
        class MinutesPreview {
            static let fileVideoColorful = BundleResources.image(named: "fileVideoColorful")
            static let tabVideoColorful = BundleResources.image(named: "tabVideoColorful")
            static let webinarVideoColorful = BundleResources.image(named: "webinarVideoColorful")
            class BG {
                static let Call = BundleResources.image(named: "Call")
                static let Generating = BundleResources.image(named: "Generating")
                static let Video = BundleResources.image(named: "Video")
            }
        }
    }

}
//swiftlint:enable all
