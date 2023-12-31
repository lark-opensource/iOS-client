//
//  InlineAIJSService.swift
//  LarkInlineAI
//
//  Created by GuoXinyi on 2023/5/11.
//

import Foundation

struct InlineAIJSService: Hashable, RawRepresentable {
    var rawValue: String
    init(_ str: String) {
        self.rawValue = str
    }

    init(rawValue: String) {
        self.init(rawValue)
    }

    static func == (lhs: InlineAIJSService, rhs: InlineAIJSService) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

extension InlineAIJSService {
    static let renderContent    = InlineAIJSService("biz.render.AIContent")
    static let renderComplete   = InlineAIJSService("biz.render.AIContent.complete")
    static let showMenu         = InlineAIJSService("biz.selection.showMenu") // 显示气泡菜单
    static let closeMenu        = InlineAIJSService("biz.selection.closeMenu") // 关闭气泡菜单
    static let longPress        = InlineAIJSService("biz.selection.longPress") // 长按选区
    static let setScrollStatus  = InlineAIJSService("biz.selection.setScrollStatus") // 禁止滚动与恢复
    static let openLink         = InlineAIJSService("biz.render.AIContent.openLink")
}
