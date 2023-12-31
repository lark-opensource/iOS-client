//
//  CCMFileDependencyImpl.swift
//  SKCommon
//
//  Created by bupozhuang on 2021/11/23.
//

import Foundation
import SpaceInterface
import RxSwift

public struct CCMFileDependencyImpl: DriveSDKDependency {
    public init() { }
    // 配置更多功能选项
    struct MoreDependencyImpl: DriveSDKMoreDependency {
        var moreMenuVisable: Observable<Bool> {
            return .just(true)
        }
        var moreMenuEnable: Observable<Bool> {
            return .just(true)
        }
        var actions: [DriveSDKMoreAction] {
            return [.saveToLocal(handler: { _, _  in }),
                    .customOpenWithOtherApp(customAction: nil, callback: nil),
                    .saveToSpace(handler: { _ in })]
        }
    }
    // 配置外部控制事件
    struct ActionDependencyImpl: DriveSDKActionDependency {
        var closePreviewSignal: Observable<Void> {
            return .never()
        }
        
        var stopPreviewSignal: Observable<Reason> {
            return .never()
        }
        
        var uiActionSignal: Observable<DriveSDKUIAction> {
            return .never()
        }
    }

    public var actionDependency: DriveSDKActionDependency {
        return ActionDependencyImpl()
    }
    public var moreDependency: DriveSDKMoreDependency {
        return MoreDependencyImpl()
    }
}
