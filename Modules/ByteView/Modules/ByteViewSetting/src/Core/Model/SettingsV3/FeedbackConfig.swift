//
//  FeedbackConfig.swift
//  ByteView
//
//  Created by wulv on 2023/2/24.
//

import Foundation
import ByteViewCommon

struct FeedbackSubItem: Decodable {
    let key: String
    let i18nKey: String

    private enum CodingKeys: String, CodingKey {
        case key
        case i18nKey // i18n_key
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        key = try values.decode(String.self, forKey: .key)
        i18nKey = try values.decode(String.self, forKey: .i18nKey)
    }
}

struct FeedbackItem: Decodable {
    let key: String
    let i18nKey: String
    let subKeys: [FeedbackSubItem]

    private enum CodingKeys: String, CodingKey {
        case key
        case i18nKey // i18n_key
        case subKeys // "sub_keys"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        key = try values.decode(String.self, forKey: .key)
        i18nKey = try values.decode(String.self, forKey: .i18nKey)
        subKeys = try values.decode([FeedbackSubItem].self, forKey: .subKeys)
        Logger.setting.info("vc_feedback_issue_type_config, key: \(key), i18nKey: \(i18nKey), subKeys: \(subKeys)")
    }
}

struct FeedbackConfig {
    let items: [FeedbackItem]
    static let `default` = FeedbackConfig(items: [])
}

extension FeedbackConfig: Decodable {
    init(from decoder: Decoder) throws {
        var fbs: [FeedbackItem] = []
        var container = try decoder.unkeyedContainer()
        for _ in 0..<(container.count ?? 0) {
            let fb = try container.decode(FeedbackItem.self)
            fbs.append(fb)
        }
        items = fbs
    }
}
