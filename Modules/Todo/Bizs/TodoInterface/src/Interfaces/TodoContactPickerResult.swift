//
//  TodoContactPickerResult.swift
//  TodoInterface
//
//  Created by wangwanxin on 2023/1/3.
//

import Foundation

public struct TodoContactPickerResult: Equatable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    public let identifier: String
    public var name: String = ""
    public var avatarKey: String = ""

    public init(identifier: String, name: String = "", avatarKey: String = "") {
        self.identifier = identifier
        self.name = name
        self.avatarKey = avatarKey
    }

}
