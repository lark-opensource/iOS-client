//
//  SnsHandleOpenURLDelegate.swift
//  LarkSnsShare
//
//  Created by shizhengyu on 2020/3/19.
//

import Foundation
import AppContainer

public final class SnsHandleOpenURLDelegate: ApplicationDelegate {
    static public let config = Config(name: "SnsHandleOpenURL", daemon: true)

    required public init(context: AppContext) {
        context.dispatcher.add(observer: self) { [weak self] (_, message) in
            self?.openURL(message)
        }
        if #available(iOS 13.0, *) {
            context.dispatcher.add(observer: self) { [weak self] (_, message) in
                self?.openSceneURL(message)
            }
        }
    }

    private func openURL(_ message: OpenURL) {
        LarkShareBasePresenter.shared.handleOpenURL(message.url)
    }

    @available(iOS 13.0, *)
    private func openSceneURL(_ message: SceneOpenURLContexts) {
        if let urlContext = message.urlContexts.first {
            LarkShareBasePresenter.shared.handleOpenURL(urlContext.url)
        }
    }

    /// NOTE:
    /// 下面的 AppLink 监听回调暂不执行。
    /// 原因：ContinueUserActivity message 在 AppLink sdk 内会进行「不支持页面」webview 的降级处理跳转，这并不符合预期。
    /// 因此需要暂时将对应处理收敛在一处，使用sdk的handleUniversalLink方法去拦截
    /// 等待开放平台那边实现了针对某个Applink URL进行注册并支持自定义拦截后，将下面逻辑收敛在 LarkSnsShare 内
    private func continueUserActivity(_ userActivity: NSUserActivity) {
        LarkShareBasePresenter.shared.handleOpenUniversalLink(userActivity)
    }
}
