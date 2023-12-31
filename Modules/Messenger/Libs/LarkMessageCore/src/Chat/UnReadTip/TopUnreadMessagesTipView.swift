//
//  TopUnreadMessagesTipView.swift
//  Lark
//
//  Created by zc09v on 2018/5/15.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel
import RxSwift
import RxCocoa

public final class TopUnreadMessagesTipView: BaseUnReadMessagesTipView {
    override class var tipType: String { return "Top" }
    public override init(chat: Chat, viewModel: BaseUnreadMessagesTipViewModel) {
        super.init(chat: chat, viewModel: viewModel)
        self.tipContent.direct = .up
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private var clickIndentify: Int32 = 0
    @objc
    override func tipButtonClick() {
        //loading中不接收再次点击
        if loadingInfo.isLoading {
            return
        }
        clickIndentify += 1
        let currentclickIndentify = clickIndentify
        let chatId = self.chat.id
        switch unReadTipState {
        case .dismiss, .showToLastMessage:
            break
        case .showUnReadAt(let message, _):
            BaseUnreadMessagesTipViewModel.logger.info("chatTrace unreadTip buttonClick scrollTo start \(chatId)")
            loadingInfo = (true, message.position)
            delegate?.scrollTo(message: message, tipView: self, finish: { [weak self] in
                /* badge清0会触发dismiss，dismiss需要loadingInfo = false。此处需要做延迟，尽量不要过早触发，否则电梯ui上就会出现短暂的loading先消失，但未读数还在
                 1. 如果此处延迟回调,早于badge清0触发dismiss: 电梯ui上就会出现短暂的loading先消失，但未读数还在，这个概率、影响不大(不会有逻辑问题)
                 2. 如果此处延迟回调,晚于badge清0触发dismiss: 此时电梯可能已经进入了新的状态，要保证回调里不要非预期重置loadingInfo，靠clickIndentify维护对应关系
                 */
                BaseUnreadMessagesTipViewModel.logger.info("chatTrace unreadTip buttonClick scrollTo callback \(chatId)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if currentclickIndentify == self?.clickIndentify {
                        BaseUnreadMessagesTipViewModel.logger.info("chatTrace unreadTip buttonClick scrollTo callback in asyncAfter \(chatId)")
                        self?.loadingInfo = (false, nil)
                    }
                }
            })
        case .showUnReadMessages:
            loadingInfo = (true, nil)
            BaseUnreadMessagesTipViewModel.logger.info("chatTrace unreadTip buttonClick scrollToToppestUnReadMessage start \(chatId)")
            delegate?.scrollToToppestUnReadMessage(tipView: self, finish: { [weak self] in
                BaseUnreadMessagesTipViewModel.logger.info("chatTrace unreadTip buttonClick scrollToToppestUnReadMessage callback \(chatId)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if currentclickIndentify == self?.clickIndentify {
                        BaseUnreadMessagesTipViewModel.logger.info("chatTrace unreadTip buttonClick scrollToToppestUnReadMessage callback in asyncAfter \(chatId)")
                        self?.loadingInfo = (false, nil)
                    }
                }
            })
        }
    }
}
