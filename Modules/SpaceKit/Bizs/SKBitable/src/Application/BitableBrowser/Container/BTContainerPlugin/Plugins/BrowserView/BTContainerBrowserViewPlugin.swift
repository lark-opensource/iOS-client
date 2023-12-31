//
//  BTContainerBrowserViewPlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/6.
//

import SKFoundation
import SKBrowser
import SKCommon
import SpaceInterface
import LarkUIKit

final class BTContainerBrowserViewPlugin: BTContainerBasePlugin {
        
    override var view: UIView? {
        get {
            service?.browserViewController?.editor
        }
    }

    var editorView: UIView? {
        get {
            service?.browserViewController?.editor.editorView
        }
    }
    
    private class CommentViewPadBottomView: UIView {
        fileprivate var height: CGFloat = 0.0 {
            didSet {
                remakeConstraints()
            }
        }
        
        override func didMoveToSuperview() {
            super.didMoveToSuperview()
            remakeConstraints()
        }
        
        private func remakeConstraints() {
            guard self.superview != nil else {
                return
            }
            self.snp.remakeConstraints { make in
                make.width.equalTo(0)
                make.height.equalTo(height)
                make.bottom.right.equalToSuperview()
            }
        }
    }
    
    private lazy var commentViewPadBottomView: CommentViewPadBottomView = CommentViewPadBottomView()

    override func updateStatus(old: BTContainerStatus?, new: BTContainerStatus, stage: UpdateStatusStage) {
        super.updateStatus(old: old, new: new, stage: stage)
                
        guard stage == .animationEndStage || stage == .finalStage else {
            return  // 默认只处理 End 和 Final
        }
        if stage == .finalStage {
            if new.viewContainerType != old?.viewContainerType {
                remakeConstraints(status: new)
            } else if new.orientation != old?.orientation {
                remakeConstraints(status: new)
            } else if new.mainContainerSize != old?.mainContainerSize {
                remakeConstraints(status: new)
            } else if new.fullScreenType != old?.fullScreenType {
                remakeConstraints(status: new)
            } else if new.isRegularMode != old?.isRegularMode {
                remakeConstraints(status: new)
            }
        } else if stage == .animationEndStage {
            if new.viewContainerType != old?.viewContainerType {
                remakeConstraints(status: new)
            }
        }
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        guard let editor = service.browserViewController?.editor else {
            DocsLogger.error("invalid editor")
            return
        }
        
        func showCornerRadius(_ show: Bool) {
            if show {
                editor.layer.cornerRadius = BTContainer.Constaints.viewContainerCornerRadius
            } else {
                editor.layer.cornerRadius = 0
            }
            editor.layer.masksToBounds = true
            editor.layer.maskedCorners = .top
        }
        
        if new.fullScreenType != .none {
            showCornerRadius(false)
        } else if new.viewContainerType == .noViewCatalogNoToolBar {
            showCornerRadius(true)
        } else {
            showCornerRadius(false)
        }
        
        remakeCommentViewPadBottomViewConstraints(status: status)
        
        editor.transform.ty = (new.canSwitchToolBar && new.toolBarHidden) ? -BTContainer.Constaints.toolBarHeight : 0
    }
    
    private func remakeCommentViewPadBottomViewConstraints(status: BTContainerStatus) {
        if UserScopeNoChangeFG.YY.bitablePadCommentsKeyboardFixDisable {
            return
        }
        if !Display.pad {
            return
        }
        let height = status.baseHeaderHidden ? 0 : status.webviewBottomOffset
        if commentViewPadBottomView.superview != nil,
            commentViewPadBottomView.frame.height != height {
            commentViewPadBottomView.height = height
        }
    }
    
    override func remakeConstraints(status: BTContainerStatus) {
        super.remakeConstraints(status: status)
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        guard let editor = service.browserViewController?.editor else {
            DocsLogger.error("invalid editor")
            return
        }
        guard let viewCatalogueContainer = service.getOrCreatePlugin(BTContainerPluginSet.viewCatalogueBanner).view else {
            DocsLogger.error("invalid viewCatalogueContainer.view")
            return
        }
        guard let viewToolBar = service.getOrCreatePlugin(BTContainerPluginSet.toolBar).view else {
            DocsLogger.error("invalid viewToolBar.view")
            return
        }
        let status = status
        if editor.superview != nil {
            if status.fullScreenType != .none {
                editor.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                }
            } else {
                let viewContainerType = status.viewContainerType
                editor.snp.remakeConstraints { (make) in
                    if viewContainerType == .noViewCatalogNoToolBar {
                        make.top.equalToSuperview()
                    } else if viewContainerType == .hasViewCatalogNoToolBar {
                        make.top.equalTo(viewCatalogueContainer.snp.bottom)
                    } else {
                        make.top.equalTo(viewToolBar.snp.bottom)
                    }
                    make.left.equalToSuperview()
                    make.bottom.equalToSuperview()
                    make.right.equalToSuperview()   // 直接与父容器宽度绑定
                }
            }
        }
    }
    
    func insertBrowser(_ browser: BrowserView) {
        DocsLogger.info("insertBrowser")
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        let plugin = service.getOrCreatePlugin(BTContainerPluginSet.viewContainer)
        if !UserScopeNoChangeFG.YY.bitablePadCommentsKeyboardFixDisable, Display.pad {
            browser.commentViewPadBottomView?.removeFromSuperview()
            browser.commentViewPadBottomView = commentViewPadBottomView
        }
        plugin.view?.addSubview(browser)
        
        // Loading 需要置顶盖在最上面
        service.getOrCreatePlugin(BTContainerPluginSet.viewContainer).bringLoadingToFront()
        service.getPlugin(BTContainerLinkedDocxPlugin.self)?.bringDocxViewUp()
        
        remakeConstraints(status: status)

        browser.lifeCycleEvent.addObserver(self)
    }
}

extension BTContainerBrowserViewPlugin: BrowserViewLifeCycleEvent {
    func browserDidLayoutSubviews() {
        DispatchQueue.main.async { [weak self] in
            guard let browser = self?.service?.browserViewController?.editor else {
                return
            }
            // iPad 上评论面板挤占 editorView 的宽度，需要更新 FAB 右侧对齐位置
            let editorView = browser.editorView
            let animationDuration = browser.commentViewAnimationDuration
            self?.service?.fabPlugin.updateEditorViewRightPadding(editorViewRightPadding: browser.frame.width - editorView.frame.width, animationDuration: animationDuration)
            
            if let status = self?.status {
                self?.remakeCommentViewPadBottomViewConstraints(status: status)
            }
        }
    }
}
