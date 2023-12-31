//
//  DocsRichTextView+Interface.swift
//  SpaceKit
//
//  Created by nine on 2019/4/22.
//

import UIKit
import Foundation

// MARK: Editor-based feature impl
extension DocsRichTextView: DocsRichTextViewAPI {

    public var view: UIView { return self }

    public func setDomains(domainPool: [String], spaceApiDomain: String, mainDomain: String) {
        Logger.info("RichTextView.setDomains.domainPool=\(domainPool),spaceApiDomain=\(spaceApiDomain),mainDomain=\(mainDomain)")
        self.injectDomain(domainPool: domainPool, spaceApiDomain: spaceApiDomain, mainDomain: mainDomain)
    }

    public func startObservingKeyboard() {
        startMonitorKeyboard()
    }

    public func stopObservingKeyboard() {
        stopMonitorKeyboard()
    }

    public func getDocData(completion: @escaping (String?, Error?) -> Void) {
        editor.getDocData(completion: completion)
    }

    public func getDocHtml(completion: @escaping (String?, Error?) -> Void) {
        editor.getDocHtml(completion: completion)
    }

    public func set(content: String, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        editor.set(content: content, success: success, fail: fail)
    }

    public func setDoc(data: String, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        editor.setDoc(data: data, success: success, fail: { _ in
            self.retry(data, success: success, fail: fail)
        })
    }

    public func checkKeep(completion: @escaping (Bool?, Error?) -> Void) {
        editor.checkKeep(completion: completion)
    }

    public func setStyle(_ style: DocsRichTextParam.AditStyle, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        editor.setStyle(style, success: success, fail: fail)
        themeMonitor.refreshStyle()
    }

    public func getContent(completion: @escaping (String?, Error?) -> Void) {
        editor.getContent(completion: completion)
    }

    public func getHtml(completion: @escaping (String?, Error?) -> Void) {
        editor.getHtml(completion: completion)
    }

    public func render(_ content: String, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        editor.render(content, success: success, fail: fail)
    }

    public func getRect(completion: @escaping (String?, Error?) -> Void) {
        editor.getRect(completion: completion)
    }

    public func clearContent(success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        editor.clearContent(success: success, fail: fail)
    }

    public func getIsChanged(completion: @escaping (Bool?, Error?) -> Void) {
        editor.getIsChanged(completion: completion)
    }

    public func setPlaceholder(_ props: DocsRichTextParam.PlaceholderProps, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        editor.setPlaceholder(props, success: success, fail: fail)
    }

    public func getText(completion: @escaping (String?, Error?) -> Void) {
        editor.getText(completion: completion)
    }

    public func setEditable(_ enable: Bool, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        editor.setEditable(enable, success: success, fail: fail)
    }

    public func setTextMenu(type: RichTextContentViewMenuType) {
        self.contentView.menuType = type
    }

    public func setCanScroll(_ canScroll: Bool) {
        contentView.webView.scrollView.isScrollEnabled = canScroll
    }

    public func setThemeConfig(_ config: ThemeConfig) {
        themeMonitor.themeConfig = config
    }

    public func becomeFirstResponder() {
        becomeFirst()
    }
}

// ↓ 不要信他 :) ，1.0的bug至今都没fix。如果需要使用bridge，请参考2.0版的 `RTEditorV2`
// 为了fix日历白屏问题，目前暂时先这么写，后期会收敛到sdk，前端会优化预加载
extension DocsRichTextView {
    private func retry(_ data: String, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.editor.setDoc(data: data, success: success, fail: { (_) in
                self.retry(data, success: success, fail: fail)
            })
        }
    }
}
