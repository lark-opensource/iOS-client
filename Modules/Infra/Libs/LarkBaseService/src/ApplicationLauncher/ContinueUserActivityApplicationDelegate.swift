//
//  ContinueUserActivityApplicationDelegate.swift
//  LarkApp
//
//  Created by yinyuan on 2019/8/26.
//

import UIKit
import Foundation
import AppContainer
import EENavigator
import LarkContainer
import LarkSnsShare
import RxSwift
import LarkAccountInterface

public final class ContinueUserActivityApplicationDelegate: ApplicationDelegate {
    @Provider var passport: PassportService // Global

    static public let config = Config(name: "ContinueUserActivity", daemon: true)

    var dispose: DisposeBag = DisposeBag()

    required public init(context: AppContext) {
        context.dispatcher.add(observer: self) { [weak self] (_, message) in
            self?.continueUserActivity(message)
        }

        if #available(iOS 13.0, *) {
            context.dispatcher.add(observer: self) { [weak self] (_, message) in
                self?.continueSceneUserActivity(message)
            }

            context.dispatcher.add(observer: self) { [weak self] (_, message) in
                self?.sceneWillConnectToUserActivity(message)
            }
        }
    }

    private func continueUserActivity(_ message: ContinueUserActivity) {
        if let mainSceneWindow = Navigator.shared.mainSceneWindow {
            continueUserActivity(userActivity: message.userActivity, from: mainSceneWindow)
        } else {
            assertionFailure()
        }
    }

    @available(iOS 13.0, *)
    private func continueSceneUserActivity(_ message: SceneContinueUserActivity) {
        if let windowScene = message.scene as? UIWindowScene {
            continueUserActivity(userActivity: message.userActivity, from: windowScene)
        } else {
            assertionFailure()
        }
    }

    @available(iOS 13.0, *)
    private func sceneWillConnectToUserActivity(_ message: SceneWillConnectSession) {
        /// 监听账号信息,一定要账号登录后才能开始push，否则会push不出来
        /// 这里已知两个问题，导致这里需要写临时代码
        /// 问题1: Lark启动流程存在异常，在流程中存在将rootVC设置为nil的异步操作，现在这个问题杨京已经正在解决，所以我们这里需要写成这样子的异步操作
        /// 问题2:AccountServiceAdapter的accountChangedObservable事件发出的时候，rootVC是登录的VC，不是首页VC，所以我们延迟1s，否则会在错误的VC弹出，这个只需要等待问题1解决之后，就可以在这里写同步代码，就可以绕开问题2了
        if let windowScene = message.scene as? UIWindowScene {
            if !message.connectionOptions.userActivities.isEmpty {
                passport.state
                    .observeOn(MainScheduler.asyncInstance)
                    .subscribe(onNext: { [weak self] (state) in
                        guard let self = self, state.user != nil, state.loginState == .online else { return }

                        self.dispose = DisposeBag()
                        /// 这里需要延迟1s，否则会找不到正确的VC
                        /// 因为如果是冷启动，如果用户没有登录，那么会先登录， 登录完成之后会马上发出这个消息
                        /// 但是这个时候的rootVC是登录的VC，不是首页VC，会在错误的VC弹出，所以延迟1s
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            message.connectionOptions.userActivities.forEach {
                                self.continueUserActivity(userActivity: $0, from: windowScene)
                            }
                        }
                    }).disposed(by: self.dispose)
            }
        } else {
            assertionFailure()
        }
    }

    private func continueUserActivity(userActivity: NSUserActivity, from: NavigatorFrom) {
        // 目前的分布式Application Event响应不太好支持多个注册方去通信
        // 先将分享sdk的applink唤起lark逻辑放在applink通用逻辑前做拦截
        // 等applink服务支持自定义拦截注册后，再讲handle收敛到LarkSnsShare中
        if LarkShareBasePresenter.shared.handleOpenUniversalLink(userActivity) {
            return
        }
        // 支持 Universal Links
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL {
            // 采用与 OpenURL 相同的处理逻辑
            URLInterceptorManager.shared.handle(url, from: from, options: [:])
        }
    }
}
