//
//  LarkMailResources.swift
//  LarkMail
//
//  Created by 谭志远 on 2019/6/5.
//  Copyright © 2019年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import LarkAppResources
import LarkLocalizations

class LarkMailResources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkMailBundle, compatibleWith: nil) ?? UIImage()
    }

    private static func localizationsImage(named: String) -> UIImage {
        return LanguageManager.image(named: named, in: BundleConfig.LarkMailBundle) ?? UIImage()
    }

    static let mail_scene_icon = LarkMailResources.image(named: "mail_scene_icon")
}
