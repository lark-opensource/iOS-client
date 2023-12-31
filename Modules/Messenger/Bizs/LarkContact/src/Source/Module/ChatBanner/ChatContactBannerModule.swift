//
//  ChatContactBannerModule.swift
//  LarkContact
//
//  Created by  李勇 on 2020/12/8.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkOpenIM
import LarkContainer
import LarkMessengerInterface
import LarkMessageCore
import LarkSDKInterface
import RxSwift
import LarkFeatureGating

/// 联系人业务：黑名单
///密聊场景下使用独立CryptoChatContactBannerModule，请注意修改是否需要同步调整
///https://bytedance.feishu.cn/wiki/wikcn1VprnQ1YOuaYpJFLRRplxb
public final class ChatContactBannerModule: ChatBannerSubModule {
    public override class var name: String { return "ChatContactBannerModule" }

    public override var type: ChatBannerType {
        return .externalContact
    }

    private var contactContentView: UIView?
    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var contactControlService: ContactControlService?
    private var externalContactBannerManager: ExternalContactBannerManager?

    public override func contentView() -> UIView? {
        return self.contactContentView
    }

    public override class func canInitialize(context: ChatBannerContext) -> Bool {
        return true
    }

    public override func canHandle(model: ChatBannerMetaModel) -> Bool {
        return model.chat.type == .p2P && model.chat.isCrossTenant
    }

    public override func handler(model: ChatBannerMetaModel) -> [Module<ChatBannerContext, ChatBannerMetaModel>] {
        return [self]
    }

    public override func createViews(model: ChatBannerMetaModel) {
        super.createViews(model: model)

        // 默认不展示，后续监听信号再展示
        self.display = false
        if let observable = self.contactControlService?.getExternalBannerModelObservable(chat: model.chat),
            let chatOpenService = try? self.context.resolver.resolve(assert: ChatOpenService.self) {
            externalContactBannerManager = ExternalContactBannerManager(
                targetVC: chatOpenService.chatVC(),
                chat: model.chat,
                addContactSuccessPush: (try? self.context.resolver.userPushCenter.observable(for: PushAddContactSuccessMessage.self)) ?? .empty(),
                userResolver: self.context.userResolver
            )

            /// 这里如果banner的view 自身被移除了, 这个时候不需要等待服务端的通知，本地直接隐藏
            externalContactBannerManager?.onBannerViewRemovedCallBack = { [weak self] bannerView in
                if bannerView === self?.contactContentView {
                    self?.hideBanner()
                }
            }
            /// 监听信号 隐藏banner
            observable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] model in
                if let banner = self?.externalContactBannerManager?.getBannerFromModel(model) {
                    self?.contactContentView = banner
                    self?.display = true
                    self?.context.refresh()
                } else {
                    self?.hideBanner()
                }
                self?.context.refresh()
            }).disposed(by: self.disposeBag)
        }
    }

    /// 隐藏banner
    func hideBanner() {
        /// 如果原来是隐藏的，不需要在刷新banner
        if !self.display {
            return
        }
        self.contactContentView = nil
        self.display = false
        self.context.refresh()
    }
}
