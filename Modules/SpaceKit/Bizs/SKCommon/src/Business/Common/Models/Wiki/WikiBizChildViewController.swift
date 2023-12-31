//
//  WikiBizChildViewController.swift
//  SKCommon
//
//  Created by bupozhuang on 2021/8/5.
//

import Foundation
import SKUIKit
import RxSwift

public protocol WikiBizChildViewController {
    var displayTitle: String { get }
    // 仅作为wiki容器获取drive权限使用
    var permissionObservable: Observable<Bool> { get }
    // 被删除文档恢复成功通知
    var restoreSuccessObservable: Observable<Bool> { get }
    // wiki节点被删除的通知
    var wikiNodeDeletedObservable: Observable<Bool> { get }
    func configWikiTreeItem(_ item: SKBarButtonItem)
    func hiddenWikiTreeItem(_ item: SKBarButtonItem)
    // wiki失败兜底页面
    func showFailed()
}
