//
//  ChatPinCardContext.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/5/12.
//

import Foundation
import LarkContainer
import LarkOpenIM
import LarkModel

public final class ChatPinCardContext: BaseModuleContext {
    /// 更新看板（列表）内的 Pin 卡片数据
    public func update(doUpdate: @escaping (ChatPinPayload) -> ChatPinPayload?, completion: ((Bool) -> Void)?) {
        (try? self.userResolver.resolve(assert: ChatOpenPinCardService.self))?.update(doUpdate: doUpdate, completion: completion)
    }

    /// 获取 card content 区域最大宽度
    public var contentAvailableMaxWidth: CGFloat {
        return (try? self.userResolver.resolve(assert: ChatOpenPinCardService.self))?.contentAvailableMaxWidth ?? .zero
    }

    /// 获取 card header(icon + title) 区域最大宽度
    public var headerAvailableMaxWidth: CGFloat {
        return (try? self.userResolver.resolve(assert: ChatOpenPinCardService.self))?.headerAvailableMaxWidth ?? .zero
    }

    /// 重新计算卡片 size && 更新视图
    public func calculateSizeAndUpateView(shouldUpdate: @escaping (Int64, ChatPinPayload?) -> Bool) {
        (try? self.userResolver.resolve(assert: ChatOpenPinCardService.self))?.calculateSizeAndUpateView(shouldUpdate: shouldUpdate)
    }

    /// 刷新整个列表
    public func refresh() {
        (try? self.userResolver.resolve(assert: ChatOpenPinCardService.self))?.refresh()
    }

    public var targetViewController: UIViewController {
        (try? self.userResolver.resolve(assert: ChatOpenPinCardService.self))?.targetViewController ?? UIViewController()
    }
}
