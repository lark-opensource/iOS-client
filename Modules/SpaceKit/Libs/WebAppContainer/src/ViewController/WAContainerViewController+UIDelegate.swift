//
//  WAContainerViewController+Delegate.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/30.
//

import Foundation
import EENavigator
import LarkUIKit

extension WAContainerViewController: WAContainerUIDelegate {
    public func onLoadStatusChange(old: WALoadStatus, new: WALoadStatus) {
        switch new {
        case .loading:
            guard viewModel.config.openConfig?.showLoading ?? false else {
                emptyView.hide()
                return
            }
            emptyView.show(type: .loading)
        case .success:
            emptyView.hide()
        case let .error(waError):
            if case let .webError(showPage, _) = waError, !showPage {
                emptyView.hide()
                return
            }
            emptyView.show(type: .error(type: waError, clickHandler: { [weak self] in
                self?.viewModel.refresh()
            }))
        case .cancel, .start:
            emptyView.hide()
        case .overtime:
            emptyView.show(type: .error(type: .overtime, clickHandler: { [weak self] in
                self?.viewModel.refresh()
            }))
        }
    }
    
    public func updateTitleBar(_ titleBarConfig: WATitleBarConfig, target: AnyObject, selector: Selector) {
        self.titleNaviBar.update(titleBarConfig: titleBarConfig, target: target, selector: selector)
        
        self.hasSetCustomTitleBar = true
    }
    
    public func updateTitle(_ title: String?) {
        self.titleNaviBar.navigationBar.title = title
    }
    
    public func openUrl(_ url: URL) {
        Navigator.shared.showDetailOrPush(url, context: ["showTemporary": false], from: self, animated: true)
    }
    
    public func goBackPage() {
        var hasWebBack = false
        if self.contentView.webview.canGoBack {
            hasWebBack = self.contentView.webview.goBack() != nil
            Self.logger.info("try goback in webview:\(hasWebBack)")
        }
        Self.logger.info("onGoBack")
        if !hasWebBack {
            self.back()
        }
    }
    
    public func refreshPage() {
        self.viewModel.refresh()
    }
    
    public func closePage() {
        self.back()
    }
}
