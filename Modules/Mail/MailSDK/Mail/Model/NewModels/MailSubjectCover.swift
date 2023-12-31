//
//  MailSubjectCover.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/5/6.
//

import Foundation
import UniverseDesignColor

struct MailSubjectCover: Codable, Equatable {
    let token: String
    var subjectColorStr: String

    enum CodingKeys: String, CodingKey {
        case token = "token"
        case subjectColorStr = "subjectColorHex"
    }
    
    lazy var subjectColor: UIColor = {
        return UIColor.ud.rgb(subjectColorStr)
    }()

    /// 转化为 json
    var coverInfo: String {
        guard let data = try? JSONEncoder().encode(self),
              let string = String(data: data, encoding: .utf8)
        else {
            MailLogger.error("Failed to encode mail cover object")
            return ""
        }
        return string
    }

    /// 从  json 初始化
    static func decode(from string: String) -> MailSubjectCover? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(MailSubjectCover.self, from: data)
    }
}
