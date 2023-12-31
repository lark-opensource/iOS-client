//
//  MediaServiceToastConfig.swift
//  ByteViewSetting
//
//  Created by fakegourmet on 2023/5/22.
//

import Foundation

// disable-lint: magic number
public struct MediaServiceToastConfig: Decodable {

    public struct MediaServiceSystemConfig: Decodable {
        public let major: Int
        public let minor: Int
        public let patch: Int

        // nolint-next-line: magic number
        static let `default` = MediaServiceSystemConfig(major: 99, minor: 0, patch: 0)

        enum CodingKeys: String, CodingKey {
            case major
            case minor
            case patch
        }

        public var systemVersion: OperatingSystemVersion {
            OperatingSystemVersion(majorVersion: major, minorVersion: minor, patchVersion: patch)
        }
    }

    public let max: MediaServiceSystemConfig
    public let min: MediaServiceSystemConfig

    enum CodingKeys: String, CodingKey {
        case max
        case min
    }

    static let `default`: MediaServiceToastConfig = {
        return MediaServiceToastConfig(max: .default, min: .default)
    }()
}
