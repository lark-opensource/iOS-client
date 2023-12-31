//
//  AnimationConfig.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/12/8.
//

import Foundation

// disable-lint: magic number
public struct AnimationConfig {
    public let configs: [Keys: AnimationConfigItem]

    public enum Keys: String {
        case mic_volume
        case unknown
    }

    static let `default`: AnimationConfig = {
        let configs: [AnimationConfigItem] = [
            // nolint-next-line: magic number
            AnimationConfigItem(key: .mic_volume, enabled: true, framerate: 15)
        ]
        return AnimationConfig(configs: Dictionary(uniqueKeysWithValues: configs.map { ($0.key, $0) }))
    }()
}

public struct AnimationConfigItem: Decodable {
    public let key: AnimationConfig.Keys
    public let enabled: Bool
    public let framerate: CGFloat

    enum CodingKeys: CodingKey {
        case key
        case enabled
        case framerate
    }

    public init(key: AnimationConfig.Keys, enabled: Bool, framerate: CGFloat) {
        self.key = key
        self.enabled = enabled
        self.framerate = framerate
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.key = AnimationConfig.Keys(rawValue: try c.decode(String.self, forKey: .key)) ?? .unknown
        self.enabled = try c.decode(Bool.self, forKey: .enabled)
        self.framerate = try c.decode(CGFloat.self, forKey: .framerate)
    }
}

extension AnimationConfig: Decodable {

    public init(from decoder: Decoder) throws {
        var configs: [AnimationConfigItem] = []
        var c = try decoder.unkeyedContainer()
        for _ in 0..<(c.count ?? 0) {
            let config = try c.decode(AnimationConfigItem.self)
            configs.append(config)
        }
        self.configs = Dictionary(uniqueKeysWithValues: configs.map { ($0.key, $0) })
    }
}
