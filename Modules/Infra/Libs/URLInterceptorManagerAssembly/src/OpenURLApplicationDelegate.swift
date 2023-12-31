//
//  OpenURLApplicationDelegate.swift
//  Lark
//
//  Created by liuwanlin on 2018/12/4.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import AppContainer
import LarkContainer
import LarkAccountInterface
import EENavigator
import RxSwift
import RxCocoa

public final class OpenURLApplicationDelegate: ApplicationDelegate {
    static public let config = Config(name: "OpenURL", daemon: true)

    var dispose: DisposeBag = DisposeBag()

    required public init(context: AppContext) {
        context.dispatcher.add(observer: self) { [weak self] (_, message) in
            self?.openURL(message)
        }

        if #available(iOS 13.0, *) {
            context.dispatcher.add(observer: self) { [weak self] (_, message) in
                self?.openSceneURL(message)
            }

            context.dispatcher.add(observer: self) { [weak self] (_, message) in
                self?.openSceneURLWhenConnect(message)
            }
        }
    }

    private func openURL(_ message: OpenURL) {
        if let mainSceneWindow = Navigator.shared.mainSceneWindow { //Global
            URLInterceptorManager.shared.handle(message.url, from: mainSceneWindow, options: message.options)
        } else {
            assertionFailure()
        }
    }

    @available(iOS 13.0, *)
    private func openSceneURL(_ message: SceneOpenURLContexts) {
        if let urlContext = message.urlContexts.first {
            if let windowScene = message.scene as? UIWindowScene {
                URLInterceptorManager.shared.handle(urlContext.url, from: windowScene, options: urlContext.options)
            } else {
                assertionFailure()
            }
        }
    }

    @available(iOS 13.0, *)
    private func openSceneURLWhenConnect(_ message: SceneWillConnectSession) {
        if let urlContext = message.connectionOptions.urlContexts.first {
            if let windowScene = message.scene as? UIWindowScene {
                // 监听账号信息
                AccountServiceAdapter.shared //Gloabl
                    .accountChangedObservable
                    .observeOn(MainScheduler.asyncInstance)
                    .subscribe(onNext: { [weak self] (account) in
                        guard let self = self else { return }
                        if account != nil {
                            self.dispose = DisposeBag()
                            // 不加异步分享发送给自己会导致崩溃，添加 1 秒 delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                URLInterceptorManager.shared.handle(urlContext.url, from: windowScene, options: urlContext.options)
                            }
                        }
                    }).disposed(by: self.dispose)
                // 添加 5 秒超时
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.dispose = DisposeBag()
                }
            } else {
                assertionFailure()
            }
        }
    }
}
