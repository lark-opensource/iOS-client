//
//  Resources.swift
//  Module
//
//  Created by chengzhipeng-bytedance on 2018/3/15.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkEnv
import LarkSetting
import UniverseDesignIcon

final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkUrgentBundle, compatibleWith: nil) ?? UIImage()
    }

    static let urgency = UDIcon.getIconByKey(.buzzFilled, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let avatarBorder = Resources.image(named: "avatar_inner_border")
    static let smallVideoIcon = UDIcon.getIconByKey(.videoFilled, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let urgentAlert = Resources.image(named: "urgent_alert")
    static let imageDownloadFailed = Resources.image(named: "image_download_failed")
    static let urgent_fail_icon = Resources.image(named: "urgent_fail_icon")
}

final class ConfigManager {
    static func jumpHelpDeskUrlString() -> String {
        let domain = DomainSettingManager.shared.currentSetting["urgent_helpdesk_domain"]?.first ?? ""
        let host = "https://\(domain)/client/helpdesk/"
        let quary: String
        if EnvManager.env.isStaging {
            quary = "open?id=6934871265543159828&extra=%7B%22channel%22%3A14%2C%22created_at%22%3A1617246713%2C%22human_service%22%3Atrue%2C%22scenario_id%22%3A6937491551345967123%2C%22" +
            "signature%22%3A%229df9ed53d1cd7fd62be8055f37ab2f8b8cf71583%22%7D"
        } else {
            quary = "open?id=6626260912531570952&extra=%7B%22channel%22%3A14%2C%22created_at%22%3A1616898084%2C%22human_service%22%3Atrue%2C%22scenario_id%22%3A6888204905589325826%2C%22" +
            "signature%22%3A%2278b0c5156b727a66d02c9b689ea0785d1a865bb5%22%7D"
        }
        return host + quary
    }
}
