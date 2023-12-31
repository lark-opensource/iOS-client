//
//  MeegoLinkConfig.swift
//  LarkMeego
//
//  Created by qsc on 2023/8/8.
//

import Foundation
import LarkSetting

struct MeegoLinkConfig: SettingDecodable {
    static var settingKey = UserSettingKey.make(userKeyLiteral: "meego_link_config")
    let flutterOnlyPath: [String]
}

extension MeegoLinkConfig {
    func isFlutterOnly(url: URL) -> Bool {
        let range = NSRange(location: 0, length: url.path.utf16.count)
        return flutterOnlyPath.contains { pattern in
            let regex = try? NSRegularExpression(pattern: pattern)
            let r = regex?.firstMatch(in: url.path, range: range)
            return r != nil
        }
    }
}
