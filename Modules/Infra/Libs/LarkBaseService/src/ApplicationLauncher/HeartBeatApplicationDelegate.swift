//
//  HeartBeatApplicationDelegate.swift
//  Lark
//
//  Created by liuwanlin on 2018/12/4.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import Homeric
import AppContainer
import Swinject
import RxSwift
import RxCocoa
import BootManager
import LKCommonsTracker
import LarkAccountInterface
import LarkContainer

public final class HeartBeatPassportDelegate: PassportDelegate {
    public var name: String = "HeartBeatPassportDelegate"

    // 监听账号切换后的信号
    public var onAccountOffline = BehaviorSubject<Bool>(value: false)

    public func userDidOffline(state: PassportState) {
        onAccountOffline.onNext(true)
    }
}

public final class HeartBeatLauncherDelegate: LauncherDelegate {
    public var name: String = "HeartBeatLauncherDelegate"

    // 监听账号切换后的信号
    public var onAccountOffline = BehaviorSubject<Bool>(value: false)

    init() {}

    /// 退出账号（包括切租户）
    public func afterLogout(context: LauncherContext, conf: LogoutConf) {
        onAccountOffline.onNext(true)
    }
}

public final class HeartBeatApplicationDelegate: ApplicationDelegate {

    static public let config = Config(name: "HeartBeat", daemon: true)

    private var disposeBag = DisposeBag()
    private var disposeBagV1 = DisposeBag()
    /// v2 提供给get_focus_v2使用，为了不破坏get_focus的上报逻辑
    /// 区别于，get_foucs 在退出账号后仍然会进行上报，但此刻关联不到uid
    /// 新的埋点 get_focus_v2 对该问题进行优化，退出账号后会停止计时器
    private var disposeBagV2 = DisposeBag()
    private var isColdStart = true
    @Provider var passport: PassportService // Global

    required public init(context: AppContext) {
        context.dispatcher.add(observer: self) { [weak self] (_, message: DidBecomeActive) in
            guard let `self` = self else { return }
            self.didBecomeActive(message)
            if self.isColdStart {
                /// 过滤掉冷启动，由 HeartBeatTask驱动上报
                self.isColdStart = false
            } else {
                self.triggerFocusV2Event()
            }
        }

        context.dispatcher.add(observer: self) { [weak self] (_, _: DidEnterBackground) in
            self?.disposeBagV1 = DisposeBag()
            self?.disposeBagV2 = DisposeBag()
        }

        let passportService = context.container.resolve(HeartBeatPassportDelegate.self)
        passportService?.onAccountOffline.subscribe(onNext: { [weak self] (isOffline) in
            guard let `self` = self else { return }
            if isOffline {
                self.disposeBagV2 = DisposeBag()
            }
        }).disposed(by: self.disposeBag)

        let launchService = context.container.resolve(HeartBeatLauncherDelegate.self)
        launchService?.onAccountOffline.subscribe(onNext: { [weak self] (isOffline) in
            guard let `self` = self else { return }
            if isOffline {
                self.disposeBagV2 = DisposeBag()
            }
        }).disposed(by: self.disposeBag)
    }

    private func didBecomeActive(_ message: DidBecomeActive) {
        self.trackFocus(true)

        Observable<Int>
            .interval(
                .seconds(60),
                scheduler: SerialDispatchQueueScheduler(
                    queue: DispatchQueue.global(qos: .utility),
                    internalSerialQueueName: "heartbeat")
            )
            .subscribe(onNext: { [weak self] (_) in
                self?.trackFocus(false)
            })
            .disposed(by: self.disposeBagV1)
    }

    private func trackFocus(_ firstTime: Bool) {
        Tracker.post(TeaEvent(Homeric.GET_FOCUS, params: [
            "is_first": firstTime ? "true" : "false"
            ])
        )
    }

    func triggerFocusV2Event() {
        guard passport.foregroundUser != nil else { return }
        self.trackFocusV2(true)

        Observable<Int>
            .interval(
                .seconds(60),
                scheduler: SerialDispatchQueueScheduler(
                    queue: DispatchQueue.global(qos: .utility),
                    internalSerialQueueName: "heartbeatv2")
            )
            .subscribe(onNext: { [weak self] (_) in
                self?.trackFocusV2(false)
            })
            .disposed(by: self.disposeBagV2)
    }

    /// get_focus 存在上报时没有did和uid情况，
    /// 为了修复该问题，但又不影响线上的数据，使用新的事件上报数据进行对比
    /// 若修复有效，又不影响其他数据统计，将替代get_focus
    private func trackFocusV2(_ firstTime: Bool) {
        Tracker.post(TeaEvent(Homeric.GET_FOCUS_V2, params: [
            "is_first": firstTime ? "true" : "false"
            ])
        )
    }
}
