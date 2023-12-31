//
//  ChatKeyboardTopExtendContext.swift
//  LarkOpenChat
//
//  Created by zc09v on 2021/8/9.
//

import Foundation
import Swinject
import LarkOpenIM
import LarkContainer

public final class ChatKeyboardTopExtendContext: BaseModuleContext {
    @available(*, deprecated, message:"废弃，可使用refresh()")
    public func refresh(type: ChatKeyboardTopExtendType) {
        DispatchQueue.main.async { [weak self] in
            try? self?.resolver.resolve(assert: ChatOpenKeyboardTopExtendService.self).refresh()
        }
    }

    public func refresh() {
        DispatchQueue.main.async { [weak self] in
            try? self?.resolver.resolve(assert: ChatOpenKeyboardTopExtendService.self).refresh()
        }
    }
}
