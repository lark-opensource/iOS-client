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
import UniverseDesignIcon
import LarkIllustrationResource

// swiftlint:disable all
final class BundleResources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkTourBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    final class LarkTour {
        final class NewUserGuide {
            final class AddMember {
                static let add_member_guide = LarkIllustrationResource.Resources.imSpecializedAddTeamMembers
            }
            final class Welcome {
                static let background_bottom = BundleResources.image(named: "background_bottom")
                static let background_top = BundleResources.image(named: "background_top")
                static let explore_background = BundleResources.image(named: "explore_background")
                static let welcome_emoji = BundleResources.image(named: "welcome_emoji")
            }
        }
        final class Video {
            static let fullscreen_paly = UDIcon.windowMaxOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
            static let loading = BundleResources.image(named: "loading")
            static let mute = BundleResources.image(named: "mute")
            static let pause = UDIcon.pauseLivestreamOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
            static let play = UDIcon.expandRightFilled.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
            static let quit_full_screen = UDIcon.windowMiniOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
            static let replay_button = UDIcon.refreshOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
            static let replay_large = UDIcon.getIconByKey(.refreshOutlined, size: CGSize(width: 40, height: 40)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
            static let slider_circle = BundleResources.image(named: "slider_circle")
            static let voice = UDIcon.getIconByKey(.speakerOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
        }
    }

}
//swiftlint:enable all
