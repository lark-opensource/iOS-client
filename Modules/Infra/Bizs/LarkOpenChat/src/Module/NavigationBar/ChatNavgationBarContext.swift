//
//  ChatNavgationBarContext.swift
//  LarkOpenChat
//
//  Created by zc09v on 2021/10/12.
//

import UIKit
import Foundation
import Swinject
import LarkBadge
import LarkOpenIM
import LarkContainer
import LarkMessageBase

public final class ChatNavgationBarContext: BaseModuleContext {
    public let interceptor: ChatNavigationInterceptor
    public init(parent: Container,
                store: Store,
                interceptor: ChatNavigationInterceptor,
                userStorage: UserStorage, 
                compatibleMode: Bool = false) {
        self.interceptor = interceptor
        super.init(parent: parent, store: store,
                   userStorage: userStorage, compatibleMode: compatibleMode)
    }
    public func chatVC() -> UIViewController {
        return (try? self.resolver.resolve(assert: ChatOpenService.self).chatVC()) ?? UIViewController()
    }

    public lazy var chatRootPath: Path = {
        return (try? self.resolver.resolve(assert: ChatOpenService.self).chatPath) ?? Path()
    }()

    /// 当前chat的选择模式(普通or多选)
    public func currentSelectMode() -> ChatSelectMode {
        return (try? self.resolver.resolve(assert: ChatOpenService.self).currentSelectMode()) ?? .normal
    }

    /// 重新刷新导航栏
    public func refresh() {
        self.performOnMainThread { [weak self] in
            try? self?.resolver.resolve(assert: ChatOpenNavigationService.self).refresh()
        }
    }

    public func refreshLeftItems() {
        /// 重新刷新导航栏
        self.performOnMainThread { [weak self] in
            try? self?.resolver.resolve(assert: ChatOpenNavigationService.self).refreshLeftItems()
        }
    }

    /// 重新刷新导航栏右侧按钮区
    public func refreshRightItems() {
        self.performOnMainThread { [weak self] in
            try? self?.resolver.resolve(assert: ChatOpenNavigationService.self).refreshRightItems()
        }
    }

    /// 刷新content
    public func refreshContent() {
        self.performOnMainThread { [weak self] in
            try? self?.resolver.resolve(assert: ChatOpenNavigationService.self).refreshCenterContent()
        }
    }

    /// 获取当前navgation的展示样式
    public func navigationBarDisplayStyle() -> OpenChatNavigationBarStyle {
        return (try? self.resolver.resolve(assert: ChatOpenNavigationService.self).navigationBarDisplayStyle()) ?? .lightContent
    }

    private func performOnMainThread(_ block: @escaping (() -> Void)) {
        if Thread.current.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}
