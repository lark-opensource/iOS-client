//
//  BTLocalAttachmentPreview.swift
//  SKBitable
//
//  Created by zhouyuan on 2021/9/6.
//

import Foundation
import RxSwift
import SKCommon
import SpaceInterface

struct BTLocalDependencyImpl: DriveSDKDependency {
    let more = LocalMoreDependencyImpl()
    let action = ActionDependencyImpl()
    var actionDependency: DriveSDKActionDependency {
        return action
    }
    var moreDependency: DriveSDKMoreDependency {
        return more
    }
}

struct LocalMoreDependencyImpl: DriveSDKMoreDependency {
    var moreMenuVisable: Observable<Bool> {
        return .just(true)
    }
    var moreMenuEnable: Observable<Bool> {
        return .just(true)
    }
    var actions: [DriveSDKMoreAction] {
        return [.customOpenWithOtherApp(customAction: nil, callback: nil)]
    }
}

struct ActionDependencyImpl: DriveSDKActionDependency {
    var uiActionSignal: RxSwift.Observable<SpaceInterface.DriveSDKUIAction> {
        return .never()
    }
    private var closeSubject = PublishSubject<Void>()
    private var stopSubject = PublishSubject<Reason>()
    var closePreviewSignal: Observable<Void> {
        return closeSubject.asObserver()
    }

    var stopPreviewSignal: Observable<Reason> {
        return stopSubject.asObserver()
    }
}
