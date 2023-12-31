//
//  DKMainViewController+Wiki.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/5.
//

import Foundation
import SKCommon
import SKUIKit
import SKFoundation
import RxSwift
import RxRelay
// MARK: - support wiki
extension DKMainViewController: WikiBizChildViewController {
    var displayTitle: String {
        guard let host = viewModel.hostModule else { return "" }
        return host.docsInfoRelay.value.title ?? host.docsInfoRelay.value.type.i18Name
    }
    
    var wikiNodeDeletedObservable: Observable<Bool> {
        let deleteRelay = BehaviorRelay<Bool>(value: false)
        guard let host = viewModel.hostModule else { return .never() }
        host.subModuleActionsCenter.subscribe(onNext: { action in
            if case let .wikiNodeDeletedStatus(isDelete) = action {
                deleteRelay.accept(isDelete)
            }
        }).disposed(by: bag)
        return deleteRelay.asObservable()
    }
    var permissionObservable: Observable<Bool> {
        guard let host = viewModel.hostModule else { return .never() }
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            return host.permissionService.onPermissionUpdated.map { [weak host] _ in
                return host?.permissionService.validate(operation: .view).allow ?? false
            }
        } else {
            return host.permissionRelay.map { $0.isReadable }
        }
    }
    
    var restoreSuccessObservable: Observable<Bool> {
        guard let host = viewModel.hostModule else {
            return .never()
        }
        return host.subModuleActionsCenter.map {
            if case .resotreSuccess = $0 {
                return true
            }
            return false
        }.asObservable()
    }

    func configWikiTreeItem(_ item: SKBarButtonItem) {
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
    
    func hiddenWikiTreeItem(_ item: SKBarButtonItem) {
        var curItems = self.navigationBar.leadingBarButtonItems
        
        curItems.removeAll { (curItem) -> Bool in
            curItem.id == item.id
        }
        navigationBar.leadingBarButtonItems = curItems
        navigationBar.setNeedsLayout()
    }
    
    func showFailed() {}
}
