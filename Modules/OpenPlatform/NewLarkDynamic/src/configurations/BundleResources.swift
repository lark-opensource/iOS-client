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
import UniverseDesignTheme
//swiftlint:disable all

typealias ICON = BundleResources.NewLarkDynamic

class BundleResources {
    class NewLarkDynamic {
        static func image(named: String) -> UIImage {
            return UIImage(named: named, in: BundleConfig.NewLarkDynamicBundle, compatibleWith: nil) ?? UIImage()
        }
        static func loadIcon(_ key: UDIconType, iconColor: UIColor) -> UIImage {
            let icon = UDIcon.getIconByKey(key, size: NewLarkDynamic.iconSize)
                             .ud.withTintColor(iconColor)
            return icon
        }
        static let iconSize = CGSize(width: 18, height: 18)
        /// date
        static let date = NewLarkDynamic.loadIcon(.calendarOutlined,
                                                  iconColor: .ud.iconN2)
        static let date_disable = NewLarkDynamic.loadIcon(.calendarOutlined,
                                                          iconColor: .ud.iconDisabled)
        /// loading
        static let loading = NewLarkDynamic.loadIcon(.loadingOutlined,
                                                     iconColor: .ud.primaryContentDefault)
        static let loading_red = NewLarkDynamic.loadIcon(.loadingOutlined,
                                                         iconColor: .ud.functionDangerContentDefault)
        /// menu
        static let menu = NewLarkDynamic.loadIcon(.downOutlined,
                                                  iconColor: .ud.iconN2)
        static let menu_disable = NewLarkDynamic.loadIcon(.downOutlined,
                                                          iconColor: .ud.iconDisabled)
        /// overflow
        static let overflow = NewLarkDynamic.loadIcon(.moreOutlined,
                                                      iconColor: .ud.iconN2)

        static let overflow_disable = NewLarkDynamic.loadIcon(.moreOutlined,
                                                              iconColor: .ud.iconDisabled)
        /// time
        static let time = NewLarkDynamic.loadIcon(.timeOutlined,
                                                  iconColor: .ud.iconN2)
        static let time_disable = NewLarkDynamic.loadIcon(.timeOutlined,
                                                          iconColor: .ud.iconDisabled)
        static let image_placeholder = NewLarkDynamic.loadIcon(.imageFailOutlined,
                                                               iconColor: .ud.iconDisabled)
        
        /// load icon method
        static func iconbyName(iconName: String) -> UIImage? {
            switch iconName {
            case "button_date":
                return NewLarkDynamic.date
            case "button_date_disable":
                return NewLarkDynamic.date_disable
            case "button_loading":
                return NewLarkDynamic.loading
            case "button_loading_red":
                return NewLarkDynamic.loading_red
            case "button_menu":
                return NewLarkDynamic.menu
            case "button_menu_disable":
                return NewLarkDynamic.menu_disable
            case "button_overflow":
                return NewLarkDynamic.overflow
            case "button_overflow_disable":
                return NewLarkDynamic.overflow_disable
            case "button_time":
                return NewLarkDynamic.time
            case "button_time_disable":
                return NewLarkDynamic.time_disable
            default:
                return nil
            }
        }
        static let updateWarn = NewLarkDynamic
            .loadIcon(.warningHollowFilled, iconColor: .ud.iconN3)
    }
}
//swiftlint:enable all
