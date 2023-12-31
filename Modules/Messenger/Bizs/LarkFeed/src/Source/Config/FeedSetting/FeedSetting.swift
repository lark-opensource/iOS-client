//
//  FeedSetting.swift
//  LarkFeed
//
//  Created by chaishenghua on 2022/8/10.
//

import Foundation
import LarkSetting
import RustPB
import LarkContainer

struct FeedGroupSetting {
    let feedGroupMap: [Feed_V1_FeedFilter.TypeEnum: Bool]
    func check(feedGroupPBType: Feed_V1_FeedFilter.TypeEnum) -> Bool {
        return feedGroupMap[feedGroupPBType] ?? false
    }
}

public struct FeedCardSetting {
    let feedCardMap: [RustPB.Basic_V1_FeedCard.EntityType: Bool]
    public func check(feedPreviewPBType: RustPB.Basic_V1_FeedCard.EntityType) -> Bool {
        return feedCardMap[feedPreviewPBType] ?? false
    }
}

// MARK: 分组setting能力
public struct FeedSetting {
    public let userResolver: UserResolver
    public init(_ userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    static let FeedGroupKey = "feedgroup"
    func getFeedGroupSetting(key: UserSettingKey) -> FeedGroupSetting {
        guard let settingJson = getSettingJson(key: key) else {
            return FeedGroupSetting(feedGroupMap: [:])
        }
        return getFeedGroupSetting(settingJson: settingJson)
    }

    func getFeedGroupSetting(settingJson: [String: Any]) -> FeedGroupSetting {
        guard let setting = settingJson[FeedSetting.FeedGroupKey] as? [String: Bool] else {
            return FeedGroupSetting(feedGroupMap: [:])
        }
        var feedGroupMap: [Feed_V1_FeedFilter.TypeEnum: Bool] = [:]
        for type in Feed_V1_FeedFilter.TypeEnum.allCases {
            if let enable = setting[String(type.rawValue)] {
                feedGroupMap[type] = enable
            }
        }
        return FeedGroupSetting(feedGroupMap: feedGroupMap)
    }
}

// MARK: feed card setting 能力
extension FeedSetting {
    static let FeedCardKey = "feedcard"
    func getFeedCardSetting(settingJson: [String: Any]) -> FeedCardSetting {
        getFeedCardSetting(settingJson: settingJson, feedcardKey: FeedSetting.FeedCardKey)
    }

    func getFeedCardSetting(settingJson: [String: Any], feedcardKey: String) -> FeedCardSetting {
        guard let setting = settingJson[feedcardKey] as? [String: Bool] else {
            return FeedCardSetting(feedCardMap: [:])
        }
        var feedCardMap: [RustPB.Basic_V1_FeedCard.EntityType: Bool] = [:]
        for type in RustPB.Basic_V1_FeedCard.EntityType.allCases {
            if let enable = setting[String(type.rawValue)] {
                feedCardMap[type] = enable
            }
        }
        return FeedCardSetting(feedCardMap: feedCardMap)
    }
}

// MARK: Base
extension FeedSetting {
    func getSettingJson(key: UserSettingKey) -> [String: Any]? {
        guard let setting = try? userResolver.settings.setting(with: key) else {
            let info = FeedBaseErrorInfo(type: .error(), errorMsg: "\(key)")
            FeedExceptionTracker.Setting.cloudSetting(node: .getSettingJson, info: info)
            return nil
        }
        if let data = try? JSONSerialization.data(withJSONObject: setting, options: []) {
            let str = String(data: data, encoding: String.Encoding.utf8)
            FeedContext.log.info("feedlog/setting/\(key). \(String(describing: str))")
        } else {
            FeedContext.log.info("feedlog/setting/\(key). \(setting)")
        }
        return setting
    }

    func deserialize<T>(key: UserSettingKey, entity: T.Type) -> Decodable? where T: Decodable {
        if let settingConfig = try? userResolver.settings.setting(
            with: key) {
            let jsonDecoder = JSONDecoder()
            guard let jsonData = try? JSONSerialization.data(withJSONObject: settingConfig, options: []) else { return nil }
            guard let model = try? jsonDecoder.decode(entity, from: jsonData) else { return nil }
            return model
        }
        return nil
    }
}
