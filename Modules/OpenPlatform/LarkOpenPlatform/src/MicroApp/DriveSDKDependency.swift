//
//  DriveSDKDependency.swift
//  LarkOpenPlatform
//
//  Created by zhaojingxin on 2022/4/7.
//

import SpaceInterface
import RxSwift
import UIKit
/*
 DriveSDK 注入配置
 https://bytedance.feishu.cn/wiki/wikcn5UXLpQ4Hf7Jfdq9yazHN0d#
 */

// MARK: - Local File

class LocalPreviewFullscreenNavigationViewController: UINavigationController {
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        self.modalPresentationStyle = .overFullScreen
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
}

/// [更多]行为 配置
struct MoreDependencyImpl: DriveSDKMoreDependency {
    private let showing: Bool
    private let action: ((UIViewController) -> (Void))?

    var moreMenuVisable: Observable<Bool> { return .just(showing) }
    var moreMenuEnable: Observable<Bool> { return .just(showing) }
    var actions: [DriveSDKMoreAction] { return [.customOpenWithOtherApp(customAction: action, callback: nil)] }

    init(showing: Bool, action: ((UIViewController) -> (Void))?) {
        self.showing = showing
        self.action = action
    }
}

/// 其他行为 配置
struct ActionDependencyImpl: DriveSDKActionDependency {

    private var closeSubject = PublishSubject<Void>()
    private var stopSubject = PublishSubject<Reason>()

    var closePreviewSignal: Observable<Void> { return closeSubject.asObserver() }
    var stopPreviewSignal: Observable<Reason> { return stopSubject.asObserver() }
}

/// 默认本地预览文件 配置
struct DefaultLocalDependencyImpl: DriveSDKDependency {

    private let more: DriveSDKMoreDependency
    private let action: DriveSDKActionDependency

    var actionDependency: DriveSDKActionDependency { return action }
    var moreDependency: DriveSDKMoreDependency { return more }

    init(showMore: Bool, moreAction: ((UIViewController) -> (Void))?) {
        more = MoreDependencyImpl(showing: showMore, action: moreAction)
        action = ActionDependencyImpl()

    }
}
