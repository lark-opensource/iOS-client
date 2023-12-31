//
//  ShareUserCardAlertProvider.swift
//  LarkForward
//
//  Created by 赵家琛 on 2020/4/24.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import UniverseDesignToast
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface
import LarkAlertController
import EENavigator
import LarkBizAvatar

struct ShareUserCardAlertContent: ForwardAlertContent {
    let shareChatter: Chatter
    var getForwardContentCallback: GetForwardContentCallback {
        let param = SendUserCardForwardParam(shareChatterId: self.shareChatter.id)
        let forwardContent = ForwardContentParam.sendUserCardMessage(param: param)
        let callback = {
            let observable = Observable.just(forwardContent)
            return observable
        }
        return callback
    }

    init(shareChatter: Chatter) {
        self.shareChatter = shareChatter
    }
}

// nolint: duplicated_code -- 转发v2代码，转发v3全业务GA后可删除
final class ShareUserCardAlertProvider: ForwardAlertProvider {
    private let avatarSize: CGFloat = 64

    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ShareUserCardAlertContent != nil {
            return true
        }
        return false
    }

    override var isSupportMention: Bool {
        return true
    }

    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        // 话题置灰
        let includeConfigs: IncludeConfigs = [
            ForwardUserEnabledEntityConfig(),
            ForwardGroupChatEnabledEntityConfig(),
            ForwardBotEnabledEntityConfig()
        ]
        return includeConfigs
    }

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let userCardContent = content as? ShareUserCardAlertContent else {
            return nil
        }

        let container = BaseForwardConfirmFooter()
        let avatarView = BizAvatar()
        container.addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.width.height.equalTo(avatarSize)
            make.top.left.bottom.equalToSuperview().inset(10)
        }
        avatarView.setAvatarByIdentifier(userCardContent.shareChatter.id,
                                         avatarKey: userCardContent.shareChatter.avatarKey,
                                         avatarViewParams: .init(sizeType: .size(avatarSize)))

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 4
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.N900
        titleLabel.text = BundleI18n.LarkForward.Lark_Legacy_PreviewUserCard(userCardContent.shareChatter.localizedName)
        container.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(avatarView.snp.top).offset(4)
            make.left.equalTo(avatarView.snp.right).offset(10)
            make.right.equalToSuperview().inset(10)
            make.bottom.lessThanOrEqualToSuperview().offset(-10)
        }
        return container
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let messageContent = content as? ShareUserCardAlertContent,
              let forwardService = try? self.resolver.resolve(assert: ForwardService.self),
              let window = from.view.window ?? self.userResolver.navigator.mainSceneWindow else { return .just([]) }
        var tracker = ShareAppreciableTracker(pageName: "ForwardViewController", fromType: .topic)
        tracker.start()
        let hud = UDToast.showLoading(on: window)
        let shareChatter = messageContent.shareChatter
        let shareChatterId = shareChatter.id
        let userIDs = self.itemsToIds(items).userIds
        let chatIDs = items.filter { $0.type == .chat }.map { $0.id }
        let threadIDAndChatIDs = items.filter { $0.type.isThread }.map { ($0.id, $0.channelID ?? "") }
        let startTime = CACurrentMediaTime()

        return forwardService
            .share(shareChatterId: shareChatterId,
                   message: input ?? "",
                   chatIds: chatIDs,
                   userIds: userIDs,
                   threadIDAndChatIDs: threadIDAndChatIDs)
            .observeOn(MainScheduler.instance)
            .do(onNext: { _ in
                hud.remove()
                tracker.end(sdkCost: CACurrentMediaTime() - startTime)
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                shareErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
                tracker.error(error)
            })
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let messageContent = content as? ShareUserCardAlertContent,
              let forwardService = try? self.resolver.resolve(assert: ForwardService.self),
              let window = from.view.window ?? self.userResolver.navigator.mainSceneWindow else { return .just([]) }
        var tracker = ShareAppreciableTracker(pageName: "ForwardViewController", fromType: .topic)
        tracker.start()
        let hud = UDToast.showLoading(on: window)
        let shareChatter = messageContent.shareChatter
        let shareChatterId = shareChatter.id
        let userIDs = self.itemsToIds(items).userIds
        let chatIDs = items.filter { $0.type == .chat }.map { $0.id }
        let threadIDAndChatIDs = items.filter { $0.type.isThread }.map { ($0.id, $0.channelID ?? "") }
        let startTime = CACurrentMediaTime()

        return forwardService
            .share(shareChatterId: shareChatterId,
                   attributeMessage: attributeInput ?? NSAttributedString(string: ""),
                   chatIds: chatIDs,
                   userIds: userIDs,
                   threadIDAndChatIDs: threadIDAndChatIDs)
            .observeOn(MainScheduler.instance)
            .do(onNext: { _ in
                hud.remove()
                tracker.end(sdkCost: CACurrentMediaTime() - startTime)
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                shareErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
                tracker.error(error)
            })
    }
}
