//
//  ChatKeyboardTopExtendView.swift
//  LarkMessageCore
//
//  Created by zc09v on 2022/1/12.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkModel
import RxSwift
import LarkCore
import RxCocoa
import UniverseDesignColor

public protocol ChatKeyboardTopExtendViewDelegate: AnyObject {
    func keyboardTopExtendViewOnRefresh()
}

public final class ChatKeyboardTopExtendView: UIView, ChatOpenKeyboardTopExtendService {
    /// 内容距离顶部的间距
    public static let contentTopMargin: CGFloat = 8
    private let topExtendModule: BaseChatKeyboardTopExtendModule
    private let disposeBag: DisposeBag = DisposeBag()
    private let chatWrapper: ChatPushWrapper
    private weak var delegate: ChatKeyboardTopExtendViewDelegate?
    public init(topExtendModule: BaseChatKeyboardTopExtendModule,
                chatWrapper: ChatPushWrapper,
                delegate: ChatKeyboardTopExtendViewDelegate) {
        self.topExtendModule = topExtendModule
        self.chatWrapper = chatWrapper
        self.delegate = delegate
        super.init(frame: .zero)
    }

    /// 是否允许展示键盘上方快捷组件
    /// 底部为群空间菜单的时候禁止展示
    public var shouldShow: Bool = false {
        didSet {
            if shouldShow {
                self.isHidden = self.subviews.isEmpty
            } else {
                self.isHidden = true
            }
        }
    }

    public func setupModule() {
        let chat = self.chatWrapper.chat.value
        let metaModel = ChatKeyboardTopExtendMetaModel(chat: chat)
        self.topExtendModule.handler(model: metaModel)
        if let (contentView, topMargin) = self.topExtendModule.setUpContentView(model: metaModel) {
            self.addSubview(contentView)
            contentView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(topMargin)
                make.bottom.left.right.equalToSuperview()
            }
        }

        chatWrapper.chat
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chat in
                self?.topExtendModule.modelDidChange(model: ChatKeyboardTopExtendMetaModel(chat: chat))
            }).disposed(by: self.disposeBag)
        self.isHidden = shouldShow ? self.subviews.isEmpty : true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func refresh() {
        self.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        if let (contentView, topMargin) = self.topExtendModule.refresh() {
            self.addSubview(contentView)
            contentView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(topMargin)
                make.bottom.left.right.equalToSuperview()
            }
        }
        self.isHidden = shouldShow ? self.subviews.isEmpty : true
        self.delegate?.keyboardTopExtendViewOnRefresh()
    }
}
