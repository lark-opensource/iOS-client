//
//  LKAssetBrowserPlugin.swift
//  LarkAssetsBrowser
//
//  Created by Hayden Wang on 2022/11/14.
//

import Foundation
import UIKit

public final class LKAssetBrowserContext {
    public var actionInfo: ActionInfo
    public var currentAsset: LKAsset
    public weak var currentPage: LKAssetBrowserPage?
    public weak var assetBrowser: LKAssetBrowser?
    
    init(asset: LKAsset, page: LKAssetBrowserPage, browser: LKAssetBrowser, actionInfo: ActionInfo) {
        self.currentAsset = asset
        self.currentPage = page
        self.assetBrowser = browser
        self.actionInfo = actionInfo
    }

    public struct ActionInfo {
        // 是否触发自底部按钮
        public var ifFromBottomButton: Bool
        // ActionSheet 是否来自于长按
        public var isFromLongPress: Bool

        static var fromBottomButton = ActionInfo(ifFromBottomButton: true, isFromLongPress: false)
        static var fromMoreButton = ActionInfo(ifFromBottomButton: false, isFromLongPress: false)
        static var fromLongPress = ActionInfo(ifFromBottomButton: false, isFromLongPress: true)
    }
}

public struct LKAssetPluginPosition: OptionSet {
    public let rawValue: Int

    public static let bottomButton = LKAssetPluginPosition(rawValue: 1 << 0)
    public static let actionSheet = LKAssetPluginPosition(rawValue: 1 << 1)
    public static let all: LKAssetPluginPosition = [.bottomButton, .actionSheet]
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

internal protocol LKAssetBrowserPluggable {
    
    var id: String { get }
    var type: LKAssetPluginPosition { get }
    var icon: UIImage? { get }
    var title: String? { get }
    func shouldDisplayPlugin(on context: LKAssetBrowserContext) -> Bool
    func handleAsset(on context: LKAssetBrowserContext)
}

open class LKAssetBrowserPlugin: NSObject, LKAssetBrowserPluggable {
    
    internal var id: String = UUID().uuidString
    
    open var currentContext: LKAssetBrowserContext?
    
    internal lazy var button: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(icon, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.backgroundColor = LKAssetBrowserView.Cons.buttonColor
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 32),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        return button
    }()
    
    open var type: LKAssetPluginPosition { LKAssetPluginPosition(rawValue: 0) }
    
    open var icon: UIImage? { nil }
    
    open var title: String? { nil }
    
    open func shouldDisplayPlugin(on context: LKAssetBrowserContext) -> Bool {
        return false
    }
    
    open func handleAsset(on context: LKAssetBrowserContext) {
        // to be override
    }
    
    @objc
    private func didTapButton() {
        guard let currentContext = currentContext else { return }
        handleAsset(on: currentContext)
    }
}
