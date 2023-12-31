//
//  LarkLiveTheme.swift
//  LarkLive
//
//  Created by yangyao on 2021/12/10.
//

import Foundation

enum ThemeColor: Int, Codable {
    case `default` = 0
    case light = 1
    case dark = 2
}
struct LarkLiveTheme: Codable {
    var themeColor: ThemeColor?
    
    enum CodingKeys: String, CodingKey {
        case themeColor = "theme_color"
    }
}
