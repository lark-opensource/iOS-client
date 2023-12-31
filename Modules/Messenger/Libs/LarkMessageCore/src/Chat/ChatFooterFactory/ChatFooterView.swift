//
//  ChatFooterView.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2022/7/7.
//

import Foundation
import LarkCore
import LarkOpenChat
import RxSwift
import RxCocoa
import UIKit

public final class ChatFooterView: UIView, ChatOpenFooterService {

    private let footerModule: BaseChatFooterModule
    private let disposeBag = DisposeBag()
    private let chatWrapper: ChatPushWrapper
    public private(set) var isDisplay: Bool = false

    public init(footerModule: BaseChatFooterModule, chatWrapper: ChatPushWrapper) {
        self.footerModule = footerModule
        self.chatWrapper = chatWrapper
        super.init(frame: .zero)
        self.reload()
        chatWrapper.chat
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chat in
                self?.footerModule.modelDidChange(model: ChatFooterMetaModel(chat: chat))
            })
            .disposed(by: self.disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func refresh() {
        self.footerModule.onRefresh()
        self.subviews.forEach { view in
            view.removeFromSuperview()
        }
        var hasAvailableView = false
        if let view = self.footerModule.contentView() {
            self.addSubview(view)
            view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            hasAvailableView = true
        }
        self.isDisplay = hasAvailableView
    }

    public func reload() {
        let chat = self.chatWrapper.chat.value
        self.footerModule.handler(model: ChatFooterMetaModel(chat: chat))
        self.footerModule.createViews(model: ChatFooterMetaModel(chat: chat))
        self.refresh()
    }
}
