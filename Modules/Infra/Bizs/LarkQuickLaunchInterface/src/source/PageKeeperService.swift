//
//  PageKeeperService.swift
//  LarkKeepAlive
//
//  Created by Yaoguoguo on 2023/9/26.
//

import Foundation

public protocol PageSceneProvider {
    func getSceneBy(id: String) -> PageKeeperScene?
}

public protocol PageKeeperService {

    var hasSetting: Bool { get }

    /// 用于获取是否在场景中：主导航、多任务浮窗
    func setSceneProvider(_ sceneProvider: PageSceneProvider)

    /// 可供查询是否在白名单
    func pageIDInWhiteList(_ id: String, scene: PageKeeperScene) -> Bool

    /// 获取cache，获取到后会从cache中移除
    /// - Parameter id: pageid
    /// - Returns: PagePreservable?
    func popCachePage(id: String, scene: String) -> PagePreservable?

    /// 获取cache
    /// - Parameter id: pageid
    /// - Returns: PagePreservable?
    func getCachePage(id: String, scene: String) -> PagePreservable?

    /// 存Page
    func cachePage(_ page: PagePreservable, with completion: ((Bool) -> Void)?)

    /// 移除Page
    func removePage(_ page: PagePreservable, force: Bool, notice: Bool, with completion: ((Bool) -> Void)?)
}
