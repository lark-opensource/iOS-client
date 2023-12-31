//
//  Resources.swift
//  LarkSceneManagerDev
//
//  Created by Saafo on 2021/3/26.
//

import Foundation
import UIKit

class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named) ?? UIImage()
    }
    static let iconHome = Resources.image(named: "icon_sidebar_home")
    static let iconChat = Resources.image(named: "icon_chat_filled")
    static let iconDoc = Resources.image(named: "icon_doc_colorful")
}
