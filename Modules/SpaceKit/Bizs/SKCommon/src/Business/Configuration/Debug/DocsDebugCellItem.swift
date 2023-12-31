//
//  DocsSercetDebugCellItem.swift
//  Docs
//
//  Created by xurunkang on 2018/8/20.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

public enum DocsDebugCellType {
    case none
    case id
    case back
    case switchButton(isOn: Bool, tag: Int)
}

public struct DocsDebugCellItem {
    public let title: String
    public let detail: String?
    public let type: DocsDebugCellType

    public init(title: String, type: DocsDebugCellType = .none, detail: String? = nil) {
        self.title = title
        self.detail = detail
        self.type = type
    }
}
