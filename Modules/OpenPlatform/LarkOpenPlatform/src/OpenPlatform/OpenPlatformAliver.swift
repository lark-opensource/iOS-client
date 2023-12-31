//
//  OpenPlatformAliver.swift
//  LarkOpenPlatform
//
//  Created by tujinqiu on 2020/2/27.
//

import UIKit
import Swinject
import LarkSDKInterface
import RxSwift
import LarkContainer

/// 这个对象需要保活
class OpenPlatformAliver {
    private let resolver: UserResolver
    private let disposeBag = DisposeBag()
    private var setupDone = false
    private var speedClockIn: SpeedClockIn?

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func setup() {
        if setupDone {
            return
        }
        setupDone = true
        setupOnce()
    }

    private func setupOnce() {
        speedClockIn = SpeedClockIn(resolver: resolver)
        speedClockIn?.start()
        try? resolver.userPushCenter.observable(for: PushDynamicNetStatus.self).subscribe(onNext: { (push) in
            OpenPlatformUtil.netStatus = push.dynamicNetStatus
        }).disposed(by: disposeBag)
    }
}
