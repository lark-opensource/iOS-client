//
//  CustomTopContainerManager.swift
//  SKBrowser
//
//  Created by lizechuang on 2020/11/4.
//

import Foundation
import SKUIKit
import SKCommon
import SKFoundation
import UniverseDesignColor

/**
 Custom top container  used in SpaceKit iOS.
 * https://bytedance.feishu.cn/docs/doccno29ZZ3T4gUuCVlIAme6zie#
 * https://bytedance.feishu.cn/docs/doccn42935xT0vODjS7MOaxcLsg
 */

public final class CustomTopContainerManager {

    private(set) weak var proxy: CustomTCManagerProxy?

    // MARK: construction
    private var topContainer: CustomTopContainer?

    // record the current StatusBarStyle
    private var lastStatusBarStyle: UIStatusBarStyle?
    private var lastFullScreenEnabled: Bool?
    private var _hideCustomHeaderInLandscape: Bool?

    init(proxy: CustomTCManagerProxy) {
        self.proxy = proxy
    }

    public func updateCurNavBarSizeType(_ sizeType: SKNavigationBar.SizeType) {
        guard let topContainer = self.topContainer else {
            return
        }
        topContainer.updateCurNavBarSizeType(sizeType)
    }
}

// MARK: Private Methods
extension CustomTopContainerManager {
    private func _initialize() {
        if topContainer != nil {
            return
        }

        let navBar: SKNavigationBar = SKNavigationBar()
        if let sizeType = self.proxy?.navBarSizeType {
            navBar.sizeType = sizeType
        }

        topContainer = CustomTopContainer(navBar: navBar)
        _setupTopContainer()
        lastStatusBarStyle = proxy?.statusBarStyle
        // hidden indicator
        proxy?.customTCManger(self, shouldShowIndicator: false)
        // configuration original TC
        lastFullScreenEnabled = proxy?.enableFullscreenScrolling
        proxy?.enableFullscreenScrolling = false
        proxy?.customTCMangerDidShow(self)
        DocsLogger.info("CustomTopContainerManager initialize")
    }

    private func _setupTopContainer() {
        guard let host = self.proxy?.hostView, let topContainer = self.topContainer else {
            DocsLogger.info("hostView 获取失败")
            return
        }
        host.addSubview(topContainer)
        topContainer.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        topContainer.setup()
        topContainer.startInterceptPopGesture(gesture: proxy?.obtainHostVCInteractivePopGestureRecognizer())
    }

    private func _reset() {
        topContainer?.stopInterceptPopGesture()
        topContainer?.removeFromSuperview()
        topContainer?.snp.removeConstraints()
        topContainer = nil
        if let lastStatusBarStyle = self.lastStatusBarStyle {
            proxy?.customTCManger(self, updateStatusBarStyle: lastStatusBarStyle)
        }
        if let lastFullScreenEnabled = self.lastFullScreenEnabled {
            proxy?.enableFullscreenScrolling = lastFullScreenEnabled
        }
        proxy?.customTCMangerDidHidden(self)
        DocsLogger.info("CustomTopContainerManager reset")
    }
}

// MARK: CustomTopContainerDisplayConfig
extension CustomTopContainerManager: CustomTopContainerDisplayConfig {
    public func customTopContainerShow() -> Bool {
        return !(topContainer?.isHidden ?? true)
    }
    
    public func setCustomTopContainer(isShow: Bool) {
        if proxy?.disableCustomNavBarBackground == true {
            return
        }
        isShow ? _initialize() : _reset()
    }

    public func setCustomTopContainerHidden(_ hidden: Bool) {
        if proxy?.disableCustomNavBarBackground == true {
            return
        }
        topContainer?.isHidden = hidden
    }

    public var leftBarButtonItems: [SKBarButtonItem]? {
        get { return topContainer?.navBar.leadingBarButtonItems }
        set { topContainer?.navBar.leadingBarButtonItems = newValue ?? [] }
    }
    
    public var rightBarButtonItems: [SKBarButtonItem]? {
        get { return topContainer?.navBar.trailingBarButtonItems }
        set { topContainer?.navBar.trailingBarButtonItems = newValue ?? [] }
    }

    public var layoutAttributes: SKNavigationBar.LayoutAttributes? {
        get { return topContainer?.layoutAttributes }
        set {
            if let newValue = newValue {
                topContainer?.layoutAttributes = newValue
            }
        }
    }
    
    public var hideCustomHeaderInLandscape: Bool? {
        get { return _hideCustomHeaderInLandscape }
        set { _hideCustomHeaderInLandscape = newValue }
    }

    public func setCustomTCTitleInfo(_ titleInfo: NavigationTitleInfo?) {
        topContainer?.titleInfo = titleInfo
    }

    public func setCustomTCTitleHorizontalAlignment(_ titleHorizontalAlignment: UIControl.ContentHorizontalAlignment) {
        topContainer?.titleHorizontalAlignment = titleHorizontalAlignment
    }

    public func shouldShowDivider(_ show: Bool) {
        topContainer?.shouldShowDivider(show)
    }

    public func setCustomTCThemeColor(_ themeColor: String) {
        if proxy?.disableCustomNavBarBackground == true {
            return
        }
        let isDark = UIColor.docs.isColorDark(themeColor)
        proxy?.customTCManger(self, updateStatusBarStyle: isDark ? .lightContent : .default)
        let backgroundColor = UIColor.docs.rgb(themeColor)
        topContainer?.setCustomAppearance(backgroundColor: backgroundColor)
    }

    public func setCustomTCInteractivePopGestureAction(_ action: @escaping () -> Void) {
        topContainer?.interactivePopGestureAction = action
    }

    public func setCustomCenterView(_ view: CustomSubTopContainer?) {
        topContainer?.setCustomCenterView(view)
    }

    public func setCustomRightView(_ view: CustomSubTopContainer?) {
        topContainer?.setCustomRightView(view)
    }
    public func getCustomCenterView() -> CustomSubTopContainer? {
        return topContainer?.getCustomCenterView()
    }
    
    public func setPreNaviPopGestureDelegate(naviPopGestureDelegate: UIGestureRecognizerDelegate?) {
        topContainer?.previousGestureDelegate = naviPopGestureDelegate
    }
}
