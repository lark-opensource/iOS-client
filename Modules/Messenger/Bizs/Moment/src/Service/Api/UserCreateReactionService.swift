//
//  UserCreateReactionService.swift
//  Moment
//
//  Created by liluobin on 2021/5/31.
//

import UIKit
import Foundation
import LarkUIKit
import LarkContainer
import RxCocoa
import RxSwift
import LarkSDKInterface
import LarkAlertController
import EENavigator
import RoundedHUD

protocol UserCreateReactionService {
    func createReaction(byID entityID: String,
                        entityType: RawData.EntityType,
                        reactionType: String,
                        originalReactionSet: RawData.ReactionSet,
                        categoryIds: [String],
                        isAnonymous: Bool,
                        fromVC: UIViewController?)
}

final class UserCreateReactionServiceIMP: UserCreateReactionService, UserResolverWrapper {
    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var reactionAPI: ReactionAPI?
    @ScopedInjectedLazy private var postAPI: PostApiService?
    @ScopedInjectedLazy private var configService: MomentsConfigAndSettingService?
    @ScopedInjectedLazy private var momentsAccountService: MomentsAccountService?

    func createReaction(byID entityID: String,
                        entityType: RawData.EntityType,
                        reactionType: String,
                        originalReactionSet: RawData.ReactionSet,
                        categoryIds: [String],
                        isAnonymous: Bool,
                        fromVC: UIViewController?) {
        let createReaction = { [weak self] in
            guard let self = self else { return }
            self.postAPI?
                .createReaction(byID: entityID,
                                entityType: entityType,
                                reactionType: reactionType,
                                originalReactionSet: originalReactionSet,
                                categoryIds: categoryIds,
                                isAnonymous: isAnonymous)
                .subscribe(onError: { [weak self] error in
                    self?.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: nil)
                })
                .disposed(by: self.disposeBag)
            self.reactionAPI?.updateRecentlyUsedReaction(reactionType: reactionType).subscribe().disposed(by: self.disposeBag)
        }
        if isAnonymous {
            self.configService?.getUserCircleConfigWithFinsih({ [weak self] (config) in
                if config.anonymityPolicy.enabled,
                    config.anonymityPolicy.type == .nickname,
                    config.nicknameUser.userID.isEmpty {
                    self?.showAlertWithCircleId(config.circleID, fromVC: fromVC)
                } else {
                    createReaction()
                }
            }, onError: nil)
        } else {
            createReaction()
        }
    }

    func showAlertWithCircleId(_ circleId: String, fromVC: UIViewController?) {
        guard let vc = fromVC else {
            return
        }
        let alertVC = LarkAlertController()
        alertVC.setTitle(text: BundleI18n.Moment.Lark_Community_ChooseNicknameDialogTitle)
        alertVC.setContent(text: BundleI18n.Moment.Lark_Community_ChooseNicknameDialogDesc)
        alertVC.addSecondaryButton(text: BundleI18n.Moment.Lark_Community_ChooseNicknameDialogNotNowButton)
        alertVC.addPrimaryButton(text: BundleI18n.Moment.Lark_Community_ChooseNicknameDialogChooseNicknameButton, dismissCompletion: { [weak self] in
            let body = MomentsUserNickNameSelectBody(circleId: circleId) { (momentUser, renewNicknameTime) in
                self?.configService?.updateUserNickName(momentUser: momentUser, renewNicknameTime: renewNicknameTime)
                RoundedHUD.showTips(with: BundleI18n.Moment.Lark_Community_NicknameSetAddReactionNowToast, on: vc.view.window ?? vc.view, delay: 1.5)
            }
            self?.userResolver.navigator.present(body: body, from: vc, prepare: {
                $0.modalPresentationStyle = Display.pad ? .pageSheet : .fullScreen
            })
        })
        userResolver.navigator.present(alertVC, from: vc)
    }

}
