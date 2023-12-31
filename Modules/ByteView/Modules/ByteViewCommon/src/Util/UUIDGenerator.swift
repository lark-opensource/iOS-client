//
//  UUIDGenerator.swift
//  ByteViewCommon
//
//  Created by kiri on 2022/8/24.
//

import Foundation

public final class UUIDGenerator {
    public static let defaultCharset = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    private static let calendar = Calendar(identifier: .gregorian)

    private let charset: String
    private let count: Int
    private let strict: Bool
    /// - parameters:
    ///     - count: 生成的UUID长度，默认为`5`
    ///     - charset: UUID可用的字符集, 默认为`0-9a-zA-Z`
    ///     - strict: 是否严格唯一，默认为`true`
    public init(count: Int = 6, charset: String = UUIDGenerator.defaultCharset, strict: Bool = true) {
        assert(!charset.isEmpty, "charset isEmpty")
        if charset.count > 31 {
            self.charset = charset
        } else {
            /// 为了用日历
            var cs = charset
            while cs.count < 32 {
                cs += charset
            }
            self.charset = cs
        }
        self.count = count
        self.strict = strict
    }

    @RwAtomic
    private var uuidCache: Set<String> = []
    /// return sort uuid string, unique in current launch.
    public func generate() -> String {
        let date = Self.calendar.dateComponents([.day, .hour], from: Date())
        for _ in 0..<5 {
            var chars: [Character] = []
            if count > 4 {
                chars.append(charset[charset.index(charset.startIndex, offsetBy: date.day!)])
                chars.append(charset[charset.index(charset.startIndex, offsetBy: date.hour!)])
                let randomCount = count - 2
                for _ in 0..<randomCount {
                    chars.append(charset.randomElement()!)
                }
            } else {
                for _ in 0..<count {
                    chars.append(charset.randomElement()!)
                }
            }
            let uuid = String(chars)
            if !strict {
                return uuid
            }
            if !uuidCache.contains(uuid) {
                uuidCache.insert(uuid)
                return uuid
            }
        }
        Logger.util.error("generate contextId failed, use UUID() replaced.")
        return UUID().uuidString
    }
}
