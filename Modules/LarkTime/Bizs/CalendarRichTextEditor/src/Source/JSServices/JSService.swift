//
//  JSService.swift
//  RichTextEditor
//
//  Created by chenhuaguan on 2020/6/29.
//

import Foundation

struct JSService: Hashable, RawRepresentable {
    var rawValue: String
    init(_ str: String) {
        self.rawValue = str
    }

    init(rawValue: String) {
        self.init(rawValue)
    }

    static func == (lhs: JSService, rhs: JSService) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

// MARK: - util
extension JSService {
    static let rtUtilLogger = JSService("biz.util.logger")
    static let rtUtilMonitor = JSService("biz.util.monitor")
    static let rtNotifyHeight = JSService("biz.notify.sendChangedHeight")
    static let rtNotifyReady = JSService("biz.notify.ready")
    static let rtOnKeyboardChanged = JSService("biz.util.onKeyboardChanged")
    static let rtUtilKeyBoard = JSService("biz.util.showKeyboard")
    static let rtNavToolBar = JSService("biz.navigation.setToolBar")
    static let rtOpenUrl = JSService("biz.util.openUrl")

    static let richTextResizeY = JSService("biz.core.resizeY")
    static let richTextSetStyle = JSService("biz.util.setStyle")
    static let richTextGetContent = JSService("biz.core.getContent")
    static let richTextGetHtml = JSService("biz.core.getHtml")
    static let richTextGetRect = JSService("biz.core.getRect")
    static let richTextRender = JSService("biz.core.render")
    static let richTextGetText = JSService("biz.core.getText")
    static let richTextSetContent = JSService("biz.core.setContent")
    static let richTextClearContent = JSService("biz.core.clearContent")
    static let richTextIsChanged = JSService("biz.core.isChanged")
    static let richTextSetEditable = JSService("biz.core.setEditable")
    static let richTextSetPlaceholder = JSService("biz.core.setPlaceholder")

    // clipboard
    static let rtClipboardSetContent = JSService("biz.clipboard.setContent")
    static let rtClipboardGetContent = JSService("biz.clipboard.getContent")

    // onPasteCallBack
    static let rtOnPasteDocs = JSService("biz.core.onPasteDocs")

    static let rtDocsAutoAuthFG = JSService("biz.core.isFeatureEnable")
}

struct JSCallBack: Hashable, RawRepresentable {
    var rawValue: String
    init(_ str: String) {
        self.rawValue = str
    }

    init(rawValue: String) {
        self.init(rawValue)
    }

    static func == (lhs: JSCallBack, rhs: JSCallBack) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
