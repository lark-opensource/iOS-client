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

#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif

//swiftlint:disable all
final class BundleResources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "LarkSearchCore.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.LarkSearchCoreBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    final class LarkSearchCore {
        static let department_avatar = BundleResources.image(named: "department_avatar")
        final class Picker {
            static let table_unfold = BundleResources.image(named: "table_unfold")
            static let thread_topic = BundleResources.image(named: "thread_topic")
            static let thread_topic_middle = BundleResources.image(named: "thread_topic_middle")
            static let thread_msg_icon = BundleResources.image(named: "messageThreadIcon")
            static let user_group = BundleResources.image(named: "user_group")
        }
    }

}
//swiftlint:enable all
