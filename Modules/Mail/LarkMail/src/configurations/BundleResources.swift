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
        return UIImage(named: named, in: BundleConfig.LarkMailBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    	class LarkMail {
		class Mail {
			static let mail_set_unread = BundleResources.image(named: "mail_set_unread")
			static let docs_detail_share_toutiaoquan = BundleResources.image(named: "docs_detail_share_toutiaoquan")
			static let send_docs_delete_doc = BundleResources.image(named: "send_docs_delete_doc")
			static let docs_detail_share_link = BundleResources.image(named: "docs_detail_share_link")
			static let mail_set_read = BundleResources.image(named: "mail_set_read")
		}
		class Tabbar {
			class Badge {
				static let badge_inbox_mute_more_icon = BundleResources.image(named: "badge_inbox_mute_more_icon")
				static let badge_inbox_more_icon = BundleResources.image(named: "badge_inbox_more_icon")
				static let badge_red_mute_icon = BundleResources.image(named: "badge_red_mute_icon")
				static let badge_done_more_icon = BundleResources.image(named: "badge_done_more_icon")
				static let badge_urgent_icon = BundleResources.image(named: "badge_urgent_icon")
				static let badge_mute_icon = BundleResources.image(named: "badge_mute_icon")
				static let badge_at_icon = BundleResources.image(named: "badge_at_icon")
			}
			static let tabbar_mail_shadow = BundleResources.image(named: "tabbar_mail_shadow")
			static let tabbar_mail_light = BundleResources.image(named: "tabbar_mail_light")
		}
	}

}
//swiftlint:enable all
