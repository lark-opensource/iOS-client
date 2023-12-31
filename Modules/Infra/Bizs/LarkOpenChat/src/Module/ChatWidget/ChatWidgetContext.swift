//
//  ChatWidgetContext.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/1/9.
//

import UIKit
import Foundation
import LarkContainer
import LarkOpenIM
import LarkModel

public final class ChatWidgetContext: BaseModuleContext {
    public func update(doUpdate: @escaping (ChatWidget) -> ChatWidget?, completion: ((Bool) -> Void)?) {
        try? self.resolver.resolve(assert: ChatOpenWidgetService.self).update(doUpdate: doUpdate, completion: completion)
    }

    public var containerSize: CGSize {
        return (try? self.resolver.resolve(assert: ChatOpenWidgetService.self).containerSize) ?? .zero
    }

    public func refresh() {
        try? self.resolver.resolve(assert: ChatOpenWidgetService.self).refresh()
    }
}
