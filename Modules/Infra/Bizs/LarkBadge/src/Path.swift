//
//  NodeName.swift
//  LarkBadge
//
//  Created by KT on 2019/4/22.
//

import Foundation

@dynamicMemberLookup
public struct Path: PathRepresentable {

    // MARK: - Public
    public init() {
        self.init(value: "")
    }

    // Dynamic Member Lookup
    public subscript(dynamicMember member: String) -> Path {
        return Path(value: concat(self.value, with: member))
    }

    /// 由前缀构造路径
    ///
    /// - Parameters:
    ///   - prefix: 已经注册的前缀名
    ///   - identifies: 拼接id
    public func prefix(_ prefix: Path, with identifies: String...) -> Path {
        return Path(value: concat(self.value, with: (prefix.value + identifies.joined())))
    }

    /// 由参数构造路径
    ///
    /// - Parameter values: 参数
    /// - Returns: 路径
    public func raw(_ values: String...) -> Path {
        return Path(value: concat(self.value, with: values.joined()))
    }

    // MARK: - Private
    let value: String

    private init(value: String) {
        self.value = value
    }

    // 由Path转化为[NodeName]
    var nodeNames: [NodeName] {
        return self.value.components(separatedBy: ".")
    }

    // 拼接 "."
    private func concat(_ first: String, with second: String) -> String {
        if first.isEmpty { return second }
        return first + "." + second
    }
}

extension Path: Equatable {
    public static func == (lhs: Path, rhs: Path) -> Bool {
        return lhs.value == rhs.value
    }
}
