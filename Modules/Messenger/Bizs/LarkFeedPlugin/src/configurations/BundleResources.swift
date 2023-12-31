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
import LarkFeedBase

//swiftlint:disable all
final class BundleResources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkFeedPluginBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    final class LarkFeedPlugin {
        static let feed_at_all_border = LarkFeedBase.Resources.LarkFeedBase.atAllImage
        static let feed_at_me_border = LarkFeedBase.Resources.LarkFeedBase.atMeImage
        static let thread_topic = Resources.LarkFeedPlugin.thread_topic
        static let msg_thread = Resources.LarkFeedPlugin.msg_thread
    }

}
//swiftlint:enable all
