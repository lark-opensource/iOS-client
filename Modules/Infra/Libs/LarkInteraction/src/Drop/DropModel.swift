//
//  DropModel.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/25.
//

import Foundation

public enum DropItemType {
    /// Class 类型 item
    case classType(NSItemProviderReading.Type)
    /// 通过 UTI 获取 Item Data 类型数据
    case UTIDataType(String)
    /// 通过 UTI 获取 Item URL 类型数据
    case UTIURLType(String)
}

public enum DropItemHandleTactics {
    case onlySupportTypes       // dropItems 全部在支持的 type 中，才可以响应
    case containSupportTypes    // dropItems 存在支持的 type，就可以响应
}

public struct DropItemOptions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// 只支持响应一个 item
    public static let onlySupportOneItem = DropItemOptions(rawValue: 1)
    /// 只支持当前 app 的 item
    public static let onlySupportCurrentApplication = DropItemOptions(rawValue: 1 << 1)
    /// 只支持当前 app 的 item
    public static let notSupportCurrentApplication = DropItemOptions(rawValue: 1 << 2)
}

public struct DropItemValue {
    /// 文件名
    public var suggestedName: String
    /// item 数据
    public var itemData: DropItemData
}

public enum DropItemData {
    case classType(NSItemProviderReading)
    case UTIDataType(String, Data)
    case UTIURLType(String, URL)
}
