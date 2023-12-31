//
//  Options.swift
//  LarkResource
//
//  Created by 李晨 on 2020/2/20.
//

import Foundation

public typealias OptionsInfo = [OptionsInfoItem]

extension Array where Element == OptionsInfoItem {
    static let empty: OptionsInfo = []
}

public enum OptionsInfoItem {
    /// 自定义额外的索引表，优先级高于全局默认索引, 数组中索引优先级依次降低
    case extraIndexTables([IndexTable])
    /// 自定义额外的索引表，优先级低于全局默认索引, 数组中索引优先级依次降低
    case baseIndexTables([IndexTable])
    /// 自定义转化资源 convertEntry
    case convertEntry([ConvertKey: ConvertibleEntryProtocol])
    /// 额外信息
    case addition([String: Any])
}

public struct OptionsInfoSet {

    public var extraIndexTables: [IndexTable] = []
    public var baseIndexTables: [IndexTable] = []
    public var converts: [ConvertKey: ConvertibleEntryProtocol] = [:]
    public var addition: [String: Any] = [:]

    public init(options: OptionsInfo) {
        for option in options {
            switch option {
            case .extraIndexTables(let extraIndexTables):
                self.extraIndexTables = extraIndexTables
            case .baseIndexTables(let baseIndexTables):
                self.baseIndexTables = baseIndexTables
            case .convertEntry(let converts):
                self.converts = converts
            case .addition(let addition):
                self.addition = addition
            }
        }
    }
}
