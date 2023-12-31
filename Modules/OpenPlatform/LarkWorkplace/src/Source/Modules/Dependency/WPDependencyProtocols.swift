//
//  WorkPlaceDependencyProtocols.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/3/23.
//

import Foundation
import Swinject
import RxSwift
import Photos
import RustPB
import WebBrowser
import LarkSetting
import UIKit
import LarkWorkplaceModel

/// 聚合协议，方便注册与接口拆分
public protocol WorkPlaceDependency: WorkPlaceDependencyShare,
                                     WorkPlaceDependencyBadge,
                                     WorkPlaceDependencyNavigation {}

// MARK: - share
/// 分享依赖
public protocol WorkPlaceDependencyShare {
    /// 应用分享
    func shareAppFromWorkplaceAppCard(with appId: String, from: UIViewController)

    /// 纯链接分享
    /// - Parameters:
    ///   - link: 链接原文
    ///   - from: from
    ///   - sentHandler: 分享回调 (userIds, chatIds)
    func sharePureLink(with link: String, from: UIViewController, sentHandler: @escaping ([String], [String]) -> Void)

    func shareBlockCard(from: UIViewController, shareTaskGenerator: @escaping ([WPMessageReceiver], String?) -> Observable<[String]>?)
}

// MARK: - badge
/// badge依赖
public protocol WorkPlaceDependencyBadge {
    /// 更新 Badge
    func update(appID: String, badgeEnable: Bool)

    /// 拉取 Badge
    func pull(appID: String)
}

// MARK: - navigation
/// WPChatInfo
public struct WPChatInfo {
    /// userId
    public let userId: String
    /// from
    public var from: UIViewController?
    /// disposeBag
    public let disposeBag: DisposeBag
}

/// navigator依赖
public protocol WorkPlaceDependencyNavigation {
    /// toChat
    func toChat(_ info: WPChatInfo, completion: ((Bool) -> Void)?)

    /// 跳转到大搜
    func toMainSearch(from: UIViewController)

    /// 进入网络诊断工具页面
    func showDiagnoseSettingVC(from: UIViewController)
}
