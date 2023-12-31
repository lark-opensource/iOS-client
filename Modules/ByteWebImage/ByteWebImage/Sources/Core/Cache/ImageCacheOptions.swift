//
//  ImageCacheOptions.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/9/5.
//

import Foundation

public struct ImageCacheOptions: OptionSet, Sendable {

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    // swiftlint:disable operator_usage_whitespace
    public static let none: ImageCacheOptions = []
    public static let memory = ImageCacheOptions(rawValue: 1 << 0)
    public static let disk   = ImageCacheOptions(rawValue: 1 << 1)
    public static let all    = memory.union(disk)
    // swiftlint:enable operator_usage_whitespace
}

extension ImageCacheOptions {

    public var opposite: Self {
        .all.subtracting(self)
    }
}

extension ImageCacheOptions: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        switch self {
        case .memory: return "memory"
        case .disk: return "disk"
        case .all: return "all"
        default: return "unknown"
        }
    }

    public var debugDescription: String {
        description
    }
}

extension ImageCacheOptions: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
