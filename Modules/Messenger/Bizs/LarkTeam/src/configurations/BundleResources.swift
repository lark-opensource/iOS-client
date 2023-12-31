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
import LarkAppResources
import UniverseDesignIcon

final class Resources {
    static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkTeamBundle, compatibleWith: nil) ?? UIImage()
    }

    static let right_arrow = Resources.image(named: "right_arrow")
    static let icon_circle_add = Resources.image(named: "icon_circle_add")
    static let icon_circle_delete = Resources.image(named: "icon_circle_delete")
    static let icon_edit = Resources.image(named: "icon_edit")
    static let icon_more_outlined = UDIcon.moreOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let chatOutlined = UDIcon.getIconByKey(.chatOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3)
    static let chatDisableOutlined = UDIcon.getIconByKey(.chatDisableOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3)
    static let icon_more_outlinedN2 = UDIcon.moreOutlined.ud.withTintColor(UIColor.ud.iconN2)
    // 默认团队头像
    static let defalut_team_icon = Resources.image(named: "default_team_icon")
    static let checkmark = UDIcon.getIconByKey(.listCheckBoldOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.primaryContentDefault)
    static let newStyle_team_icon = UDIcon.getIconByKey(.communityTabFilled,
                                                        size: CGSize(width: 60, height: 60)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)

}
