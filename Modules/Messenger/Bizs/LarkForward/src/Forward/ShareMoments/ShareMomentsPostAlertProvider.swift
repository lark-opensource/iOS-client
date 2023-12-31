//
//  ShareMomentsPostAlertProvider.swift
//  LarkForward
//
//  Created by zc09v on 2021/1/22.
//
import UIKit
import Foundation
import LarkModel
import LarkMessengerInterface
import LarkCore
import LarkContainer
import LarkSDKInterface
import RxSwift
import UniverseDesignToast
import Swinject
import RustPB

struct ShareMomentsPostAlertContent: ForwardAlertContent {
    let post: RustPB.Moments_V1_Post
}

// nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
final class ShareMomentsPostAlertProvider: ForwardAlertProvider {
    @ScopedInjectedLazy private var forwardService: ForwardService?
    private let action: ([String], String?) -> Observable<Void>
    private let cancel: (() -> Void)?
    public override var needSearchOuterTenant: Bool {
        return false
    }

    override var isSupportMention: Bool {
        return true
    }

    override func getFilter() -> ForwardDataFilter? {
        return { (item) -> Bool in
            return item.type != .threadMessage
        }
    }

    override func getForwardItemsIncludeConfigs() -> IncludeConfigs? {
        guard let postContent = content as? ShareMomentsPostAlertContent else { return nil }
        let includeConfigs: IncludeConfigs = [
            //业务需要过滤外部会话（人和群），所有帖子（普通话题和消息话题）
            ForwardUserEntityConfig(tenant: .inner),
            ForwardGroupChatEntityConfig(tenant: .inner),
            ForwardBotEntityConfig()
        ]
        return includeConfigs
    }

    public override func isShowInputView(by items: [ForwardItem]) -> Bool {
        return true
    }

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let postContent = content as? ShareMomentsPostAlertContent else { return nil }
        return ShareMomentsPostConfirmFooter(post: postContent.post)
    }

    init(userResolver: UserResolver,
         content: ForwardAlertContent,
         action: @escaping ([String], String?) -> Observable<Void>,
         cancel: (() -> Void)?) {
        self.action = action
        self.cancel = cancel
        super.init(userResolver: userResolver, content: content)
        var filter = ForwardFilterParameters()
        //includeThread目前特指话题群
        filter.includeThread = true
        filter.includeOuterChat = false
        self.filterParameters = filter
    }

    required init(userResolver: UserResolver, content: ForwardAlertContent) {
        fatalError("init(resolver:content:) has not been implemented")
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let window = from.view.window,
              let forwardService = forwardService
        else {
            return .just([])
        }
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        return forwardService.checkAndCreateChats(chatIds: ids.chatIds, userIds: ids.userIds)
            .flatMap { (chatModels) -> Observable<[String]> in
                let chatIds = chatModels.map({ $0.id })
                return self.action(chatIds, input).map { (_) -> [String] in
                    return chatIds
                }
            }
            .observeOn(MainScheduler.instance)
            .do(onNext: { (_) in
                hud.remove()
            }, onError: { (error) in
                hud.showFailure(
                    with: BundleI18n.LarkForward.Lark_Community_UnableToShare,
                    on: window,
                    error: error
                )
            })
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let window = from.view.window,
              let forwardService = forwardService
        else {
            return .just([])
        }
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        return forwardService.checkAndCreateChats(chatIds: ids.chatIds, userIds: ids.userIds)
            .flatMap { (chatModels) -> Observable<[String]> in
                let chatIds = chatModels.map({ $0.id })
                return self.action(chatIds, attributeInput?.string).map { (_) -> [String] in
                    return chatIds
                }
            }
            .observeOn(MainScheduler.instance)
            .do(onNext: { (_) in
                hud.remove()
            }, onError: { (error) in
                hud.showFailure(
                    with: BundleI18n.LarkForward.Lark_Community_UnableToShare,
                    on: window,
                    error: error
                )
            })
    }

    override func cancelAction() {
        self.cancel?()
    }
}

final class ShareMomentsPostConfirmFooter: BaseForwardConfirmFooter {
    private let post: RustPB.Moments_V1_Post

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(post: RustPB.Moments_V1_Post) {
        self.post = post
        super.init()

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 4
        label.lineBreakMode = .byTruncatingTail
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        }

        let summerize = post.postContent.content.lc.summerize()
        if !summerize.isEmpty {
            label.text = summerize
        } else if !post.postContent.imageSetList.isEmpty {
            label.text = BundleI18n.LarkForward.Lark_Community_Image
        } else if post.postContent.hasMedia {
            label.text = BundleI18n.LarkForward.Lark_Community_Video
        } else {
            label.text = ""
        }
    }
}
