//
//  BrowserViewController+Version.swift
//  SKBrowser
//
//  Created by ByteDance on 2022/9/6.
//

import Foundation
import SKCommon
import SKFoundation
import SKUIKit
import UniverseDesignIcon
import EENavigator
import SKResource
import UniverseDesignEmpty
import SpaceInterface

public protocol VersionChildViewController {
    var displayTitle: String { get }
}

extension BrowserViewController: VersionChildViewController {
    public var displayTitle: String {
        guard let docsInfo = self.docsInfo else {
            spaceAssertionFailure("version suspendable get docsInfo to be empty")
            return ""
        }
        return docsInfo.versionInfo?.name ?? (docsInfo.title ?? docsInfo.originType.i18Name)
    }
}

extension BrowserViewController {
    private static var canShowVersionKey: UInt8 = 0
    public var canShowVersionTitle: Bool {
        get {
            let value = objc_getAssociatedObject(self, &Self.canShowVersionKey) as? Bool ?? false
            return value
        }
        set {
            objc_setAssociatedObject(self, &Self.canShowVersionKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    private static var canShowDelKey: UInt8 = 1
    public var canShowDelEmptyView: Bool {
        get {
            let value = objc_getAssociatedObject(self, &Self.canShowDelKey) as? Bool ?? true
            return value
        }
        set {
            objc_setAssociatedObject(self, &Self.canShowDelKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }
        
    
    /// 文档版本被删除的 EmptyConfig
    public var emptyConfigForDeletedVersion: UDEmptyConfig {
        return UDEmptyConfig(description: .init(descriptionText: BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_Deleted),
                             imageSize: 100,
                             type: .noContent,
                             primaryButtonConfig: (BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_View_Back2Ori_Button, { [weak self] button in
            guard let self = self else { return }
            guard let docsInfo = self.docsInfo, let shareUrl = docsInfo.shareUrl, !shareUrl.isEmpty else {
                DocsLogger.error("openSourceDocs url is nil", component: LogComponents.version)
                return
            }
            DocsLogger.info("goto openSourceDocs", component: LogComponents.version)
            if var components = URLComponents(string: shareUrl) {
                components.query = nil // 移除所有参数
                let finalUrl = components.string
                if finalUrl != nil, let sourceURL = URL(string: finalUrl!) {
                    _ = self.userResolver.docs.editorManager?.requiresOpen(self.editor, url: sourceURL)
                }
            }
            var params = ["click": "back", "target": "none"]
            params.merge(other: DocsParametersUtil.createCommonParams(by: docsInfo))
            if docsInfo.inherentType == .sheet {
                DocsTracker.newLog(enumEvent: .sheetVersionDeletedTipClick, parameters: params)
            } else {
                DocsTracker.newLog(enumEvent: .docsVersionDeletedTipClick, parameters: params)
            }
            }))
    }
    
    public func showVersionsListPanel(dissCallBack: @escaping() -> Void) {
        guard let docsInfo = self.docsInfo else {
            return
        }
        let vm = DocsVersionsPanelViewModel(token: docsInfo.objToken, type: docsInfo.inherentType, fromSource: FromSource.switchVersion)
        let versionPanelVC = DocsVersionViewController(title: BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_View_SwitchV_Mob,
                                                       currentVersionToken: self.docsInfo?.versionInfo?.versionToken, viewModel: vm,
                                                       shouldShowDragBar: !(SKDisplay.pad && editor?.hostView.isMyWindowRegularSize() ?? false))
        versionPanelVC.delegate = self
        versionPanelVC.dismissBlock = dissCallBack
        editor?.uiResponder.resign()
        if SKDisplay.pad, editor?.hostView.isMyWindowRegularSize() ?? false {
            versionPanelVC.modalPresentationStyle = .popover
            versionPanelVC.popoverPresentationController?.sourceView = navigationBar
            versionPanelVC.popoverPresentationController?.sourceRect = CGRect(x: self.getVersionTitlePositionX(), y: navigationBar.frame.minY + navigationBar.frame.height - 16, width: 0, height: 0)
            versionPanelVC.popoverPresentationController?.permittedArrowDirections = .up
            present(versionPanelVC, animated: true, completion: nil)
        } else {
            self.present(versionPanelVC, animated: true, completion: nil)
        }
    }
    
    func getVersionTitlePositionX() -> CGFloat {
        return navigationBar.titleLabel.frame.size.width / 2 + navigationBar.titleLabel.frame.left + navigationBar.titleView.frame.left
    }
    
    public func needHidenCatalogInVesion() -> Bool {
        // 如果是版本，非regular的要隐藏目录
        if self.editor.docsInfo?.isVersion ?? false,
           SKDisplay.pad {
            return self.isMyWindowCompactSize()
        }
        return false
    }
    
    public func deleteVersionCacheData(_ docsInfo: DocsInfo) {
        if docsInfo.isVersion, let versionInfo = docsInfo.versionInfo {
            // 从缓存数据中删除当前的版本数据
            DocsVersionManager.shared.deleteVerisonData(type: docsInfo.inherentType, token: versionInfo.objToken, versionToken: versionInfo.versionToken)
        } else {
            // 从缓存数据中删除当前文档的所有版本数据
            DocsVersionManager.shared.deleteAllVersionData(type: docsInfo.inherentType, token: docsInfo.sourceToken)
        }
    }
    // 收到源文档删除通知
    public func didReceiveVersionDeleteNotification(_ notification: Notification) {
        guard let info = notification.userInfo,
              let cinfo = self.docsInfo,
            let type = info["type"] as? DocsType,
            let token = info["token"] as? String else { return }
        if cinfo.sourceToken == token, cinfo.inherentType == type {
        }
    }
    
    // 收到源文档权限变化
    public func didReceiveVersionPermissionNotification(_ notification: Notification) {
        guard let info = notification.userInfo,
              let cinfo = self.docsInfo,
            let type = info["type"] as? DocsType,
            let token = info["token"] as? String else { return }
        if cinfo.sourceToken == token, cinfo.inherentType == type {
            canShowVersionTitle = false
            lockBasicNavigationMode()
        }
    }
    
    // 收到版本信息更新通知
    public func didReceiveVersionUpdateNotification(_ notification: Notification) {
        guard let cinfo = self.docsInfo,
              cinfo.isVersion
             else { return }
        editor.docsLoader?.updateVersionInfo()
        refreshLeftBarButtons()
        navigationBar.layoutIfNeeded()
    }
    
    // 检查url中token是版本token，要展示失败提示页
    public func didReceiveTokenCheckFailNotification(_ notification: Notification) {
        guard let info = notification.userInfo,
              let cinfo = self.docsInfo,
            let type = info["type"] as? DocsType,
            let token = info["token"] as? String else { return }
        if cinfo.objToken == token, cinfo.inherentType == type {
            DocsLogger.info("didReceiveTokenCheckFailNotification, show error tips", component: LogComponents.version)
            let config = UDEmptyConfig(description: .init(descriptionText: BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_DocNonExist_Mob),
                                       imageSize: 100,
                                       type: .noContent)
            let deleteHintView = UDEmptyView(config: config)
            view.addSubview(deleteHintView)
            view.bringSubviewToFront(deleteHintView)
            deleteHintView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            canShowVersionTitle = false
            lockBasicNavigationMode()
            view.bringSubviewToFront(topContainer)
            self.browerEditor?.setShowTemplateTag(false)
            topContainer.banners.removeAll()
        }
    }
    
    public func checkCanShowVersionName() {
        switch navigationBar.navigationMode {
        case .basic:
            // do nothing
            DocsLogger.info("current navigationMode is Basic, not show version Name", component: LogComponents.version)
        default:
            self.canShowVersionTitle = true
            DocsLogger.info("current navigationMode is not Basic, show version Name", component: LogComponents.version)
        }
    }
}

extension BrowserViewController: DocsVersionPanelDelegate {
    private static var versionKey: UInt8 = 0
    public var parentDelegate: VersionParentVCProtocol? {
        get {
            let value = objc_getAssociatedObject(self, &Self.versionKey) as? VersionParentVCProtocol
            return value
        }
        set {
            objc_setAssociatedObject(self, &Self.versionKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    public func didClickVersion(item: DocsVersionItemData, from: FromSource?) {
        // 从源文档打开要打开新的页面
        guard let parent = self.parentDelegate else {
            guard let urlString = self.browerEditor?.docsInfo?.shareUrl, let vurl = URL(string: urlString) else {
                return
            }
            let sourceURL = vurl.docs.addQuery(parameters: ["edition_id": item.version, "versionfrom": from?.rawValue ?? "unknown"])// 版本需要增加参数
            // 从临时区打开的文档，版本文档也从临时区打开
            guard let vc = self.navigationController else {
                DocsLogger.error("BrowserViewController navigationController is nil")
                return
            }
            if self.isTemporaryChild {
                userResolver.navigator.open(sourceURL, context: ["showTemporary": true], from: vc)
            } else {
                // 从右侧push打开的文档，版本文档从右侧push打开
                userResolver.navigator.open(sourceURL, context: ["showTemporary": false], from: vc)
            }
            return
        }
        guard let urlString = self.browerEditor?.docsInfo?.shareUrl, let vurl = URL(string: urlString) else {
            return
        }
        let sourceURL = vurl.docs.addQuery(parameters: ["edition_id": item.version, "versionfrom": from?.rawValue ?? "unknown"])// 版本需要增加参数
        // 从临时区打开的文档，版本文档也从临时区打开
        guard let vc = self.navigationController else {
            DocsLogger.error("BrowserViewController navigationController is nil")
            return
        }
        if self.isTemporaryChild {
            userResolver.navigator.open(sourceURL, context: ["showTemporary": true], from: vc)
            return
        }
        // 在当前containerVC切换
        parent.didChangeVersionTo(item: item, from: from)
    }
    
    public func getDocsTrackCommonParams() -> [String: Any]? {
        guard let docInfo = self.docsInfo else {
            return nil
        }
        return DocsParametersUtil.createCommonParams(by: docInfo)
    }
}
