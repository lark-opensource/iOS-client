//
//  ExternalContactBannerManager.swift
//  LarkMessageCore
//
//  Created by JackZhao on 2020/10/12.
//

import UIKit
import Foundation
import RxSwift
import LarkMessengerInterface
import LarkSDKInterface
import LarkMessageBase
import LarkModel
import RxRelay
import LKCommonsLogging
import LKCommonsTracker
import LarkContainer
import Homeric

private enum ExternalContactBannerBehavior {
    // 展示屏蔽联系人 & 添加联系人
    case showRelationBanner
    // 添加联系人
    case showAddContactBanner(model: AddExternalContactBannerModel)
    // 收到添加联系人申请
    case showRecieveAddContactBanner(model: AddExternalContactBannerModel)
    // 不显示
    case hideBanner
}

final public class ExternalContactBannerManager: UserResolverWrapper {
    public let userResolver: UserResolver
    weak var targetVC: UIViewController?
    private var displayName: String {
        return chat.chatter?.displayName ?? ""
    }
    private var userId: String {
        return chat.chatterId
    }
    private var chatId: String {
        return chat.id
    }
    @ScopedInjectedLazy private var userRelationService: UserRelationService?
    @ScopedInjectedLazy private var externalContactsAPI: ExternalContactsAPI?
    private var addContactSuccessPush: Observable<PushAddContactSuccessMessage>
    private var chat: Chat
    private lazy var behaviorRelay: BehaviorRelay<UserRelationModel>? = {
        return self.userRelationService?.getAndStashUserRelationModelBehaviorRelay(chat: chat)
    }()
    private var model: AddExternalContactBannerModel?
    public var onBannerViewRemovedCallBack: ((UIView?) -> Void)?
    // 屏蔽/添加好友banner
    lazy private var relationBanner: ExternalContactRelationBannerView = {
        let banner = ExternalContactRelationBannerView(
            targetVC: targetVC,
            userId: userId,
            chatId: chatId,
            displayName: displayName,
            addContactSuccessPush: addContactSuccessPush,
            externalContactsAPI: externalContactsAPI,
            nav: self.navigator
        )
        banner.removeFromSuperViewCallBack = { [weak self, weak banner] in
            self?.onBannerViewRemovedCallBack?(banner)
        }
        return banner
    }()

    // 添加好友banner
    lazy private var addContactBanner: AddExternalContactBannerView? = {
        guard let model = model else { return nil }
        let banner = AddExternalContactBannerView(targetVC: targetVC,
                                                  model: model,
                                                  userId: userId,
                                                  chatId: chatId,
                                                  displayName: displayName,
                                                  addContactSuccessPush: addContactSuccessPush,
                                                  behaviorRelay: behaviorRelay,
                                                  userResolver: self.userResolver)
        banner.removeFromSuperViewCallBack = { [weak self, weak banner] in
            self?.onBannerViewRemovedCallBack?(banner)
        }
        return banner
    }()

    public init(targetVC: UIViewController?,
                chat: Chat,
                addContactSuccessPush: Observable<PushAddContactSuccessMessage>,
                userResolver: UserResolver) {
        self.targetVC = targetVC
        self.chat = chat
        self.addContactSuccessPush = addContactSuccessPush
        self.userResolver = userResolver
    }

    deinit {
        print("ExternalContactBannerManager deinit")
    }

    // 根据模型获取banner
    public func getBannerFromModel(_ model: ExternalBannerModel) -> UIView? {
        let behavior: ExternalContactBannerBehavior = self.getBannerType(model: model)
        let type = model.userRelationModel.isOwner ? "initiator" : "recipient"

        switch behavior {
        case .showRelationBanner:
            Tracker.post(TeaEvent(Homeric.SHOW_IM_CONTACTS_BANNER,
                                  params: ["type": type]))
            return self.relationBanner
        case .showAddContactBanner(let model), .showRecieveAddContactBanner(let model):
            Tracker.post(TeaEvent(Homeric.SHOW_IM_CONTACTS_BANNER,
                                  params: ["type": type]))
            // 如果不为空，走更新UI的逻辑，否则取lazy的view
            if self.model != nil {
                self.addContactBanner?.updateFromViewModel(model)
            }
            self.model = model
            return self.addContactBanner
        case .hideBanner:
            return nil
        }
    }

    // 获取banner的类型
    private func getBannerType(model externalBannerModel: ExternalBannerModel) -> ExternalContactBannerBehavior {
        let model = externalBannerModel.userRelationModel
        // 是好友/发送申请/屏蔽对方 都不显示banner
        guard !(model.isFriend ||
                    model.isHasApply ||
                    model.isHasBlock ||
                    model.isCtrlAddContact ||
                    model.isAssociatedOrignazationMember) else {
            return .hideBanner
        }
        var description = ""
        // 是发起方，收到好友申请
        if model.isOwner && model.isRecieveApply {
            if let beAppliedReason = model.beAppliedReason, !beAppliedReason.isEmpty {
                description = BundleI18n.LarkMessageCore.Lark_IM_ThisUserSentYouAcontactRequestPlusReason_Banner(beAppliedReason)
            } else {
                description = BundleI18n.LarkMessageCore.Lark_IM_ThisUserSentYouAcontactRequest_Banner
            }
            let model = AddExternalContactBannerModel(description: description,
                                                      buttonType: .recieve)
            return .showRecieveAddContactBanner(model: model)
        }
        // 是发起方，没有收到好友申请, 显示发起好友申请的banner
        if model.isOwner && !model.isRecieveApply && !model.isHasBlock {
            description = BundleI18n.LarkMessageCore.Lark_IM_NotYourContact_Add_Button
            let model = AddExternalContactBannerModel(description: description,
                                                      buttonType: .add)
            return .showAddContactBanner(model: model)
        }
        // 是接收方，没有屏蔽对方并且没有收到申请，显示 屏蔽&添加好友 banner
        if !model.isOwner && !model.isRecieveApply {
            return .showRelationBanner
        }
        // 是接收方，收到好友申请
        if !model.isOwner, model.isRecieveApply {
            // 接受方显示
            if let beAppliedReason = model.beAppliedReason, !beAppliedReason.isEmpty {
                description = BundleI18n.LarkMessageCore.Lark_IM_ThisUserSentYouAcontactRequestPlusReason_Banner(beAppliedReason)
            } else {
                description = BundleI18n.LarkMessageCore.Lark_IM_ThisUserSentYouAcontactRequest_Banner
            }
            let model = AddExternalContactBannerModel(description: description,
                                                      buttonType: .recieve)
            return .showRecieveAddContactBanner(model: model)
        }
        return .hideBanner
    }
}
