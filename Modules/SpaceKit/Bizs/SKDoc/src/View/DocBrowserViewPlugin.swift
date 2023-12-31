//
//  DocBrowserViewPlugin.swift
//  SKBrowser
//
//  Created by lijuyou on 2021/1/19.
//  


import Foundation
import SKCommon
import SKFoundation
import SKUIKit
import SKResource
import SKBrowser
import SpaceInterface

public final class DocBrowserViewPlugin: NSObject {
    public private(set) weak var browserView: BrowserView?
    public private(set) var docsType: DocsType
    private var catalogManager: CatalogManager? // 目录操作所需要的view
    private var editButton: SKEditButton?
    private let editButtonBottomPadding: CGFloat = 56
    private var bottonTemplateHeight: CGFloat = 0 //群公告底部模版列表高度
    private var isEditBtnShow: Bool = false //编辑按钮是否显示

    var shouldUseCatalogManager: Bool {
        if SKDisplay.pad, docsType == .doc { // doc使用iPad
            return false
        }
        return true
    }

    var canShowPhoneCatalog: Bool {
        if SKDisplay.phone {
            return true
        }
        return false
    }

    public required init(_ browserView: BrowserView, docsType: DocsType) {
        self.browserView = browserView
        self.docsType = docsType
        super.init()
    }

    private func setupCatalogManager() {
        guard shouldUseCatalogManager else { return }
        catalogManager = CatalogManager(attach: browserView,
                                        proxy: browserView?.scrollProxy,
                                        toolBar: browserView?.toolbarManagerProxy,
                                        jsEngine: browserView?.jsEngine,
                                        navigator: browserView)
        catalogManager?.delegate = self
        catalogManager?.setCurDocsType(type: docsType)
        if let mgr = catalogManager {
            DocsLogger.info("CatalogManager created")
            let canCopy = browserView?.permissionConfig.hostCanCopy ?? false
            mgr.onCopyPermissionUpdated(canCopy: canCopy) // 初始时也设置,权限请求回来后也设置
            browserView?.hostPermissionEventNotifier.addObserver(mgr)
        }
    }

    private func setupEditButton() {
        guard let browserView = browserView else { return }
        editButton?.removeFromSuperview()
        let button = SKEditButton()
        button.addTarget(self, action: #selector(handleEditButtonClick), for: .touchUpInside)
        button.layer.cornerRadius = 24
        browserView.addSubview(button)
        button.snp.makeConstraints { make in
            make.right.equalTo(browserView.safeAreaLayoutGuide.snp.right).inset(16)
            make.bottom.equalToSuperview().offset(0)
            make.width.height.equalTo(48)
        }
        button.isHidden = true
        editButton = button
        isEditBtnShow = false
    }

    @objc
    private func handleEditButtonClick() {
        self.browserView?.callFunction(.clickEdit, params: nil, completion: nil)
    }
}

extension DocBrowserViewPlugin: BrowserViewPlugin {
    public var supportDocsTypes: [DocsType] { [.doc, .docX] }
    public var curDocsType: DocsType { self.docsType }
    public var catalogAgent: BrowserViewCatalogAgent? { self }
    public var editButtnAgent: BrowserViewEditButtonAgent? { self }

    public func mount() {
        DocsLogger.info("[bizPlugin] plugin mount")
        setupEditButton()
        setupCatalogManager()
        browserView?.lifeCycleEvent.addObserver(self)
        browserView?.scrollViewProxy.addObserver(self)
    }

    public func unmount() {
        DocsLogger.info("[bizPlugin] plugin unmount")
        editButton?.removeFromSuperview()
        catalogManager?.closeCatalog()
        browserView?.scrollViewProxy.removeObserver(self)
    }

    public func clear() {
        DocsLogger.info("[bizPlugin] plugin clear")
        editButton?.isHidden = true
        isEditBtnShow = false
    }

    public func shouldHideView(_ view: UIView) -> Bool {
        if view == editButton {
            return false
        }
        return true
    }
}

extension DocBrowserViewPlugin: BrowserViewCatalogAgent {

    public var catalogDisplayer: CatalogDisplayer? { catalogManager }

    public func showCatalogIndicator(show: Bool) {
        catalogManager?.showIndicator(show: show)
    }
}


extension DocBrowserViewPlugin: BrowserViewEditButtonAgent {

    public var isEditButtonVisible: Bool {
        guard let editButton = editButton else { return false }
        return !editButton.isHidden
    }

    public func setEditButtonVisible(_ visible: Bool) {
        editButton?.isHidden = !visible
        isEditBtnShow = visible
        if visible {
            modifyEditButtonProgress(0.0, animated: false, force: true, completion: nil)
        }
    }

    /**
     Modify the edit button fullscreen scrolling progress

     - Warning: If edit button is hidden, it won't do nothing, and also it won't invoke `completion`.
     */
    public func modifyEditButtonProgress(_ progress: CGFloat, animated: Bool, force: Bool, completion: (() -> Void)?) {
        guard let editButton = editButton, editButton.superview != nil else { return }
        guard !editButton.isHidden || force else { return }
        let reformedProgress: CGFloat = max(0.0, min(1.0, progress))
        let buttonSize: CGSize = CGSize(width: 48, height: 48)
        let movementRange: CGFloat = (editButtonBottomPadding + buttonSize.height) * reformedProgress
        var bottomOffset = editButtonBottomPadding - movementRange

        isEditBtnShow = (reformedProgress == 0)
        bottomOffset = (isEditBtnShow ? bottonTemplateHeight + editButtonBottomPadding : bottomOffset - bottonTemplateHeight * reformedProgress)
        editButton.snp.updateConstraints { make in
            make.bottom.equalToSuperview().offset(-bottomOffset)
        }
        if animated {
            let animDuration: TimeInterval = TimeInterval(UINavigationController.hideShowBarDuration)
            UIView.animate(withDuration: animDuration, animations: {
                editButton.superview?.layoutIfNeeded()
            }, completion: { _ in
                completion?()
            })
        } else {
            completion?()
        }
    }

    public func modifyEditButtonBottomOffset(height: CGFloat) {
        bottonTemplateHeight = height
        guard isEditBtnShow, let editButton = editButton else { return }
        let bottomOffset = height + editButtonBottomPadding
        editButton.snp.updateConstraints { make in
            make.bottom.equalToSuperview().offset(-bottomOffset)
        }
        editButton.superview?.layoutIfNeeded()
    }
}

extension DocBrowserViewPlugin: CatalogManagerDelegate {
    func notifyDisplayBottomEntry(show: Bool, emptyHeight: CGFloat) {
        browserView?.onKeyboardChanged(show, innerHeight: emptyHeight, trigger: "catalog")
    }
}

extension DocBrowserViewPlugin: EditorScrollViewObserver {
    public func editorViewScrollViewWillBeginDragging(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        guard canShowPhoneCatalog else { return }
        catalogManager?.catalogDidReceiveBeginDragging(info: browserView?.docsInfo)
    }

    public func editorViewScrollViewDidScroll(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        let scrollView = editorViewScrollViewProxy.getScrollView()
        let shouldHideCatalog = scrollView?.isTracking ?? false

        if canShowPhoneCatalog, let browserView = browserView {
            catalogManager?.catalogDidReceivedScroll(isEditPool: browserView.isInEditorPool, hideCatalog: shouldHideCatalog, isOpenSDK: (browserView.chatId != nil), info: browserView.docsInfo)
        } else if shouldUseCatalogManager, shouldHideCatalog {
            catalogManager?.hideCatalog()
        }
    }

    public func editorViewScrollViewDidEndScrollingAnimation(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        guard canShowPhoneCatalog else { return }
        catalogManager?.catalogDidEndScrollingAnimation()
    }

    public func editorViewScrollViewDidEndDragging(_ editorViewScrollViewProxy: EditorScrollViewProxy, willDecelerate decelerate: Bool) {
        guard canShowPhoneCatalog else { return }
        catalogManager?.catalogDidReceiveEndDragging(decelerate: decelerate)
    }

    public func editorViewScrollViewDidEndDecelerating(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        guard canShowPhoneCatalog else { return }
        catalogManager?.catalogDidReceiveEndDecelerating()
    }

}
