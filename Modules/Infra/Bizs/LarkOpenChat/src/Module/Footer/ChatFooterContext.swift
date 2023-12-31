//
//  ChatFooterContext.swift
//  LarkOpenChat
//
//  Created by Zigeng on 2022/7/7.
//

import Foundation
import Swinject
import LarkOpenIM
import LarkContainer

public final class ChatFooterContext: BaseModuleContext {
    public func refresh() {
        DispatchQueue.main.async { [weak self] in
            try? self?.resolver.resolve(assert: ChatOpenFooterService.self).refresh()
        }
    }
}
