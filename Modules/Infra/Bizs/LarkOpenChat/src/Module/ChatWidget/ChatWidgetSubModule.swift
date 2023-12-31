//
//  ChatWidgetSubModule.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/1/9.
//

import Foundation
import RustPB
import LarkModel
import LarkOpenIM

open class ChatWidgetSubModule: Module<ChatWidgetContext, ChatWidgetMetaModel> {
    open var type: RustPB.Im_V1_ChatWidget.WidgetType {
        return .unknown
    }

    /// 解析 widgets response
    open func parseWidgetsResponse(widgetPBs: [RustPB.Im_V1_ChatWidget], response: RustPB.Im_V1_GetChatWidgetsResponse) -> [ChatWidget] {
        return []
    }

    /// 解析 widgets push
    open func parseWidgetsPush(widgetPBs: [RustPB.Im_V1_ChatWidget], push: RustPB.Im_V1_PushChatWidgets) -> [ChatWidget] {
        return []
    }

    /// subModule 初始化后提供时机执行业务方逻辑
    open func setup() {}

    /// 判断 Widget 卡片是否可展示
    open func canShow(_ metaModel: ChatWidgetCellMetaModel) -> Bool {
        return false
    }

    /// 初始化并返回 Widget 卡片 VM
    open func createViewModel(_ metaModel: ChatWidgetCellMetaModel) -> ChatWidgetContentViewModel? {
        return nil
    }
}
