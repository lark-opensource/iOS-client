//
//  MomentsAnonymousPickerViewFactory.swift
//  Moment
//
//  Created by liluobin on 2021/5/26.
//

import Foundation
import UIKit
import LarkMessageCore
import LarkUIKit
import LarkContainer

final class MomentsAnonymousPickerViewFactory {
    static let realNameIdx = 0
    static let anonymousNameIdx = 1
    static func createPicker(hasAnonymousLeftCount: Bool,
                             isAnonymous: Bool,
                             showBottomLine: Bool = true,
                             viewModel: IdentitySwitchViewModel) -> AnonymousBusinessPickerView {
        guard let viewModel = viewModel as? MomentsAnonymousIdentitySwitchViewModel else {
            return AnonymousBusinessPickerView(title: "",
                                               showStyle: Display.pad ? .alwaysAlignTop : .animateToShow,
                                               pickItems: [])
        }
        // 实名身份
        let realItem = PickerItem(
            icon: nil,
            avatarKey: viewModel.currAvatarKey,
            entityId: viewModel.currUserID,
            title: BundleI18n.Moment.Lark_Community_RealNameIs + viewModel.currName,
            subTitle: "",
            badgeCount: 0,
            canSelect: true
        )
        /// 当为花名状态且花名不存在的时候, 选择箭头为
        var nickNameIsEmpty = false
        var image: UIImage?
        if viewModel.type == .nickname && (viewModel.user?.nicknameUser?.userID ?? "").isEmpty {
            nickNameIsEmpty = true
            image = Resources.nickNameArrow
        }
        let nickNameTitle = BundleI18n.Moment.Lark_Community_NicknameIs + BundleI18n.Moment.Lark_Community_GoPickNickname
        // 匿名身份
        var anonymousSubTitle: String = ""
        var anonymousCanSelect: Bool = true
        if !hasAnonymousLeftCount {
            if viewModel.type == .nickname {
                anonymousSubTitle = BundleI18n.Moment.Lark_Community_NicknameUplimitReachedDesc
            } else {
                anonymousSubTitle = BundleI18n.Moment.Lark_Community_AnonymousUplimitReachedDesc
            }
            // 如果匿名的次数已经被使用完了，但是花名身份还没选择 需要仍然选择花名
            anonymousCanSelect = false
            /// 如果花名没有额度了 但是花名还是
            if nickNameIsEmpty {
                anonymousCanSelect = true
                anonymousSubTitle = ""
            }
        }
        let anonymousItem = PickerItem(
            icon: nil,
            normalImage: image,
            seletedImage: image ?? LarkMessageCore.BundleResources.identitySelected,
            avatarKey: nickNameIsEmpty ? "" : viewModel.anonymousAvatarKey,
            entityId: nickNameIsEmpty ? "" : viewModel.anonymousEntityID,
            title: nickNameIsEmpty ? nickNameTitle : getUserDisplayNameForAnonymousAndNickNameWithVM(vm: viewModel),
            subTitle: anonymousSubTitle,
            badgeCount: 0,
            canSelect: anonymousCanSelect
        )
        // 构造选择视图
        return AnonymousBusinessPickerView(
            title: BundleI18n.Moment.Lark_Community_SelectPostIdentity,
            showStyle: Display.pad ? .alwaysAlignTop : .animateToShow,
            showBottomLine: showBottomLine,
            pickItems: [realItem, anonymousItem],
            defaultIndex: isAnonymous ? Self.anonymousNameIdx : Self.realNameIdx
        )
    }

    static func createOfficialUserPicker(momentsAccountService: MomentsAccountService,
                                         badgeInfo: MomentsBadgeInfo?,
                                         showBottomLine: Bool = true,
                                         userResolver: UserResolver) -> AnonymousBusinessPickerView {
        let viewModel = IdentitySwitchViewModel(userResolver: userResolver)
        let currentUserId = momentsAccountService.getCurrentUserId()
        // 个人身份
        var personalBadgeCount = 0
        if  currentUserId != viewModel.currUserID,
            let badge = badgeInfo?.personalUserBadge {
            personalBadgeCount = momentsAccountService.getTotalBadgeCountOf(badge)
        }
        let personalItem = PickerItem(
            icon: nil,
            avatarKey: viewModel.currAvatarKey,
            entityId: viewModel.currUserID,
            title: momentsAccountService.getPersonalUserDisplayName(),
            subTitle: "",
            badgeCount: personalBadgeCount,
            canSelect: true
        )
        var items = [personalItem]
        let officialUsers = momentsAccountService.getMyOfficialUsers()
        for (index, user) in officialUsers.enumerated() {
            var badgeCount = 0
            if currentUserId != user.userID,
               let badge = badgeInfo?.officialUsersBadge[user.userID] {
                badgeCount = momentsAccountService.getTotalBadgeCountOf(badge)
            }
            let item = PickerItem(
                icon: nil,
                avatarKey: user.avatarKey,
                entityId: user.userID,
                title: user.name,
                subTitle: "",
                badgeCount: badgeCount,
                canSelect: true
            )
            if user.userID == currentUserId {
                //当前选中的 放在最前面
                items.insert(item, at: 0)
            } else {
                items.append(item)
            }
        }

        // 构造选择视图
        return AnonymousBusinessPickerView(
            title: BundleI18n.Moment.Moments_SwitchIndentity_Title,
            showStyle: Display.pad ? .alwaysAlignTop : .animateToShow,
            showBottomLine: showBottomLine,
            pickItems: items,
            defaultIndex: 0
        )
    }

    static func getUserDisplayNameForAnonymousAndNickNameWithVM(vm: MomentsAnonymousIdentitySwitchViewModel) -> String {
        var displayName = ""
        if vm.type == .nickname {
            displayName += BundleI18n.Moment.Lark_Community_NicknameIs
        } else {
            displayName += BundleI18n.Moment.Lark_Community_AnonymousIs
        }
        displayName += vm.anonymousName
        return displayName
    }
}
