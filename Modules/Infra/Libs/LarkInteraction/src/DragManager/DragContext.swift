//
//  DragContext.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/31.
//

import Foundation

public typealias DragContextInfo = (value: Any, identifier: String)

public struct DragContextKey: Hashable, ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    public var value: String

    public init(_ value: String) {
        self.value = value
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }

    public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        self.init(value)
    }

    public init(unicodeScalarLiteral value: StringLiteralType) {
        self.init(value)
    }
}

/// Drag context 环境变量
public struct DragContext {
    private var contextInfo: [DragContextKey: DragContextInfo]

    /// context 当前 id
    public var identifier: String {
        return contextInfo.filter { (_: DragContextKey, value: DragContextInfo) -> Bool in
            return !value.identifier.isEmpty
        }.sorted { (first, second) -> Bool in
            return first.key.value.compare(second.key.value) == .orderedAscending
        }.reduce("") { (result, value) -> String in
            var result = result
            let (key, info) = value
            if !result.isEmpty {
                result += "_"
            }
            return result + key.value + "_" + info.identifier
        }
    }

    public init() {
        self.init(contextInfo: [:])
    }

    init(contextInfo: [DragContextKey: DragContextInfo]) {
        self.contextInfo = contextInfo
    }

    /// 设置新的 context 值
    /// - Parameters:
    ///   - key: 数据唯一 id
    ///   - value: 环境数据 object 对象
    ///   - identifier: 此数据 object 的 identifier，如果这个 identifier 不为空
    ///     则此环境变量会影响当前 context 的 identifier
    ///     相同 context identifier 下 相同 viewTag 的 uiview 不支持重复拖拽
    public mutating func set(key: DragContextKey, value: Any, identifier: String) {
        contextInfo[key] = (value, identifier)
    }

    /// 通过 key 获取 context 内完整 value
    public func getInfo(key: DragContextKey) -> DragContextInfo? {
        return self.contextInfo[key]
    }
    /// 通过 key 获取 context 内 value
    public func getValue(key: DragContextKey) -> Any? {
        return self.getInfo(key: key)?.0
    }

    /// 通过 key 删除对应 value
    public mutating func remove(key: DragContextKey) {
        contextInfo[key] = nil
    }

    /// 合并返回新的 context
    public func merge(context: DragContext) -> DragContext {
        let contextInfo = self.contextInfo.merging(context.contextInfo) { $1 }
        return DragContext(contextInfo: contextInfo)
    }
}
