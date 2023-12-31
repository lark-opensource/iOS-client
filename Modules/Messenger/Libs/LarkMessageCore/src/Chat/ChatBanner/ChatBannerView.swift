//
//  ChatBannerView.swift
//  LarkMessageCore
//
//  Created by zc09v on 2022/1/11.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkModel
import RxSwift
import LarkCore
import RxCocoa

public final class ChatBannerView: UIView, ChatOpenBannerService {
    private let bannerModule: BaseChatBannerModule
    private let disposeBag: DisposeBag = DisposeBag()
    private let chatWrapper: ChatPushWrapper
    public var changeDisplayStatus: ((Bool) -> Void)?
    public private (set) var isDisplay = false {
        didSet {
            if oldValue != isDisplay {
                changeDisplayStatus?(isDisplay)
            }
        }
    }

    /// 所有待展示banner的集合：入群申请、视频会议卡片、日程卡片
    private lazy var bannerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0.0
        return stackView
    }()

    public init(bannerModule: BaseChatBannerModule, chatWrapper: ChatPushWrapper) {
        self.bannerModule = bannerModule
        self.chatWrapper = chatWrapper
        super.init(frame: .zero)
        self.addSubview(self.bannerStackView)
        self.bannerStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.reload()
        chatWrapper.chat
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chat in
                self?.bannerModule.modelDidChange(model: ChatBannerMetaModel(chat: chat))
            }).disposed(by: self.disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func refresh() {
        self.bannerModule.onRefresh()
        self.bannerStackView.subviews.forEach { (view) in
            view.removeFromSuperview()
            self.bannerStackView.removeArrangedSubview(view)
        }
        let contentViews = self.bannerModule.contentViews()
        var hasAvailableView = false
        contentViews.forEach { (view) in
            self.bannerStackView.addArrangedSubview(view)
            if !view.isHidden {
                hasAvailableView = true
            }
        }
        self.isDisplay = hasAvailableView
    }

    public func reload() {
        let chat = self.chatWrapper.chat.value
        if !chat.isTeamVisitorMode {
            self.bannerModule.handler(model: ChatBannerMetaModel(chat: chat))
        }
        self.bannerModule.createViews(model: ChatBannerMetaModel(chat: chat))
        self.refresh()
    }
}
