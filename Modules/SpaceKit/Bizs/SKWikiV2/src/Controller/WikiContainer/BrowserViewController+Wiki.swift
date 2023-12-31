//
//  BrowserViewController+Wiki.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/6/3.
//  

import Foundation
import SKCommon
import SKBrowser
import SKFoundation
import SKUIKit
import UniverseDesignIcon
import RxSwift

// MARK: - support wiki
extension BrowserViewController: WikiBizChildViewController {
    public var displayTitle: String {
        guard let docsInfo = self.docsInfo else {
            spaceAssertionFailure("wiki suspendable get docsInfo to be empty")
            return ""
        }
        if docsInfo.isVersion, let name = docsInfo.versionInfo?.name {
            return name
        }
        if let title = docsInfo.title {
            return title
        }
        if let docName = self.docName {
            return docName
        }
        return docsInfo.title ?? docsInfo.inherentType.i18Name
    }
    public var permissionObservable: Observable<Bool> {
        return .never()
    }
    
    public var restoreSuccessObservable: Observable<Bool> {
        self.restoreSuccessRelay.asObservable()
    }
    
    public var wikiNodeDeletedObservable: Observable<Bool> {
        return .never()
    }

    public func configWikiTreeItem(_ item: SKBarButtonItem) {
        let curItems = self.navigationBar.leadingBarButtonItems

        let treeItem = curItems.first(where: { (curItem) -> Bool in
            return curItem.id == item.id
        })
        if treeItem == nil {
            navigationBar.leadingBarButtonItems = curItems + [item]
        } else {
            treeItem?.isEnabled = item.isEnabled // 如果已存在，更新enable状态
            navigationBar.leadingBarButtonItems = curItems
        }
        navigationBar.setNeedsLayout()
    }
    
    public func hiddenWikiTreeItem(_ item: SKBarButtonItem) {
        var curItems = self.navigationBar.leadingBarButtonItems
        
        curItems.removeAll { (curItem) -> Bool in
            return curItem.id == item.id
        }
        navigationBar.leadingBarButtonItems = curItems
        navigationBar.setNeedsLayout()
    }
    
    public func showFailed() {
        addDeletedViewForWikiShortcut()
    }
}
