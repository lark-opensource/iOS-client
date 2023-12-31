//
//  AvatarImageConfig.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/4/13.
//

import Foundation
import LKCommonsLogging
import LarkSetting

public struct AvatarImageConfig {
    /// 屏幕像素密度，也即 UIScreen.Scale
    public enum Dpr {
        /// [0, 1.0]
        case low
        /// (1.0, 2.0]
        case middle
        /// (2.0, 3.0]
        case high

        init(scale: CGFloat) {
            switch scale {
            case 0...1:
                self = .low
            case 1...2:
                self = .middle
            case 2...3:
                self = .high
            default:
                self = .low
            }
        }
    }

    public struct DprConfig {
        public let sizeLow: Int
        public let sizeHigh: Int
        public let downloadSize: Int
        public let preloadSize: Int

        init(sizeLow: Int, sizeHigh: Int, downloadSize: Int, preloadSize: Int) {
            self.sizeLow = sizeLow
            self.sizeHigh = sizeHigh
            self.downloadSize = downloadSize
            self.preloadSize = preloadSize
        }

        init?(config: Any?) {
            guard let config = config as? [String: Int] else {
                return nil
            }
            sizeLow = config["dp_size_low"] ?? 0
            sizeHigh = config["dp_size_high"] ?? 0
            downloadSize = config["download_size"] ?? 0
            preloadSize = config["preload_size"] ?? 0
        }
    }

    public enum AvatarImageSize: String {
        case thumb = "th"
        case middle = "mid"
        case big = "hd"
    }

    static let logger = Logger.log(AvatarImageConfig.self, category: "AvatarConfig")
    public static let sizeConfigKey = UserSettingKey.make(userKeyLiteral: "avatar_size_config")
    public static let avatarConfigKey = UserSettingKey.make(userKeyLiteral: "avatar_config")

    public private(set) var defaultPrefix: String = "default-avatar_"
    // 字节跳动租户id和系统消息机器人id都为1，导致头像冲突，需要下发一份冲突的id配置，这些id仍以avatarKey为文件名
    public private(set) var conflictIDs: [Int64] = [1]
    public var currentDpr: Dpr {
        return Dpr(scale: UIScreen.main.scale)
    }
    public private(set) var dprConfigs: [AvatarImageSize: DprConfig] = [:]

    public init() {
        buildDefaultConfig()
    }

    public init(dprConfig: [String: Any], keyAndIdConfig: [String: Any]) {
        buildKeyAndIdConfig(keyAndIdConfig)
        switch currentDpr {
        case .low: buildDprConfig(dprConfig["dpr_low"])
        case .middle: buildDprConfig(dprConfig["dpr_middle"])
        case .high: buildDprConfig(dprConfig["dpr_high"])
        }
    }

    private mutating func buildKeyAndIdConfig(_ from: [String: Any]) {
        guard let prefix = from["default_avatar_key_prefix"] as? String,
              let ids = from["conflict_entity_ids"] as? [Int64] else {
                  AvatarImageConfig.logger.error("buildKeyAndIdConfig error, \(from)")
            return
        }
        defaultPrefix = prefix
        conflictIDs = ids
    }

    private mutating func buildDprConfig(_ from: Any?) {
        guard let dict = from as? [String: Any],
              let thumb = DprConfig(config: dict["thumb"]),
              let middle = DprConfig(config: dict["middle"]),
              let big = DprConfig(config: dict["big"]) else {
            AvatarImageConfig.logger.error("buildDprConfig error, \(String(describing: from))")
            return
        }
        dprConfigs[.thumb] = thumb
        dprConfigs[.middle] = middle
        dprConfigs[.big] = big
    }

    // 默认配置
    private mutating func buildDefaultConfig() {
        defaultPrefix = "default-avatar_"
        conflictIDs = [1]
        // disable-lint: magic number
        switch currentDpr {
        case .low:
            dprConfigs[.thumb] = DprConfig(sizeLow: 0, sizeHigh: 32, downloadSize: 32, preloadSize: 0)
            dprConfigs[.middle] = DprConfig(sizeLow: 33, sizeHigh: 79, downloadSize: 48, preloadSize: 32)
            dprConfigs[.big] = DprConfig(sizeLow: 80, sizeHigh: 320, downloadSize: 320, preloadSize: 32)
        case .middle:
            dprConfigs[.thumb] = DprConfig(sizeLow: 0, sizeHigh: 32, downloadSize: 64, preloadSize: 0)
            dprConfigs[.middle] = DprConfig(sizeLow: 33, sizeHigh: 79, downloadSize: 96, preloadSize: 64)
            dprConfigs[.big] = DprConfig(sizeLow: 80, sizeHigh: 320, downloadSize: 1080, preloadSize: 64)
        case .high:
            dprConfigs[.thumb] = DprConfig(sizeLow: 0, sizeHigh: 32, downloadSize: 96, preloadSize: 0)
            dprConfigs[.middle] = DprConfig(sizeLow: 33, sizeHigh: 79, downloadSize: 128, preloadSize: 96)
            dprConfigs[.big] = DprConfig(sizeLow: 80, sizeHigh: 320, downloadSize: 1080, preloadSize: 96)
        }
        // enable-lint: magic number
    }
}

public extension AvatarImageConfig {
    func transform(sizeType: SizeType) -> AvatarImageSize {
        switch sizeType {
        case .size(let maxSize): return transform(maxSize: maxSize)
        case .thumb: return .thumb
        case .middle: return .middle
        case .big: return .big
        }
    }

    func transform(maxSize: CGFloat) -> AvatarImageSize {
        if isThumb(maxSize: maxSize) { return .thumb } else if isMiddle(maxSize: maxSize) { return .middle } else if isBig(maxSize: maxSize) { return .big }
        return .middle
    }

    func transformDic(entityId: String, avatarKey: String, size: SizeType) -> [String: Any] {
        var addition = [String: Any]()
        addition["entityId"] = entityId
        let fileName = isDefault(key: avatarKey) || isConflict(entityId: entityId) ? avatarKey : entityId.bt.md5
        addition["fileName"] = fileName
        let cacheKey = avatarKey.appending("_").appending(transform(sizeType: size).rawValue)
        addition["cacheKey"] = cacheKey // 不同尺寸的头像process之后存储在同一目录，需要拼接size后缀区分
        addition["isOrigin"] = transform(sizeType: size) == .big
        return addition
    }

    func isThumb(maxSize: CGFloat) -> Bool {
        let size = Int(maxSize)
        if let config = dprConfigs[.thumb] {
            return size >= config.sizeLow && size <= config.sizeHigh
        }
        return false
    }

    func isMiddle(maxSize: CGFloat) -> Bool {
        let size = Int(maxSize)
        if let config = dprConfigs[.middle] {
            return size >= config.sizeLow && size <= config.sizeHigh
        }
        return false
    }

    func isBig(maxSize: CGFloat) -> Bool {
        let size = Int(maxSize)
        if let config = dprConfigs[.big] {
            return size >= config.sizeLow // big图片无上限
        }
        return false
    }

    func isDefault(key: String) -> Bool {
        return key.hasPrefix(defaultPrefix)
    }

    func isConflict(entityId: String) -> Bool {
        if let id = Int64(entityId) {
            return conflictIDs.contains(id)
        }
        return false
    }
}
