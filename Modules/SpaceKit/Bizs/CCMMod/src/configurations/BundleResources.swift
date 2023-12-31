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
import UniverseDesignIcon
import UniverseDesignColor

#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif

class BundleResources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "CCMMod.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.CCMModBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    class CCMMod {
        class Docs {
            static let icon_doc_colorful = BundleResources.image(named: "icon_doc_colorful")
            static let send_docs_delete_doc = BundleResources.image(named: "send_docs_delete_doc")
        }
        class Share {
            static let icon_bell_outlined = BundleResources.image(named: "icon_bell_outlined")
        }
        class Tabbar {
            static let tabbar_docs_light = BundleResources.image(named: "tabbar_docs_light")
            static let tabbar_docs_shadow = BundleResources.image(named: "tabbar_docs_shadow")
            static let tabbar_wiki_light = BundleResources.image(named: "tabbar_wiki_light")
            static let tabbar_wiki_shadow = BundleResources.image(named: "tabbar_wiki_shadow")
        }
        class Feed {
            static let badge_at_icon = UDIcon.getIconByKey(.atOutlined, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.staticWhite)
        }
    }
}
