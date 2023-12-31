//
//  BaseUnReadMessagesTipView.swift
//  Lark
//
//  Created by zc09v on 2018/5/14.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkModel
import LarkInteraction
import LarkSuspendable
import LarkAIInfra

public protocol MessageInfoForUnReadTip {
    var id: String { get }
    var position: Int32 { get }
    var badgeCount: Int32 { get }
    var fromChatter: Chatter? { get }
    var isAtAll: Bool { get }
}

public protocol UnReadMessagesTipViewDelegate: AnyObject {
    func tipWillShow(tipView: BaseUnReadMessagesTipView)
    func tipCanShow(tipView: BaseUnReadMessagesTipView) -> Bool
    func scrollTo(message: MessageInfoForUnReadTip, tipView: BaseUnReadMessagesTipView, finish: @escaping () -> Void)
    func scrollToBottommostMessage(tipView: BaseUnReadMessagesTipView, finish: @escaping () -> Void)
    func scrollToToppestUnReadMessage(tipView: BaseUnReadMessagesTipView, finish: @escaping () -> Void)
    func onUnReadMessagesTipViewMyAIItemTapped(tipView: BaseUnReadMessagesTipView)
    func shouldShowUnReadMessagesMyAIView(tipView: BaseUnReadMessagesTipView) -> Bool
}

public extension UnReadMessagesTipViewDelegate {
    func tipWillShow(tipView: BaseUnReadMessagesTipView) {
        return
    }

    func tipCanShow(tipView: BaseUnReadMessagesTipView) -> Bool {
        return true
    }

    func scrollTo(message: MessageInfoForUnReadTip, tipView: BaseUnReadMessagesTipView, finish: @escaping () -> Void) {
        return
    }

    func scrollToBottommostMessage(tipView: BaseUnReadMessagesTipView, finish: @escaping () -> Void) {
        return
    }

    func scrollToToppestUnReadMessage(tipView: BaseUnReadMessagesTipView, finish: @escaping () -> Void) {
        return
    }

    func onUnReadMessagesTipViewMyAIItemTapped(tipView: BaseUnReadMessagesTipView) {
    }

    func shouldShowUnReadMessagesMyAIView(tipView: BaseUnReadMessagesTipView) -> Bool {
        return false
    }
}

public class BaseUnReadMessagesTipView: UIView {
    class var tipType: String { return "" }
    public weak var delegate: UnReadMessagesTipViewDelegate?
    public var viewModel: BaseUnreadMessagesTipViewModel
    /// (是否是加载中，当前加载的messagePos)
    var loadingInfo: (isLoading: Bool, loadingPos: Int32?) = (false, nil) {
        didSet {
            tipContent.loading = loadingInfo.isLoading
        }
    }
    let tipContent: UnReadMessagesTipContentView

    let disposeBag: DisposeBag = DisposeBag()
    public private (set) var unReadTipState: UnReadMessagesTipState = .dismiss
    let chat: Chat
    public init(chat: Chat, viewModel: BaseUnreadMessagesTipViewModel) {
        self.chat = chat
        self.viewModel = viewModel
        tipContent = UnReadMessagesTipContentView()
        super.init(frame: .zero)
        tipContent.addTarget(self, action: #selector(tipButtonClick), for: .touchUpInside)
        self.addSubview(tipContent)
        tipContent.snp.remakeConstraints({ make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(12)
            make.trailing.bottom.equalToSuperview().offset(-12)
        })
        tipContent.myAIViewClickCallBack = { [weak self] in
            guard let self = self else { return }
            self.delegate?.onUnReadMessagesTipViewMyAIItemTapped(tipView: self)
        }
        if let image = viewModel.myAIService?.defaultResource.iconLarge {
            tipContent.setMyAIViewIcon(image)
        }
        self.isHidden = true

        self.addPointer(
            .init(
                effect: .lift,
                shape: { (size) -> PointerInfo.ShapeSizeInfo in
                    return (size, size.height / 2)
                }
            )
        )
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeProtectedZone()
    }

    override public func didMoveToSuperview() {
        guard self.superview != nil else {
            return
        }
        self.driveDataProvider()
        self.viewModel.fetchDataWhenLoad()
    }

    public func driveDataProvider() {
        viewModel.stateDriver.drive(onNext: { [weak self] (state) in
            self?.handle(state: state)
        }).disposed(by: disposeBag)
    }

    public func refresh() {
        self.handle(state: self.unReadTipState)
    }

    private func handle(state: UnReadMessagesTipState) {
        BaseUnreadMessagesTipViewModel.logger.info("chatTrace unreadTip handle state \(Self.tipType) \(state.rawValue)")
        self.unReadTipState = state
        if delegate?.tipCanShow(tipView: self) ?? false {
            switch unReadTipState {
            case .dismiss:
                loadingInfo = (false, nil)
                setUnreadTipsHidden(true)
            case .showToLastMessage:
                tipContent.update(content: .forToLastMsg)
                setUnreadTipsHidden(false)
            case .showUnReadAt(let message, _):
                if let user = message.fromChatter {
                    let placeholder: String
                    let userDisplayName = user.displayName(chatId: self.chat.id, chatType: self.chat.type, scene: .unReadTip)
                    if message.isAtAll {
                        placeholder = BundleI18n.LarkMessageCore.Lark_Legacy_AtAllWindow("")
                    } else {
                        placeholder = BundleI18n.LarkMessageCore.Lark_Legacy_AtPeople("")
                    }
                    tipContent.update(content: .forUnreadAt(entityId: user.id, avatarKey: user.avatarKey, text: userDisplayName, placeholder: placeholder))
                } else {
                    if message.isAtAll {
                        tipContent.update(content: .forUnreadAt(entityId: nil, avatarKey: nil, text: "", placeholder: BundleI18n.LarkMessageCore.Lark_Legacy_SomeOneAtAll))
                    } else {
                        tipContent.update(content: .forUnreadAt(entityId: nil, avatarKey: nil, text: "", placeholder: BundleI18n.LarkMessageCore.Lark_Legacy_SomeoneAtYou))
                    }
                }
                delegate?.tipWillShow(tipView: self)
                setUnreadTipsHidden(false)
            case .showUnReadMessages(let count, _):
                tipContent.update(content: .forUnreadMsg(unreadCount: count, text: self.viewModel.unReadTip(count: count),
                                                         showMyAI: delegate?.shouldShowUnReadMessagesMyAIView(tipView: self) ?? false))
                delegate?.tipWillShow(tipView: self)
                setUnreadTipsHidden(false)
            }
        } else {
            loadingInfo = (false, nil)
            setUnreadTipsHidden(true)
        }
    }

    @objc
    func tipButtonClick() {
    }

    private func setUnreadTipsHidden(_ isHidden: Bool) {
        self.isHidden = isHidden
        // ContentView's frame is modified by calling `invalidateIntrinsicContentSize`,
        // so the correct frame should be reached in next layout cycle.
        DispatchQueue.main.async {
            if isHidden {
                self.removeProtectedZone()
            } else {
                self.addProtectedZone()
            }
        }
    }

    /// 添加与多任务浮窗的互斥区域，电梯按钮出现后调用
    private func addProtectedZone() {
        let key = "\(Unmanaged.passUnretained(self).toOpaque())"
        if let frame = self.superview?.convert(self.frame, to: nil) {
            SuspendManager.shared.addProtectedZone(frame, forKey: key)
        }
    }

    /// 移除与多任务浮窗的互斥区域，电梯按钮消失后调用
    private func removeProtectedZone() {
        let key = "\(Unmanaged.passUnretained(self).toOpaque())"
        SuspendManager.shared.removeProtectedZone(forKey: key)
    }
}
