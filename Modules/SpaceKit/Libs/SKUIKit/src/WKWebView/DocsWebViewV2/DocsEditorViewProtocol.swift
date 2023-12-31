//
//  DocsEditorViewProtocol.swift
//  SKUIKit
//
//  Created by chenhuaguan on 2021/7/1.
//

import Foundation

public protocol EditorConfigDelegate: AnyObject {
    /// request header
    var editorRequestHeaders: [String: String] { get }
}

public enum EditorViewType: Int {
    case webView
    case native
}

/// 再抽象一层，editor不一定由webview实现，也可以有native编辑器来实现
public protocol DocsEditorViewProtocol: UIView {

    var editorViewType: EditorViewType { get }

    var skEditorViewInputAccessory: SKInputAccessory { get }

    func becomeFirst() -> Bool

    func resign() -> Bool

    func setSKResponderDelegate(_ delegate: DocsEditorViewResponderDelegate?)

    func setSKEditorConfigDelegate(_ delegate: EditorConfigDelegate?)

    func setSKGestureDelegate(_ delegate: EditorViewGestureDelegate?)
}
