//
//  UDFont+Token.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/5/18.
//

import Foundation
import UniverseDesignFont
import UIKit

extension UDFont {
    /// 网络状态字体
    static var netStatusBarFont: UIFont {
        // 字体使用 UD token 初始化
        // swiftlint:disable init_font_with_token
        return UIFont.systemFont(ofSize: 14.0, weight: .medium)
        // swiftlint:enable init_font_with_token
    }
}
