// 
// Created by duanxiaochen.7 on 2020/4/14.
// SKBrowser
// 
// Description: BrowserViewController 对各种协议的实现
//  swiftlint:disable file_length

import UIKit
import LarkUIKit
import EENavigator
import SpaceInterface
import SKFoundation
import SKCommon
import SKUIKit
import SKResource
import LarkSuspendable
import LarkTab
import UniverseDesignIcon
import UniverseDesignEmpty
import LarkSplitViewController
import SKInfra
import LarkQuickLaunchInterface
import LarkContainer

// MARK: - DocsKeyboardObservingViewDelegate
extension BrowserViewController: DocsKeyboardObservingViewDelegate {
    func keyboardFrameChanged(frame: CGRect) {
        animator.keyboardFrameChanged(frame)
        toolbarManager.keyboardFrameChanged(frame)
    }
}

extension BrowserViewController: BrowserViewNavigationItemObserver {
    public func titleDidChange(from oldValue: String?, to newValue: String?) {
    }
    
    public func fullScreenButtonBarItemDidChangeState(isEnable: Bool) {
        let fullScreenModeItem = navigationBar.leadingBarButtonItems.first { $0.id == .fullScreenMode }
        if let item = fullScreenModeItem {
            item.isEnabled = isEnable
            DocsLogger.info("SET fullScreenModeItem isEnable => \(isEnable)")
        } else {
            DocsLogger.info("fullScreenModeItem not found !")
        }
    }
}

extension BrowserViewController: DocsBulletinResponser {
    public func canHandle(_ type: [String]) -> Bool {
        guard canBulletinShow else { return false }
        return type.contains(editor.docsInfo?.type.name ?? "")
    }

    public func bulletinShouldShow(_ info: BulletinInfo) {
        guard let token = editor.docsInfo?.objToken,
            let content = info.content[DocsSDK.convertedLanguage] else { return }
        if !content.contains(token), bulletin.info?.id != info.id {
            topContainer.banners.setItem(bulletin)
            bulletin.info = info
            bulltinTrack(event: .view(bulletin: info))
        }
    }

    public func bulletinShouldClose(_ info: BulletinInfo?) {
        guard info == nil || info?.id == bulletin.info?.id else { return }
        topContainer.banners.removeItem(bulletin)
        bulletin.info = nil
    }
    
    private func bulltinTrack(event: DocsBulletinTrackEvent) {
        var commonParams: [String: Any] = [:]
        if let docsInfo = self.docsInfo {
            commonParams = DocsParametersUtil.createCommonParams(by: docsInfo)
        }
        let manager = DocsContainer.shared.resolve(DocsBulletinManager.self)
        manager?.track(event, commonParams: commonParams)
    }
}

// MARK: First responder operate logic
extension BrowserViewController: DocsEditorViewResponderDelegate {
    public func docsEditorViewWillBecomeFirstResponder(_ editorView: DocsEditorViewProtocol) {
        toolbarManager.docsEditorViewWillBecomeFirstResponder(editorView)
    }

    public func docsEditorViewDidBecomeFirstResponder(_ editorView: DocsEditorViewProtocol) {
        toolbarManager.docsEditorViewDidBecomeFirstResponder(editorView)
    }

    public func docsEditorViewWillResignFirstResponder(_ editorView: DocsEditorViewProtocol) {
        toolbarManager.docsEditorViewWillResignFirstResponder(editorView)
    }

    public func docsEditorViewDidResignFirstResponder(_ editorView: DocsEditorViewProtocol) {
        toolbarManager.docsEditorViewDidResignFirstResponder(editorView)
        //webview失去焦点BrowserKeyboardHanlder无法处理键盘事件时手动通知键盘消失
        self.hideKeyboardAndNoticeWebIfNeed()
    }
}


extension BrowserViewController: BrowserViewDelegate {
    public func browserViewController() -> BaseViewController {
        return self
    }
    
    public func browserPermissionHostView(_ browserView: BrowserView) -> UIView? {
        return permissionHostView()
    }
    
    public func browserStateHostConfig(_ browserView: BrowserView) -> CustomStatusConfig? {
        return stateHostConfig()
    }

    public func browserViewDidUpdateDocsInfo(_ browserView: BrowserView) {
        logNavBarEvent(.navigationBarView)
        updateTemporaryTab()
    }
    
    public func browserView(_ browserView: BrowserView, shouldShowBanner item: BannerItem) {
        // 如果是版本，在兜底、出错时不展示banner
        var docsVersionCanShow = true
        if browserView.docsInfo?.isVersion ?? false {
            docsVersionCanShow = canShowVersionTitle
        }
        //无网络下新建文档会在调用viewdidLoad之前走到这里产生crash，添加下保护
        if isFinishSetUp == true, docsVersionCanShow {
            topContainer.banners.setItem(item)
        }
    }

    public func browserView(_ browserView: BrowserView, shouldHideBanner item: BannerItem) {
        topContainer.banners.removeItem(item)
    }

    public func browserViewShouldRemoveAllBannerItem(_ browserView: BrowserView) {
        topContainer.banners.removeAll()
    }

    public func browserView(_ browserView: BrowserView, shouldChangeBannerInvisible toHidden: Bool) {
        topContainer.banners.alpha = toHidden ? 0.0 : 1.0
        topContainer.layoutIfNeeded()
    }

    public func browserViewShouldToggleEditMode(_ browserView: BrowserView) {
        let toVisible = togglingEditModeState == 2
        guard togglingEditModeState != 1,
              editor.isEditButtonVisible else { return }

        togglingEditModeState = 1
        setFullScreenProgress(toVisible ? 0 : 1)
    }

    public func browserView(_ browserView: BrowserView, shouldChangeCatalogButtonState isOpen: Bool) {
        self.isShowCatalogItem = isOpen
        self.setCatalogDisplayButtonStatus(isSelected: self.isShowCatalogItem)
    }

    public func browserVIewIPadCatalogState(_ browserView: BrowserView) -> Bool {
        return self.isShowCatalogItem
    }
    
    public func browserViewTitleBarCoverHeight(_ browserView: BrowserView) -> CGFloat {
        return topContainer.preferredHeight - topPlaceholder.bounds.height
    }

    public func browserView(_ browserView: BrowserView, shouldChangeCompleteButtonInvisible toHidden: Bool) {
        if isEmbedMode {
            // EmbedMode 中，如果需要显示完成按钮，则需要使用 fixedShowing 模式，否则使用 fixedHiding 模式
            topContainerState = toHidden ? .fixedHiding : .fixedShowing
        }
        isDoneButtonVisible = !toHidden
        let doneButtonItem = self.doneButtonItem
        if SKDisplay.pad {
            var itemComponents: [SKBarButtonItem] = navigationBar.temporaryTrailingBarButtonItems
            if isDoneButtonVisible, !itemComponents.contains(doneButtonItem) {
                itemComponents.insert(doneButtonItem, at: 0)
            } else if !isDoneButtonVisible, itemComponents.contains(doneButtonItem) {
                itemComponents = itemComponents.filter { $0 != doneButtonItem }
            }
            navigationBar.temporaryTrailingBarButtonItems = itemComponents
        } else {
            var itemComponents: [SKBarButtonItem] = navigationBar.leadingBarButtonItems
            if isDoneButtonVisible, !itemComponents.contains(doneButtonItem) {
                itemComponents.insert(doneButtonItem, at: 0)
            } else if !isDoneButtonVisible, itemComponents.contains(doneButtonItem) {
                itemComponents.removeAll(where: { $0 == doneButtonItem })
            }
            navigationBar.leadingBarButtonItems = itemComponents
        }
        refreshLeftBarButtons()
        self.templatesPreviewNavigationBarDelegate?.shouldChangeCompleteButton(visible: !toHidden)
    }

    public func browserView(_ browserView: BrowserView, setTopContainerState state: TopContainerState) {
        if isEmbedMode {
            // EmbedMode 模式下，TopContainer 不接受控制这里的控制，除了编辑模式下 fixedShowing，其他都是 fixedHiding
            return
        }
        topContainerState = state
    }

    public func browserView(_ browserView: BrowserView,
                     markFeedCardShortcut isAdd: Bool,
                     success: SKMarkFeedSuccess?,
                     failure: SKMarkFeedFailure?) {
        guard let feedId = feedID else { return }
        delegate?.markFeedCardShortcut(for: feedId,
                                       isAdd: isAdd,
                                       success: success,
                                       failure: failure)
    }

    public func browserViewIsFeedCardShortcut(_ browserView: BrowserView) -> Bool {
        guard let delegate = delegate, let feedId = feedID else {
            DocsLogger.info("[FeedShortcut] Delegate & feedId 为空")
            return false
        }
        return delegate.isFeedCardShortcut(feedId: feedId)
    }
    
    // 是否展示shortCut
    public func browserView(_ browserView: BrowserView, needShowFeedCardShortcut channelType: Int) -> Bool {
        if DocsSDK.isInLarkDocsApp { // 单品不展示置顶
            return false
        } else {
            return feedID != nil
        }
    }

    public func browserView(_ browserView: BrowserView, enableFullscreenScrolling enable: Bool) {
        DocsLogger.info("Fullscreen scrolling did changed state to --", extraInfo: ["enable": enable])
        self.enableFullscreenScrolling = enable
    }

    public func browserView(_ browserView: BrowserView, shouldChange orientation: UIInterfaceOrientation) {
        orientationDirector?.forceSetOrientation(orientation)
    }
    /// 考虑了用户锁定了自动旋转，但设备已经旋转角度的情况。
    /// TODO：是不是要删除的方法？ @chenjiahao.gill
    public func browserViewCurrentOrientation(_ browserView: BrowserView) -> UIInterfaceOrientation {
        return orientationDirector?.deviceOrientation ?? .portrait
    }

    public func browserViewCustomTCDisplayConfig(_ browserView: BrowserView) -> CustomTopContainerDisplayConfig? {
        return self.customTCMangager
    }

    public func browserViewHandleDeleteEvent(_ browserView: BrowserView) {
        guard let docsInfo = self.docsInfo else {
            DocsLogger.error("browserViewHandleDeleteEvent no docsInfo")
            return
        }
        guard !isShowingDocsDeleteHintView else {
            DocsLogger.warning("browserViewHandleDeleteEvent has show DeleteView")
            return
        }
        if docsInfo.isVersion {
            DocsLogger.info("version Delete Notify")
            canShowVersionTitle = false
            if self.canShowDelEmptyView {
                addDeleteHintView(isVerison: true)
            }
        } else {
            addDeleteHintView(isVerison: false)
        }
        lockBasicNavigationMode()
        view.bringSubviewToFront(topContainer)
        cleanTemplateTagFor(browserView)
    }
    
    public func browserViewHandleDeleteRecoverEvent(_ browserView: BrowserView) {
        guard let docsInfo = self.docsInfo else {
            DocsLogger.error("browserViewHandleDeleteRecoverEvent no docsInfo")
            return
        }
        guard isShowingDocsDeleteHintView  else {
            DocsLogger.warning("browserViewHandleDeleteRecoverEvent has not show DeleteView")
            return
        }
        // 刷新逻辑
        guard let editor = self.editor as? WebBrowserView,
              let loader = editor.webLoader,
              docsInfo.isVersion else {
            DocsLogger.error("can not get the webLoader, not refresh")
            return
        }
        self.navigationBar.navigationMode = DocsSDK.navigationMode
        self.isShowingDocsDeleteHintView = false   //恢复成功后重置兜底页展示标记位
        loader.reloadForRecover(true, fromTerminate: false)
        view.subviews.forEach { subView in
            if subView.isKind(of: UDEmptyView.self) {
                subView.removeFromSuperview()
            }
        }
    }
    
    public func browserViewHandleNotFoundEvent(_ browserView: BrowserView) {
        handleBrowserViewNotFoundEvent()
    }
    
    private func addDeleteHintView(isVerison: Bool) {
        guard let docsInfo = self.docsInfo else {
            return
        }
        DocsLogger.info("add Delete HintView")
        let deleteHintView = UDEmptyView(config: isVerison ? self.emptyConfigForDeletedVersion : docsInfo.emptyConfigForDeleted)
        deleteHintView.useCenterConstraints = true
        view.addSubview(deleteHintView)
        view.bringSubviewToFront(deleteHintView)
        deleteHintView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        isShowingDocsDeleteHintView = true
        if isVerison {
            var params = ["click": "confirm", "target": "none"]
            params.merge(other: DocsParametersUtil.createCommonParams(by: docsInfo))
            if docsInfo.inherentType == .sheet {
                DocsTracker.newLog(enumEvent: .sheetVersionDeletedTip, parameters: params)
            } else {
                DocsTracker.newLog(enumEvent: .docsVersionDeletedTip, parameters: params)
            }
        } else {
            // 检查被删除文档是否可被从回收站恢复, wiki场景不通过notify.event通知处理
            addDeleteRestoreView(docsInfo: docsInfo, deleteHintView: deleteHintView)
        }
    }
    
    private func addDeleteRestoreView(docsInfo: DocsInfo, deleteHintView: UDEmptyView) {
        var restoreType = RestoreType.space(objToken: docsInfo.urlToken, objType: docsInfo.urlType)
        if docsInfo.isFromWiki, let wikiToken = docsInfo.wikiInfo?.wikiToken {
            restoreType = RestoreType.wiki(wikiToken: wikiToken)
        }
        let deleteRestoreView = DocsRestoreEmptyView(type: restoreType)
        deleteRestoreView.restoreCompeletion = { [weak self] in
            // 刷新逻辑
            guard let editor = self?.editor as? WebBrowserView,
                  let loader = editor.webLoader else {
                DocsLogger.error("can not get the webLoader, not refresh")
                return
            }
            self?.navigationBar.navigationMode = DocsSDK.navigationMode
            self?.isShowingDocsDeleteHintView = false   //恢复成功后重置兜底页展示标记位
            self?.restoreSuccessRelay.accept(true)
            //恢复成功刷新文档前先调一次clear
            loader.removeContentIfNeed()
            loader.reloadForRecover(true, fromTerminate: false)
            deleteHintView.removeFromSuperview()
        }
        view.addSubview(deleteRestoreView)
        view.bringSubviewToFront(deleteRestoreView)
        deleteRestoreView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    // 通过被删除的wiki shortcut链接（本体存在）前端无法通知，wiki主动调用添加兜底页
    public func addDeletedViewForWikiShortcut() {
        browserViewHandleDeleteEvent(self.editor)
    }

    public func browserViewHandleKeyDeleteEvent(_ browserView: BrowserView) {
        guard let docsInfo = self.docsInfo else {
            DocsLogger.error("browserViewHandleKeyDeleteEvent no docsInfo")
            return
        }
        if keyDeleteHintView == nil {
            keyDeleteHintView = UDEmptyView(config: docsInfo.emptyConfigForKeyDeleted)
        }
        guard let keyDeleteHintView = keyDeleteHintView else {
            return
        }
        if keyDeleteHintView.superview == nil {
            view.addSubview(keyDeleteHintView)
        }
        view.bringSubviewToFront(keyDeleteHintView)
        keyDeleteHintView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        if self.docsInfo?.isFromWiki == true {
            configWikiNavigationBarForKeyDelete()
        } else {
            lockBasicNavigationMode()
        }
        view.bringSubviewToFront(topContainer)
        isShowingDeleteHintView.accept(true)
    }

    public func dismissKeyDeleteHintView() {
        if let keyDeleteHintView = keyDeleteHintView,
            keyDeleteHintView.superview != nil {
            keyDeleteHintView.removeFromSuperview()
            isShowingDeleteHintView.accept(false)
        }
    }

    public func browserViewDidUpdateRealTokenAndType(info: DocsInfo) {
        setupMonitorPermissions(docsInfo: info)
    }

    public func lockBasicNavigationMode() {
        // 隐藏按钮
        navigationBar.removeAllItems()
        var itemComponents: [SKBarButtonItem] = []
        // 只有在非 vc 下才设置返回按钮
        if !isInVideoConference {
            if SKDisplay.phone {
                if self.canShowBackItem {
                    itemComponents.append(backBarButtonItem)
                } else {
                    itemComponents.append(closeButtonItem)
                }
            } else if SKDisplay.pad {
                if hasBackPage, self.canShowBackItem {
                    itemComponents.append(backBarButtonItem)
                } else {
                    itemComponents.append(closeButtonItem)
                }
            }
        }
        navigationBar.leadingBarButtonItems = itemComponents
        navigationBar.navigationMode = .basic
        topContainerState = .fixedShowing
    }

    public func noPermissionNotifyEvent(_ browserView: BrowserView) {
        // 无权限时，关闭 IM 进入的 feed 通知
        canShowVersionTitle = false
        editor.simulateJSMessage(DocsJSService.feedCloseMessage.rawValue, params: [:]) //关闭通知
        refreshLeftBarButtons()
        cleanTemplateTagFor(browserView)
    }
    
    private func cleanTemplateTagFor(_ browserView: BrowserView) {
        browserView.setShowTemplateTag(false)
        topContainer.banners.removeAll()
    }
    
    /// 配置 Wiki 页面密钥删除后的 NavgationBar 样式
    private func configWikiNavigationBarForKeyDelete() {
        navigationBar.trailingBarButtonItems = []
        navigationBar.temporaryTrailingBarButtonItems = []
        navigationBar.title = nil
        navigationBar.navigationMode = .allowing(list: [.back, .close, .tree])
        topContainerState = .fixedShowing
    }
    
    public func canShowDeleteVersionEmptyView(_ show: Bool) {
        DocsLogger.info("canShowDeleteVersion：\(show)")
        self.canShowDelEmptyView = show
    }
    
    /// 设置外显目录是否显示
    public func setCatalogueBanner(visible: Bool) {
        topContainer.catalogueContainer.setCatalogueBanner(visible: visible)
    }
    
    /// 设置外显目录
    public func setCatalogueBanner(catalogueBannerData: SKCatalogueBannerData?, callback: SKCatalogueBannerViewCallback?) {
        topContainer.catalogueContainer.setCatalogueBanner(catalogueBannerData: catalogueBannerData, callback: callback)
    }
    
    public func browserViewShowBitableAdvancedPermissionsSettingVC(data: BitableBridgeData, listener: BitableAdPermissionSettingListener?) {
        handleShowBitableAdvancedPermissionsSettingVC(data: data, listener: listener)
    }
    
    /// 设置快捷键
    public func browserView(_ browserView: BrowserView, setKeyCommandsWith info: [UIKeyCommand: String]) {
        docsKeyCommands.append(info)
    }
    
    public func browserViewHandleRefreshEvent(_ browserView: BrowserView) {
        self.refresh()
    }
}

extension BrowserViewController: DocsToolBarDelegate {
    public func docsToolBar(_ toolBar: DocsToolBar, changeInputView inputView: UIView?) {
        if inputView == nil, editor.uiResponder.inputAccessory.realInputView == nil {
            //都为空则直接return掉，否则再将inputView置空会有额外的键盘升起事件传出
            //https://meego.feishu.cn/larksuite/issue/detail/7891847
            return
        }
        UIView.performWithoutAnimation {
            if SKDisplay.phone {
                editor.uiResponder.inputAccessory.realInputView = inputView
                return
            }
            var realKeyboardType: Keyboard.DisplayType = .default
            if #available(iOS 16.0, *), UserScopeNoChangeFG.LJW.toolbarAdapterForKeyboard {
                //iOS16浮动键盘切成的妙控打开图片查看器传递的事件有bug，暂时屏蔽
            } else {
                if keyboard.displayType == .floating {
                    realKeyboardType = keyboard.displayType
                }
            }
            if realKeyboardType == .floating {
                editor.uiResponder.inputAccessory.realInputAccessoryView = inputView
                //不把inputView置空会导致键盘拖到原来inputAccessoryView的位置时被弹开
                //https://meego.feishu.cn/larksuite/issue/detail/5552116
                if inputView == nil {
                    editor.uiResponder.inputAccessory.realInputView = nil
                }
            } else {
                editor.uiResponder.inputAccessory.realInputView = inputView
            }
        }
    }

    public func docsToolBarShouldEndEditing(_ toolBar: DocsToolBar, editMode: DocsToolBar.EditMode, byUser: Bool) {
        if editMode == .normal {
            // 如果先设置 inputview=nil，reloadInputViews 会触发一次 keyboard showEvent，前端会有多余滚动
            // 所以先 resignFirstResponder 再设置 inputview=nil
            self.editor.resignFirstResponder()
            self.editor.uiResponder.inputAccessory.realInputView = nil
            if floatKeyboardHasSubPanel {
                self.editor.uiResponder.inputAccessory.realInputAccessoryView = nil
            }
        } else if editMode == .sheetInput {
            guard let info = editor.browserInfo.docsInfo, byUser else { return }
            let params = ["action": "close_keyboard",
                          "file_id": DocsTracker.encrypt(id: info.objToken),
                          "file_type": info.type.name,
                          "mode": "default",
                          "module": info.type.name,
                          "source": "sheet_toolbar"]
            DocsTracker.log(enumEvent: DocsTracker.EventType.sheetOperation, parameters: params)
        }
    }

    public func docsToolBarRequestDocsInfo(_ toolBar: DocsToolBar) -> DocsInfo? {
        return editor.browserInfo.docsInfo
    }

    public func docsToolBarRequestInvokeScript(_ toolBar: DocsToolBar, script: DocsJSCallBack) {
        editor.callFunction(script, params: nil, completion: { (_, error) in
            if let error = error {
                DocsLogger.error("DocsToolBar invoke script error", extraInfo: nil, error: error, component: nil)
            }
        })
    }
    
    public func docsToolBarToggleDisplayTypeToDefault(_ toolBar: DocsToolBar) {
        UIView.performWithoutAnimation {
            if let inputView = editor.uiResponder.inputAccessory.realInputAccessoryView, inputView is SKSubToolBarPanel {
                editor.uiResponder.inputAccessory.realInputAccessoryView = nil
                editor.uiResponder.inputAccessory.realInputView = inputView
            }
        }
    }
    
    public func docsToolBarToggleDisplayTypeToFloating(_ toolBar: DocsToolBar, frame: CGRect) {
        if let inputView = editor.uiResponder.inputAccessory.realInputView, inputView is SKSubToolBarPanel {
            inputView.removeFromSuperview()
            let heightConstraints = inputView.constraints.filter { ($0.firstItem === inputView) && ($0.firstAttribute == NSLayoutConstraint.Attribute.height) }
            if  heightConstraints.count > 0 {
                let constraint = heightConstraints[0]
                constraint.constant = animator.floatKeyBoardHeight
                inputView.layoutIfNeeded()
            }
            inputView.frame = CGRect(origin: .zero, size: CGSize(width: SKDisplay.windowBounds(self.view).width, height: animator.floatKeyBoardHeight))
            editor.uiResponder.inputAccessory.realInputAccessoryView = inputView
            editor.uiResponder.inputAccessory.realInputView = nil
        }
    }
    
    public func browserViewDidUpdateDocName(_ browserView: BrowserView, docName: String?) {
        guard let docName = docName, docName.count > 0 else { return }
        self.docName = docName
        updateTemporaryTab()
    }
    
    public func browserViewWillShowNoPermissionView(_ browserView: BrowserView){
        willShowNoPermissionView()
    }
    
    // 替换loading为自己处理
    public func browserViewShowCustomLoading(_ browserView: BrowserView) -> Bool {
        return showCustomLoading()
    }

    /// 更新 iPad 主导航 Tab 信息
    func updateTemporaryTab() {
        guard !self.isEmbedMode else { return } // 嵌入模式不需要更新
        guard self.isTemporaryChild else { return }
        temporaryTabService.updateTab(self.bottomMostTab)
    }
}

// MARK: - BrowserControllable
extension BrowserViewController: BrowserControllable {
    public var browerEditor: BrowserView? {
        return editor
    }

    public func updateUrl(_ url: URL) {
        let model = Strong<URL>(url)
        self.docsURL = model
    }

    public func setDismissDelegate(_ newDelegate: BrowserViewControllerDelegate?) {
        self.delegate = newDelegate
    }

    public func setToggleSwipeGestureEnable(_ enable: Bool) {
        enablePopGesture(enable)
    }
    
    public func setLandscapeStrategyWhenAppear(_ enable: Bool) {
        self.orientationDirector?.needSetLandscapeWhenAppear = enable
    }
}

// MARK: WebViewScrollViewObserver
extension BrowserViewController: EditorScrollViewObserver {
    public func editorViewScrollViewWillBeginDragging(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        guard editorViewScrollViewProxy.isProxyEqual(editor.scrollViewProxy) else { return }

        if enableFullscreenScrolling {
            animator.beginFullscreenProgress()
        }
    }

    open func _editorViewScrollViewDidScroll(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        guard editorViewScrollViewProxy.isProxyEqual(editor.scrollViewProxy) else { return }
        if enableFullscreenScrolling {
            if animator.isFullScreenInProgress {
                self.updateFullScreenProgress(editorViewScrollViewProxy)
            }
        }
    }

    public func editorViewScrollViewDidEndDragging(_ editorViewScrollViewProxy: EditorScrollViewProxy, willDecelerate decelerate: Bool) {
        guard editorViewScrollViewProxy.isProxyEqual(editor.scrollViewProxy) else { return }
        if !decelerate {
            if enableFullscreenScrolling, animator.isFullScreenInProgress {
                animator.endFullscreenProgress()
            }
        }
    }

    public func editorViewScrollViewDidEndDecelerating(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        guard editorViewScrollViewProxy.isProxyEqual(editor.scrollViewProxy) else { return }
        if enableFullscreenScrolling, animator.isFullScreenInProgress {
            animator.endFullscreenProgress()
        }
    }

    public func editorViewScrollViewDidScrollToTop(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        guard editorViewScrollViewProxy.isProxyEqual(editor.scrollViewProxy) else { return }
        setFullScreenProgress(0)
    }
}

// MARK: - BulletinViewDelegate
extension BrowserViewController: BulletinViewDelegate {
    public func shouldClose(_ bulletinView: BulletinView) {
        guard let info = bulletin.info else { return }
        topContainer.banners.removeItem(bulletin)
        bulletin.info = nil
        bulltinTrack(event: .close(bulletin: info))
        NotificationCenter.default.post(name: DocsBulletinManager.bulletinCloseNotification, object: nil, userInfo: ["id": info.id])
    }

    public func shouldOpenLink(_ bulletinView: BulletinView, url: URL) {
        guard let info = bulletinView.info else { return }
        openBulletinDocs(url)
        bulltinTrack(event: .openLink(bulletin: info))
        NotificationCenter.default.post(name: DocsBulletinManager.bulletinOpenLinkNotification, object: nil, userInfo: ["id": info.id])
    }

    private func openBulletinDocs(_ url: URL) {
        if let type = DocsType(url: url),
            let objToken = DocsUrlUtil.getFileToken(from: url, with: type) {
            let file = SpaceEntryFactory.createEntry(type: type, nodeToken: "", objToken: objToken)
            file.updateShareURL(url.absoluteString)
            let body = SKEntryBody(file)
            userResolver.navigator.docs.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: self)
        } else {
            userResolver.navigator.push(url, from: self)
        }
    }
}

extension BrowserViewController: WatermarkUpdateListener {
    public func didUpdateWatermarkEnable() {
        let shouldShowWatermark = editor.browserInfo.docsInfo?.shouldShowWatermark ?? true
        if watermarkConfig.needAddWatermark != shouldShowWatermark {
            watermarkConfig.needAddWatermark = shouldShowWatermark
        }
    }
}

extension BrowserViewController: ViewControllerSuspendable {

    /// 页面是否支持手势侧划添加（默认为 true）
    /// - 默认值为 true。
    /// - 如果仅用了手势侧划添加，则该页面在侧划关闭时右下角不会出现篮筐，只能通过调用
    /// SuspendManager,shared.addSuspend(::) 方法来添加。
    public var isInteractive: Bool {
        if let url = self.editor.currentURL, let from = url.docs.queryParams?["from"], from == "group_tab_notice" {
            return false
        }
        return true
    }
    /// 页面的唯一 ID，由页面自己实现
    ///
    /// - 同样 ID 的页面只允许收入到浮窗一次，如果该属性被实现为 ID 恒定，则不可重复收入浮窗，
    /// 如果该属性被实现为 ID 变化（如自增），则可以重复收入多个相同页面。
    public var suspendID: String {
        guard let docsInfo = self.docsInfo else {
            spaceAssertionFailure("browser suspendable get docsInfo to be empty")
            return ""
        }
        return docsInfo.token
    }
    /// 悬浮窗展开显示的图标
    public var suspendIcon: UIImage? {
        guard let docsInfo = self.docsInfo else {
            spaceAssertionFailure("browser suspendable get docsInfo to be empty")
            return nil
        }
        if self.editor.userPermissions?.canView() == false {
            return UDIcon.getIconByKey(.fileRoundUnknowColorful, size: CGSize(width: 48, height: 48))
        }
        return docsInfo.iconForSuspendable
    }
    /// 悬浮窗展开显示的标题
    public var suspendTitle: String {
        guard let docsInfo = self.docsInfo else {
            spaceAssertionFailure("browser suspendable get docsInfo to be empty")
            return ""
        }
        if docsInfo.isVersion == true, let name = docsInfo.versionInfo?.name {
            return name
        }
        if self.editor.userPermissions?.canView() == false {
            return BundleI18n.SKResource.LarkCCM_Workspace_ConAccess_NoPerm_Title
        }
        if let title = docsInfo.title, title.count > 0 {
            return title
        }
        if let docName = self.docName, docName.count > 0 {
            return docName
        }
        if docsInfo.titleSecureKeyDeleted == true {
            return BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidTitle
        }
        return docsInfo.inherentType.untitledString
    }
    /// EENavigator 路由系统中的 URL
    ///
    /// 当页面冷恢复时，EENavigator 使用该 URL 来重新构建页面。
    public var suspendURL: String {
        guard let docsInfo = self.docsInfo else {
            spaceAssertionFailure("browser suspendable get docsInfo to be empty")
            return ""
        }
        return docsInfo.urlForSuspendable(originUrl: self.editor.currentURL)
    }
    /// EENavigator 路由系统中的页面参数，用于恢复页面状态
    /// 注意1. 记得添加from参数，由于目前只有CCM这边用到这个参数就没收敛到多任务框架中👀
    /// 注意2. 如果需要添加其他参数记得使用 ["infos":  Any]，因为胶水层只会放回参数里面的infos
    public var suspendParams: [String: AnyCodable] {
        return ["from": "tasklist"]
    }
    /// 多任务列表分组
    public var suspendGroup: SuspendGroup {
        return .document
    }
    /// 页面是否支持热恢复，ps：暂时只需要冷恢复，后续会支持热恢复
    public var isWarmStartEnabled: Bool {
        return false
    }
    /// 是否页面关闭后可重用（默认 true）
    public var isViewControllerRecoverable: Bool {
        return false
    }
    /// 埋点统计所使用的类型名称
    public var analyticsTypeName: String {
        guard let docsInfo = self.docsInfo else {
            spaceAssertionFailure("browser suspendable get docsInfo to be empty")
            return ""
        }
        return docsInfo.type.fileTypeForSta
    }
}

extension BrowserViewController: LarkSplitViewController.SplitViewControllerProxy {
    public func splitViewControllerDidCollapse(_ svc: SplitViewController) {}

    public func splitViewControllerDidExpand(_ svc: SplitViewController) {}

    public func splitViewController(_ svc: SplitViewController, willShow column: SplitViewController.Column) {}

    public func splitViewController(_ svc: SplitViewController, willHide column: SplitViewController.Column) {}

    public func splitViewController(_ svc: SplitViewController, willChangeTo splitMode: SplitViewController.SplitMode) {}

    public func splitViewController(_ svc: SplitViewController, didChangeTo splitMode: SplitViewController.SplitMode) {
        if splitMode == .secondaryOnly, editor.calculateDisplayInfos().mode == .embedded {
            editor.browserChangeFullScreenMode(true)
        }
    }

    public func splitViewControllerInteractivePresentationGestureWillBegin(_ svc: SplitViewController) {}

    public func splitViewControllerInteractivePresentationGestureDidEnd(_ svc: SplitViewController) {}
}

extension TabContainable {
    /// 是否能在 iPad 临时区打开（ tabID 为空时 showTemporary 没有响应）
    public var docsCanOpenInTemporary: Bool {
        return Display.pad && !tabID.isEmpty
    }
}

/// 接入 `TabContainable` 协议后，该页面可由用户手动添加至“底部导航” 和 “快捷导航” 上
extension BrowserViewController: TabContainable {

    /// 页面的唯一 ID，由页面的业务方自己实现
    ///
    /// - 同样 ID 的页面只允许收入到导航栏一次
    /// - 如果该属性被实现为 ID 恒定，SDK 在数据采集的时候会去重
    /// - 如果该属性被实现为 ID 变化（如自增），则会被 SDK 当成不同的页面采集到缓存，展现上就是在导航栏上出现多个这样的页面
    /// - 举个🌰
    /// - IM 业务：传入 ChatId 作为唯一 ID
    /// - CCM 业务：传入 objToken 作为唯一 ID
    /// - OpenPlatform（小程序 & 网页应用） 业务：传入应用的 uniqueID 作为唯一 ID
    /// - Web（网页） 业务：传入页面的 url 作为唯一 ID（为防止url过长，sdk 处理的时候会 md5 一下，业务方无感知
    public var tabID: String {
        // Wiki场景跳过，由WikiContainerVC处理，避免重复添加到最近记录
        // 版本文档场景跳过，由VersionContainerViewController处理，避免重复添加到最近记录
        if docsInfo?.isFromWiki == true {
            return ""
        }
        if shouldRedirect {
            return ""
        }
        if docsInfo?.isVersion == true {
            return ""
        }
        return suspendID
    }

    /// 页面所属业务应用 ID，例如：网页应用的：cli_123455
    ///
    /// - 如果 BizType == WEB_APP 的话 SDK 会用这个 BizID 来给 app_id 赋值
    ///
    /// 目前有些业务，例如开平的网页应用（BizType == WEB_APP），tabID 是传 url 来做唯一区分的
    /// 但是不同的 url 可能对应的应用 ID（BizID）是一样的，所以用这个字段来额外存储
    ///
    /// 所以这边就有一个特化逻辑：
    /// if(BizType == WEB_APP) { uniqueId = BizType + tabID, app_id = BizID}
    /// else { uniqueId = BizType+ tabID, app_id = tabID}
    public var tabBizID: String {
        return ""
    }
    
    /// 页面所属业务类型
    ///
    /// - SDK 需要这个业务类型来拼接 uniqueId
    ///
    /// 现有类型：
    /// - CCM：文档
    /// - MINI_APP：开放平台：小程序
    /// - WEB_APP ：开放平台：网页应用
    /// - MEEGO：开放平台：Meego
    /// - WEB：自定义H5网页
    public var tabBizType: CustomBizType {
        return .CCM
    }

    public var docInfoSubType: Int {
        return docsInfo?.type.rawValue ?? -1
    }

    /// 页面收入到 “底部导航（MainTabBar）” 和 “快捷导航（QuickLaunchWindow）” 上展示的图标（最近使用列表里面也使用同样的图标）
    /// - 如果后期最近使用列表里面要展示不同的图标需要新增一个协议
    public var tabIcon: CustomTabIcon {
        guard let docsInfo = self.docsInfo else {
            spaceAssertionFailure("browser suspendable get docsInfo to be empty")
            return .iconName(.fileUnknowColorful)
        }
        if self.editor.userPermissions?.canView() == false {
            return .iconName(.fileUnknowColorful)
        }
        // 新的自定义icon信息
        if let iconInfo = docsInfo.iconInfo {
            return .iconInfo(iconInfo)
        }
        return .iconName(docsInfo.iconTypeForTabContainable)
    }

    /// 页面收入到 “底部导航（MainTabBar）” 和 “快捷导航（QuickLaunchWindow）” 上展示的标题（最近使用列表里面也使用同样的标题）
    public var tabTitle: String {
        suspendTitle
    }

    /// 页面的 URL 或者 AppLink，路由系统 EENavigator 会使用该 URL 进行页面跳转
    ///
    /// - 当页面冷恢复时，EENavigator 使用该 URL 来重新构建页面
    /// - 对于Web（网页） 业务的话，这个值可能和 tabID 一样
    public var tabURL: String {
        suspendURL
    }
    
    /// 埋点统计所使用的类型名称
    ///
    /// 现有类型：
    /// - private 单聊
    /// - secret 密聊
    /// - group 群聊
    /// - circle 话题群
    /// - topic 话题
    /// - bot 机器人
    /// - doc 文档
    /// - sheet 数据表格
    /// - mindnote 思维导图
    /// - slide 演示文稿
    /// - wiki 知识库
    /// - file 外部文件
    /// - web 网页
    /// - gadget 小程序
    public var tabAnalyticsTypeName: String {
        return "doc"
    }
    
    /// 重新点击临时区域时是否强制刷新（重新从url获取vc）
    ///
    /// - 默认值为false
    public var forceRefresh: Bool {
        //新缓存是否开启，开启则返回true，关闭旧缓存
        if let keepService = userResolver.resolve(PageKeeperService.self), keepService.hasSetting {
            return true
        }
        
        //旧缓存开启
        return false
    }
}

//新的缓存逻辑  setting //
extension BrowserViewController: PagePreservable {
    public var pageID: String {
        self.tabID
    }
    
    public var pageType: LarkQuickLaunchInterface.PageKeeperType {
        .ccm
    }
}

