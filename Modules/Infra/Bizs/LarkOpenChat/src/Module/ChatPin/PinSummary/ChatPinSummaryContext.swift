//
//  ChatPinSummaryContext.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/5/12.
//

import Foundation
import LarkContainer
import LarkOpenIM
import LarkModel

public final class ChatPinSummaryContext: BaseModuleContext {
    /// 更新吸顶内的 Pin 卡片数据
    public func update(doUpdate: @escaping (ChatPinPayload) -> ChatPinPayload?, completion: ((Bool) -> Void)?) {
        (try? self.userResolver.resolve(assert: ChatOpenPinSummaryService.self))?.update(doUpdate: doUpdate, completion: completion)
    }
}
