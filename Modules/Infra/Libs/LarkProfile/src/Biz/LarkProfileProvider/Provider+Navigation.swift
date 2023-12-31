//
//  Provider+Navigation.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/7/27.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import UniverseDesignIcon
import UniverseDesignTag
import RustPB
import EENavigator
import LarkMessengerInterface
import UniverseDesignToast
import LarkFeatureGating
import LarkKAFeatureSwitch
import LarkAlertController
import LarkSDKInterface
import LKCommonsTracker
import Homeric
import LarkRustClient
import SwiftProtobuf
import Reachability

extension LarkProfileDataProvider {
    public func getNavigationButton() -> [UIButton] {
        guard (Reachability()?.connection != Reachability.Connection.none), let userInfo = self.userProfile?.userInfoProtocol else {
            return []
        }

        // AI Profile 右上角设置项不同
        if isAIProfile {
            if isAIEnabled, isMyAIProfile {
                // 只有自己的 AI 才展示设置按钮
                let settingButton = UIButton()
                settingButton.setImage(UDIcon.editOutlined.ud.withTintColor(UIColor.ud.iconN1),
                                       for: .normal)
                settingButton.setImage(UDIcon.editOutlined.ud.withTintColor(UIColor.ud.iconN1),
                                       for: .highlighted)
                settingButton.addTarget(self, action: #selector(didTapMyAISettingButton), for: .touchUpInside)
                // 本人 AI 右上角展示设置按钮
                return [settingButton]
            } else {
                // 非本人 AI 右上角不展示按钮
                return []
            }
        }

        var buttons: [UIButton] = []

        let isMe = currentChatterId == userInfo.userID
        let showSpecialFocus = !isMe
        let showShare = userInfo.hasShareInfo
        let showAliasAndMemo = !isMe

        /// 组织架构profile
        let myUserId = self.currentChatterId
        /// 是否具有举报资格：fs开&&不是自己&&国内包&&userId不为空
        let reportEnable = tnsReport &&
            (userInfo.userID != myUserId) &&
            !(userInfo.userID.isEmpty)
        /// 是否具有设置额度权限：我是userProfile的leader
        let setNumebrEnable = myUserId == userInfo.leaderID
        /**
         是否有右上角的...逻辑：
         原则：针对不同权限的人 会有不一样的配置选项 没有的话隐藏...
         线上逻辑：举报|设置号码查询次数|分享
         联系人二期：不同于线上，见 needToShowSetInfoViewWithConfig
         故有以下判断逻辑
         */
        var shoudShowRightNavigationBar = true
        let isFriend = (userInfo.friendStatus == .double && !isSameTenant)
        let canDelete = !isSameTenant && isFriend // 不是同一租户，且是好友，可以删除
        let canBlock = !isSameTenant // 不是同一租户则可以屏蔽

        if isMe && userInfo.hasShareInfo {
            // 顶部按钮品质优化：自己看自己时，可展示分享按钮
            let shareButton = UIButton()
            shareButton.setImage(UDIcon.shareOutlined.ud.withTintColor(UIColor.ud.iconN1),
                                 for: .normal)
            shareButton.setImage(UDIcon.shareOutlined.ud.withTintColor(UIColor.ud.iconN1),
                                 for: .highlighted)
            shareButton.addTarget(self, action: #selector(tapShareButton), for: .touchUpInside)
            buttons.append(shareButton)
        }

        // 举报| 设置号码查询次数| 屏蔽(不是同一Tenant) | 删除联系人(不是同一Tenant&好友) 最后两个逻辑重复（搬运自旧版profile，作者：毛振宁）
        shoudShowRightNavigationBar = reportEnable || setNumebrEnable || canDelete || canBlock
            || showSpecialFocus || showShare || showAliasAndMemo

        if !isMe && shoudShowRightNavigationBar {
            // 非个人主页可展示...按钮
            let button = UIButton()
            button.setImage(UDIcon.moreBoldOutlined.ud.withTintColor(UIColor.ud.iconN1),
                                 for: .normal)
            button.setImage(UDIcon.moreBoldOutlined.ud.withTintColor(UIColor.ud.iconN1),
                                 for: .highlighted)
            button.addTarget(self, action: #selector(tapMoreButton), for: .touchUpInside)
            buttons.append(button)
        }
        return buttons
    }

    @objc
    private func tapShareButton() {
        guard let userInfo = userProfile?.userInfoProtocol, let fromVC = self.profileVC else {
            return
        }

        if userInfo.shareInfo.enable {
            let body = ShareUserCardBody(shareChatterId: userInfo.userID)
            self.userResolver.navigator.present(body: body, from: fromVC,
                                     prepare: { $0.modalPresentationStyle = .formSheet })
        } else {
            UDToast.showFailure(with: userInfo.shareInfo.deniedDescription.getString(), on: fromVC.view)
        }

        self.tracker?.trackMainClick("share", extra: ["target": "public_multi_select_share_view"])
    }

    @objc
    private func tapMoreButton() {
        pushSetInformationViewController()
        self.tracker?.trackMainClick("more", extra: ["target": "profile_more_action_view"])
    }

    public func pushSetInformationViewController() {
        guard let fromVC = self.profileVC else {
            return
        }
        guard let userProfile = userProfile as? LarkUserProfile else {
            assertionFailure("Unexpected userProfile")
            return
        }

        let userInfo = userProfile.userInfo

        /// 组织架构profile
        let myUserId = self.currentChatterId

        /// 是否具有举报资格：fs开&&不是自己&&国内包&&userId不为空
        let reportEnable = tnsReport &&
            (userInfo.userID != myUserId) &&
            !(userInfo.userID.isEmpty)
        /// 是否具有设置额度权限：我是userProfile的leader
        let setNumebrEnable = myUserId == userInfo.leaderID

        let shareInfo: SetInformationViewControllerBody.ShareInfo = {
            if !userInfo.hasShareInfo {
                return .no
            } else {
                if userInfo.shareInfo.enable {
                    return .yes(.enable)
                } else {
                    return .yes(.denied(desc: userInfo.shareInfo.deniedDescription.getString()))
                }
            }
        }()
        let aliasAndMemoInfo = getAliasAndMemoInfos(userProfile: userProfile)
        var body = SetInformationViewControllerBody(isBlocked: self.isBlocked,
                                                    isSameTenant: isSameTenant,
                                                    setNumebrEnable: setNumebrEnable,
                                                    isCanReport: reportEnable,
                                                    isMe: myUserId == userInfo.userID,
                                                    isFriend: userInfo.friendStatus == .double,
                                                    userId: userInfo.userID,
                                                    contactToken: userInfo.contactToken,
                                                    shareInfo: shareInfo,
                                                    isSpecialFocus: userInfo.isSpecialFocus,
                                                    aliasAndMemoInfo: aliasAndMemoInfo,
                                                    isFromPrivacy: userProfile.canNotFind,
                                                    isResigned: userInfo.isResigned,
                                                    isShowBlockMenu: isShowBlockMenu,
                                                    dismissCallback: { [weak self] in
            self?.profileVC?.dismissSelf()
        })
        // profile隐藏添加按钮, 且需要申请联系人时, 将添加操作放到setting页面
        if self.isHideAddContactButtonOnProfile {
            body.showAddBtn = true
        }
        body.pushToAddContactHandler = { [weak self] in
            self?.pushAddContactRelationVC()
        }
        var naviParams = NaviParams()
        naviParams.forcePush = true
        self.userResolver.navigator.push(body: body, naviParams: naviParams, from: fromVC)
    }

    private func getAliasAndMemoInfos(userProfile: LarkUserProfile) -> SetInformationViewControllerBody.AliasAndMemoInfo {
        var alias = ""
        var memoText = ""
        var memoDescription: ProfileMemoDescription?
        for field in userProfile.fieldOrders {
            var options = JSONDecodingOptions()
            options.ignoreUnknownFields = true
            switch field.fieldType {
            case .cAlias:
                guard let text = try? LarkUserProfile.Text(jsonString: field.jsonFieldVal, options: options) else { break }
                guard !text.text.i18NVals.isEmpty || !text.text.defaultVal.isEmpty else { break }
                alias = text.text.getString()
            case .memoDescription:
                guard let memo = try? LarkUserProfile.MemoDescription(jsonString: field.jsonFieldVal, options: options) else { break }
                memoDescription = memo
                guard !memo.memoText.isEmpty else { break }
                memoText = memo.memoText
            @unknown default: break
            }
        }
        var aliasAndMemoInfo = SetInformationViewControllerBody.AliasAndMemoInfo(name: userProfile.userInfo.userName)
        aliasAndMemoInfo.alias = alias
        aliasAndMemoInfo.memoDescription = memoDescription
        aliasAndMemoInfo.memoText = memoText
        aliasAndMemoInfo.updateAliasCallback = { [weak self] in
            self?.reloadData()
        }
        return aliasAndMemoInfo
    }
}
