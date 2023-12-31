//
//  SpaceListAutoRefresher.swift
//  SKECM
//
//  Created by Weston Wu on 2020/7/26.
//

import Foundation
import SKCommon

protocol SpaceListAutoRefresher {
    typealias RefreshDataHandler = (Result<FileDataDiff, Error>) -> Void
    typealias RefreshActionHandler = (@escaping RefreshDataHandler) -> Void
    typealias NotifyRefreshHandler = (@escaping RefreshActionHandler, Bool) -> Void
    /// 处理 refresher 的 Action
    var actionHandler: NotifyRefreshHandler? { get set }
    /// 配置自动刷新组件
    func setup()
    /// 开始自动刷新
    func start()
    /// 停止自动刷新
    func stop()
    /// 通知用户手动下拉刷新当前列表
    func notifySyncEvent()
    /// 通知文件被用户删除
    func notifyFileDeleted(token: FileListDefine.ObjToken)
}
