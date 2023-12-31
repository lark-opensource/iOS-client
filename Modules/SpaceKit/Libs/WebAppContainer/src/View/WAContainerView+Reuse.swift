//
//  WAContainerView+Reuse.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/12/4.
//

import Foundation

extension WAContainerView: WAResuableItem {

    var appName: String { self.viewModel.config.appName }
    
    var canResue: Bool { self.inPool }
    
    func startCheckAlive() {
        /*
         Alive存活逻辑
         - 预加载Webview后在存活时间内没有使用，则销毁
         - 退出页面后，Webview不会立即销毁，而是缓存起来（最多缓存1个），在存活时间之后销毁，如果期间被复用了，则重新计时
         */
        guard let aliveDuration = self.viewModel.config.webviewConfig?.aliveDuration, aliveDuration > 0 else {
            Self.logger.info("dont startCheckAlive,\(self.identifier)")
            return
        }
        let delayMS = aliveDuration / 1000
        Self.logger.info("startCheckAlive after:\(delayMS),\(self.identifier)")
        self.perform(#selector(checkAlive), with: nil, afterDelay: TimeInterval(delayMS))

    }
    
    func stopCheckAlive() {
        Self.logger.info("stopCheckAlive,\(self.identifier)")
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(checkAlive), object: nil)
    }
    
    @objc func checkAlive() {
        if !self.viewModel.isAttachOnPage {
            Self.logger.info("checkAlive...,container not open, destroy it,\(self.identifier)")
            if let preloader = try? self.viewModel.userResolver.resolve(assert: WAContainerPreloader.self) {
                preloader.pool.removeItem(for: self.appName)
            }
        } else {
            Self.logger.info("checkAlive...,container opening, do nothing,\(self.identifier)")
        }
    }
}

