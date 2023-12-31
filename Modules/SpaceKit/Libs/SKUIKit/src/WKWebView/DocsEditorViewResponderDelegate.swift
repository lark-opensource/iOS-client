//
//  DocsEditorViewResponderDelegate.swift
//  SKUIKit
//
//  Created by chensi(陈思) on 2022/3/22.
//  


import SKFoundation
import WebKit
import LarkRustHTTP

public protocol DocsEditorViewResponderDelegate: AnyObject {
    /// 当请求canBecomeFirstResponder时调用(系统并不会询问此属性，故该逻辑可用性未知)
    func docsEditorViewShouldBecomeFirstResponder(_ editorView: DocsEditorViewProtocol) -> Bool
    /// 当请求canResignFirstResponder时调用(系统并不会询问此属性，故该逻辑可用性未知)
    func docsEditorViewShouldResignFirstResponder(_ editorView: DocsEditorViewProtocol) -> Bool

    func docsEditorViewWillBecomeFirstResponder(_ editorView: DocsEditorViewProtocol)
    func docsEditorViewDidBecomeFirstResponder(_ editorView: DocsEditorViewProtocol)
    func docsEditorViewWillResignFirstResponder(_ editorView: DocsEditorViewProtocol)
    func docsEditorViewDidResignFirstResponder(_ editorView: DocsEditorViewProtocol)
}

public extension DocsEditorViewResponderDelegate {
    func docsEditorViewShouldBecomeFirstResponder(_ editorView: DocsEditorViewProtocol) -> Bool { return true }
    func docsEditorViewShouldResignFirstResponder(_ editorView: DocsEditorViewProtocol) -> Bool { return true }
    func docsEditorViewWillBecomeFirstResponder(_ editorView: DocsEditorViewProtocol) { }
    func docsEditorViewDidBecomeFirstResponder(_ editorView: DocsEditorViewProtocol) { }
    func docsEditorViewWillResignFirstResponder(_ editorView: DocsEditorViewProtocol) { }
    func docsEditorViewDidResignFirstResponder(_ editorView: DocsEditorViewProtocol) { }
}
