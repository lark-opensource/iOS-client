//
//  ChatBannerContext.swift
//  LarkOpenChat
//
//  Created by 李勇 on 2020/12/8.
//

import Foundation
import Swinject
import LarkOpenIM
import LarkContainer

public final class ChatBannerContext: BaseModuleContext {
    /// 重新对subModules执行canHandle-handler，重新加载一次视图
    public func reloadModuleIfNeeded() {
        DispatchQueue.main.async { [weak self] in
            try? self?.resolver.resolve(assert: ChatOpenBannerService.self).reload()
        }
    }

    /// 对已handle的subModule重新加载一次视图
    public func refresh() {
        DispatchQueue.main.async { [weak self] in
            try? self?.resolver.resolve(assert: ChatOpenBannerService.self).refresh()
        }
    }
}
