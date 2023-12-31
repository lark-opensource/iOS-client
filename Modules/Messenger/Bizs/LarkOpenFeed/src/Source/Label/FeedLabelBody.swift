//
//  FeedLabelBody.swift
//  LarkOpenFeed
//
//  Created by xiaruzhen on 2023/4/3.
//

import Foundation
import EENavigator

/// create label interface
public enum SettingLabelMode: Equatable {
    case create
    case edit
}

// 创建｜编辑 label
public struct SettingLabelBody: PlainBody {
    public static let pattern = "//client/feed/label/setting"
    public let mode: SettingLabelMode
    /// 关联的chat ID
    public var entityId: Int64?
    /// 编辑时候需要labelId
    public var labelId: Int64?
    /// 编辑时候需要labelName
    public var labelName: String?
    /// 创建成功场景需要回传
    public var successCallback: ((Int64) -> Void)?

    public init(mode: SettingLabelMode,
                entityId: Int64?,
                labelId: Int64?,
                labelName: String?,
                successCallback: ((Int64) -> Void)?) {
        self.mode = mode
        self.entityId = entityId
        self.labelId = labelId
        self.labelName = labelName
        self.successCallback = successCallback
    }
}

// label 设置列表
public struct SettingLabelListBody: PlainBody {
    public static let pattern = "//client/feed/label/setting_label_list"
    /// 关联的chat ID
    public var entityId: Int64
    /// 当前挂的label
    public var labelIds: [Int64]

    public init(entityId: Int64, labelIds: [Int64]) {
        self.entityId = entityId
        self.labelIds = labelIds
    }
}

// 添加item到label
public struct AddItemInToLabelBody: PlainBody {
    public static let pattern = "//client/feed/label/addItem"
    public var feedId: Int64
    public var infoCallback: ((SettingLabelMode, Bool) -> Void)?
    public init(feedId: Int64,
                infoCallback: ((SettingLabelMode, Bool) -> Void)?) {
        self.feedId = feedId
        self.infoCallback = infoCallback
    }
}

// 添加item到label(picker)
public struct AddItemInToLabelPickerBody: PlainBody {
    public static let pattern = "//client/feed/label/addItemPicker"

    public let labelId: Int64
    public let disabledSelectedIds: Set<String>

    public init(labelId: Int64,
                disabledSelectedIds: Set<String>) {
        self.labelId = labelId
        self.disabledSelectedIds = disabledSelectedIds
    }
}
