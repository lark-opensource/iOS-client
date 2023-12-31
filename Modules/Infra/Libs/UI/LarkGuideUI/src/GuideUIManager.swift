//
//  GuideUIManager.swift
//  LarkGuideUI
//
//  Created by zhenning on 2020/6/4.
//

import Foundation
import UIKit
import LarkExtensions

public final class GuideUIManager {
    private var bubbleController: GuideBubbleController?
    private var dialogController: GuideDialogController?
    private var customController: GuideCustomViewController?
    private lazy var window: UIWindow = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.statusBar.rawValue - 1.0)
        window.backgroundColor = UIColor.ud.N00
        window.isHidden = true
        window.windowIdentifier = "LarkGuideUI.guideWindow"
        return window
    }()

    public init() { }

// MARK: - Bubble

    /// 开始展示气泡组件
    /// @params: makeKey 是否makeKeyWindow,默认设为true
    public func displayBubble(bubbleType: BubbleType,
                              customWindow: UIWindow? = nil,
                              makeKey: Bool = true,
                              viewTapHandler: GuideViewTapHandler? = nil,
                              dismissHandler: (() -> Void)? = nil) {
        if Thread.isMainThread {
            self.showBubbles(bubbleType: bubbleType,
                             customWindow: customWindow,
                             makeKey: makeKey,
                             viewTapHandler: viewTapHandler,
                             dismissHandler: dismissHandler)
        } else {
            DispatchQueue.main.async {
                self.showBubbles(bubbleType: bubbleType,
                                 customWindow: customWindow,
                                 makeKey: makeKey,
                                 viewTapHandler: viewTapHandler,
                                 dismissHandler: dismissHandler)
            }
        }
    }

    private func showBubbles(bubbleType: BubbleType,
                             customWindow: UIWindow? = nil,
                             makeKey: Bool,
                             viewTapHandler: GuideViewTapHandler? = nil,
                             dismissHandler: (() -> Void)? = nil) {
        let viewModel = GuideBubbleViewModel(bubbleType: bubbleType)
        self.bubbleController = GuideBubbleController(viewModel: viewModel)
        self.bubbleController?.maskTapHandler = { [weak self] in
            self?.closeBubbles(customWindow: customWindow)
        }
        self.bubbleController?.bubbleViewTapHandler = viewTapHandler
        self.bubbleController?.dismissHandler = dismissHandler
        self.bubbleController?.showInWindow(to: customWindow ?? self.window, makeKey: makeKey)
    }

    func closeBubbles(customWindow: UIWindow? = nil) {
        bubbleController?.removeFromWindow(window: customWindow ?? self.window)
    }

// MARK: - Dialog

    /// 开始展示Dialog组件
    /// @params: makeKey 是否makeKeyWindow,默认设为true
    public func displayDialog(dialogConfig: DialogConfig,
                              customWindow: UIWindow? = nil,
                              makeKey: Bool = true,
                              dismissHandler: (() -> Void)? = nil) {
        dialogController = GuideDialogController(dialogConfig: dialogConfig)
        dialogController?.dismissHandler = dismissHandler
        self.bubbleController?.maskTapHandler = { [weak self] in
            self?.closeDialog(customWindow: customWindow)
        }

        if Thread.isMainThread {
            dialogController?.showInWindow(to: customWindow ?? self.window, makeKey: makeKey)
        } else {
            DispatchQueue.main.async {
                self.dialogController?.showInWindow(to: customWindow ?? self.window, makeKey: makeKey)
            }
        }
    }

    func closeDialog(customWindow: UIWindow? = nil) {
        dialogController?.removeFromWindow(window: customWindow ?? self.window)
    }

// MARK: - Custom

    /// 开始展示Custom组件
    /// @params: makeKey 是否makeKeyWindow,默认设为true
    public func displayCustomView(customConfig: GuideCustomConfig,
                             customWindow: UIWindow? = nil,
                             makeKey: Bool = true,
                             viewTapHandler: GuideViewTapHandler? = nil,
                             dismissHandler: (() -> Void)? = nil) {
        customController = GuideCustomViewController(customConfig: customConfig)
        customController?.dismissHandler = dismissHandler
        customController?.maskTapHandler = { [weak self] in
            self?.closeCustomView(customWindow: customWindow)
        }

        if Thread.isMainThread {
            customController?.showInWindow(to: customWindow ?? self.window, makeKey: makeKey)
        } else {
            DispatchQueue.main.async {
                self.customController?.showInWindow(to: customWindow ?? self.window, makeKey: makeKey)
            }
        }
    }

    func closeCustomView(customWindow: UIWindow? = nil) {
        customController?.removeFromWindow(window: customWindow ?? self.window)
    }
}

extension GuideUIManager {

    public func closeGuideViewsIfNeeded(customWindow: UIWindow? = nil) {
        closeBubbles(customWindow: customWindow)
        closeDialog(customWindow: customWindow)
        closeCustomView(customWindow: customWindow)
    }
}
