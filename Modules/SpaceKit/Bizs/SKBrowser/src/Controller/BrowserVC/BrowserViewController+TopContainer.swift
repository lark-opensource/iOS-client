//
//  BrowserViewController+TopContainer.swift
//  SKBrowser
//
//  Created by duanxiaochen.7 on 2021/2/14.
//

import SKFoundation
import SKCommon
import SKUIKit
import UniverseDesignColor


public enum TopContainerState {
    case normal // transparency is determined by webview scrolling
    case fixedShowing // always showing, top container is to the top of the webview
    case fixedHiding // always hiding, webview take the place of top container
}

/*
 沉浸式浏览相关逻辑
 当前接入沉浸式模块：
 - 顶部所有组件
 - 底部编辑按钮组件
 - 下拉收起键盘（采用系统API)

 */
extension BrowserViewController {
    /// Set browser fullscreen mode by notification
    func setBrowserFullScreenMode(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else { return }
        guard let type = docsInfo?.type, type == .doc, UIDevice.current.userInterfaceIdiom == .phone else { return }
        guard let shouldEnter = userInfo["enterFullscreen"] as? Bool else { return }
        if let token = userInfo["token"] as? String, !token.isEmpty, token != self.editor.docsInfo?.objToken { return } // 传 token 则意味着要校验文档一致性
        let progress: CGFloat = shouldEnter ? 1 : 0
        setFullScreenProgress(progress, editButtonAnimated: true, topContainerAnimated: true)
    }
}



extension BrowserViewController: CustomTCManagerProxy {
    public var disableCustomNavBarBackground: Bool {
        return self.navigationBar.disableCustomBackgroundColor
    }
    
    public var hostView: UIView {
        return self.view
    }

    public var navBarSizeType: SKNavigationBar.SizeType {
        return self.navigationBar.sizeType
    }

    public func obtainHostVCInteractivePopGestureRecognizer() -> UIGestureRecognizer? {
        return self.navigationController?.interactivePopGestureRecognizer
    }

    public func customTCManger(_ manger: CustomTopContainerManager, updateStatusBarStyle style: UIStatusBarStyle) {
        self.statusBarStyle = style
        setNeedsStatusBarAppearanceUpdate()
    }

    public func customTCManger(_ manger: CustomTopContainerManager, shouldShowIndicator show: Bool) {
        self.editor.showIndicator(show: show)
    }

    public func customTCMangerForceTopContainer(state: TopContainerState) {
        if isEmbedMode {
            // EmbedMode 模式不接受此处控制逻辑
            return
        }
        self.topContainerState = state
    }

    public func customTCMangerDidShow(_ manger: CustomTopContainerManager) {
        self.statusBar.isHidden = true
        self.topContainerState = .fixedShowing
        self.templatesPreviewNavigationBarDelegate?.hideTemplatesPreviewNavigationBar(true)
    }

    public func customTCMangerDidHidden(_ manger: CustomTopContainerManager) {
        self.statusBar.isHidden = false
        self.topContainerState = isEmbedMode ? .fixedHiding : .normal
        self.templatesPreviewNavigationBarDelegate?.hideTemplatesPreviewNavigationBar(false)
    }
}
