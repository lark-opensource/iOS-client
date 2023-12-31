//
//  ChatWidget.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/1/9.
//

import Foundation
import RustPB

// 端上使用的 Widget 数据模型
/// PB 字段映射 + 各业务自定义数据
public class ChatWidget {
    /// widget pb 上的字段
    public let id: Int64
    public let type: RustPB.Im_V1_ChatWidget.WidgetType
    /// widget 各业务方自己的存储区域
    public var content: ChatWidgetContent? {
        get {
            os_unfair_lock_lock(&unfairLock)
            defer {
                os_unfair_lock_unlock(&unfairLock)
            }
            return _content
        }
        set {
            os_unfair_lock_lock(&unfairLock)
            _content = newValue
            os_unfair_lock_unlock(&unfairLock)
        }
    }
    private var unfairLock = os_unfair_lock_s()
    private var _content: ChatWidgetContent?

    public init(
        id: Int64,
        type: RustPB.Im_V1_ChatWidget.WidgetType,
        content: ChatWidgetContent?
    ) {
        self.id = id
        self.type = type
        self.content = content
    }

    public func copy() -> ChatWidget {
        let widget = ChatWidget(id: self.id, type: self.type, content: content?.copy())
        return widget
    }
}

// Widget 各业务自定义数据
public protocol ChatWidgetContent {
    func copy() -> Self
}
