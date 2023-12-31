//
//  ChatPinSummaryCellViewModel.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/5/12.
//

import Foundation
import LarkOpenIM
import RustPB

open class ChatPinSummaryCellViewModel: Module<ChatPinSummaryContext, ChatPinSummaryCellMetaModel> {
    open class var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        assertionFailure("need override")
        return .unknown
    }

    // MARK: 数据更新
    open override func modelDidChange(model: ChatPinSummaryCellMetaModel) {}

    // MARK: 返回摘要信息
    open func getSummaryInfo() -> (attributedTitle: NSAttributedString, iconConfig: ChatPinIconConfig?) {
        assertionFailure("need override")
        return (NSAttributedString(string: ""), ChatPinIconConfig(iconResource: .image(.just(UIImage()))))
    }

    // MARK: 点击事件
    open func onClick() {}
}
