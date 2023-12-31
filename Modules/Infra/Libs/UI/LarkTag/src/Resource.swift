//
//  Resource.swift
//  LarkTag
//
//  Created by Aslan on 2021/9/10.
//

import Foundation
import UIKit

final class Resources {
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = Resources.image(named: "tabbar_conversation_shadow")
    */
    final class LarkTag {
        static var newVersion: UIImage {
            BundleI18n.localizedImage(named: "new_version", in: BundleConfig.LarkTagBundle) ?? UIImage()
        }
    }
}
