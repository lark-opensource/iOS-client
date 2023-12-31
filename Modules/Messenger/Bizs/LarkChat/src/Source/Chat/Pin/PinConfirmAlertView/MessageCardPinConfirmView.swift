//
//  MessageCardPinConfirmView.swift
//  LarkChat
//
//  Created by MJXin on 2022/5/31.
//

import Foundation
import UIKit
import LarkModel
import LarkMessageCore
import LarkContainer

public protocol MessageCardPinAlertContentViewProtocol: UIView {
    func setPinContent(content: CardContent)
}

final class MessageCardPinConfirmViewModel: PinAlertViewModel {
    let content: CardContent

    init(cardMessage: Message, content: CardContent, getSenderName: @escaping (Chatter) -> String) {
        self.content = content
        super.init(message: cardMessage, getSenderName: getSenderName)
    }
}

final class MessageCardPinConfirmView: PinConfirmContainerView, UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedInjectedLazy var contentView: MessageCardPinAlertContentViewProtocol?
    init(userResolver: UserResolver, frame: CGRect) {
        self.userResolver = userResolver
        super.init(frame: frame)
        guard let contentView = contentView else { return }
        addSubview(contentView)
        setupBackgroundStyle()
        setupNameLabelStyle()
        setupContentViewStyle()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupBackgroundStyle() {
        backgroundColor = .clear
        layer.cornerRadius = 0
    }

    private func setupNameLabelStyle() {
        nameLabel.snp.updateConstraints { (make) in
            make.left.equalTo(0)
        }
    }

    private func setupContentViewStyle() {
        contentView?.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(0)
            make.bottom.equalTo(nameLabel.snp.top).offset(-BubbleLayout.commonInset.top)
        }
    }

    override func setPinConfirmContentView(_ contentVM: PinAlertViewModel) {
        super.setPinConfirmContentView(contentVM)
        guard let cardContentVM = contentVM as? MessageCardPinConfirmViewModel else {
            return
        }
        self.contentView?.setPinContent(content: cardContentVM.content)
    }
}
