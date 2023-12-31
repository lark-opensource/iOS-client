//
//  MobileCode.swift
//  ByteViewNetwork
//
//  Created by kiri on 2023/6/21.
//

import Foundation

public struct MobileCode: Equatable, CustomStringConvertible {
    public let key: String
    /// 国家地区名
    public let name: String
    /// 国家地区手机码
    public let code: String
    /// 索引
    public let index: String

    public var isDefault: Bool = false

    public init(key: String, name: String, code: String, index: String) {
        self.key = key
        self.name = name
        self.code = code
        self.index = index
    }

    public static func emptyCode(_ key: String) -> MobileCode {
        self.init(key: key, name: "", code: "", index: "")
    }

    public var description: String {
        String(name: isDefault ? "[default] MobileCode" : "MobileCode", dropNil: true, [
            "key": key,
            "name": name,
            "code": code,
            "index": index
        ])
    }
}
