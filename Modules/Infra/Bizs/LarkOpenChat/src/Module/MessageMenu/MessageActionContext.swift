//
//  MessageActionContext.swift
//  LarkOpenChat
//
//  Created by Zigeng on 2023/1/18.
//

import Foundation
import Swinject
import LarkMessageBase
import UIKit
import LarkContainer

public class MessageActionContext: BaseModuleContext {
    /// 消息操作拦截器
    public let interceptor: MessageActionInterceptor
    /// 按钮操作依赖的页面级能力
    public weak var pageAPI: PageAPI? {
        if let pageAPI = try? self.resolver.resolve(assert: ChatMessagesOpenService.self).pageAPI {
            return pageAPI
        } else {
            return nil
        }
    }
    /// 按钮操作宿主VC
    public weak var targetVC: UIViewController? { pageAPI }

    public init(parent: Container,
                store: Store,
                interceptor: MessageActionInterceptor,
                userStorage: UserStorage, compatibleMode: Bool = false) {
        self.interceptor = interceptor
        super.init(parent: parent, store: store,
                   userStorage: userStorage, compatibleMode: compatibleMode)
    }
}

public final class PrivateThreadMessageActionContext: MessageActionContext {
    public let originMergeForwardId: String
    public init(parent: Container,
                store: Store,
                originMergeForwardId: String,
                interceptor: MessageActionInterceptor,
                userStorage: UserStorage, compatibleMode: Bool = false
                ) {
        self.originMergeForwardId = originMergeForwardId
        super.init(parent: parent, store: store, interceptor: interceptor,
                   userStorage: userStorage, compatibleMode: compatibleMode)
    }
}
