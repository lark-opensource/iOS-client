//
//  VCLiveSettingPicker.swift
//  ByteViewMod
//
//  Created by sihuahao on 2022/5/6.
//

import Foundation
import ByteViewNetwork
import UniverseDesignToast
import LarkAccountInterface
import LarkSDKInterface
import LarkSearchCore
import LarkNavigation
import LarkUIKit
import LarkMessengerInterface
import UIKit
import EENavigator

enum DisplayStatus: Int {
    case normal // 展示且可选
    case disabled  // 展示且置灰
    case hidden // 不展示
}

final class VCLiveSettingPicker {
    var title: String
    var customView: UIView?
    var pickedConfirmCallBack: (([LivePermissionMember]) -> Void)?
    var defaultSelectedMembers: [LivePermissionMember]?
    var from: UIViewController
    var displayStatus: DisplayStatus
    var disableUserKey: String
    var disableGroupKey: String

    init (_ msg: String, displayStatus: Int, disableUserKey: String?, disableGroupKey: String?, customView: UIView?, pickedConfirmCallBack: (([LivePermissionMember]) -> Void)?, defaultSelectedMembers: [LivePermissionMember]?, from: UIViewController) {
        self.title = msg
        self.customView = customView
        self.pickedConfirmCallBack = pickedConfirmCallBack
        self.defaultSelectedMembers = defaultSelectedMembers
        self.from = from
        self.displayStatus = DisplayStatus(rawValue: displayStatus) ?? .normal
        self.disableUserKey = disableUserKey ?? ""
        self.disableGroupKey = disableGroupKey ?? ""
    }

    func buildBody() -> VCChatterPickerBody {
        var body = VCChatterPickerBody()
        body.title = title
        body.supportCustomTitleView = true
        body.supportSelectGroup = true
        body.supportSelectOrganization = true
        body.supportUnfoldSelected = true
        body.enableRelatedOrganizations = true
        body.includeOuterChat = !(displayStatus == .hidden)
        body.needSearchOuterTenant = !(displayStatus == .hidden)
        body.allowDisplaySureNumber = false
        body.includeOuterGroupForChat = !(displayStatus == .hidden)
        body.limitInfo = SelectChatterLimitInfo(max: 1000, warningTip: BundleI18n.ByteViewMod.View_MV_MaxSelected_Toast)
        if self.displayStatus == .disabled {
            body.myGroupContactCanSelect = { item in
                if item.isCrossTenant {
                    return false
                }
                return true
            }
            body.myGroupContactDisableReason = { _ in
                return self.disableGroupKey
            }
            body.externalContactCanSelect = { item in
                if item.isCrossTenant {
                    return false
                }
                return true
            }
            body.externalContactDisableReason = { _ in
                return self.disableUserKey
            }

            body.checkChatterDeniedReasonForWillSelected = { (isExternal, targetVC) in
                if isExternal {
                    UDToast.showTips(with: self.disableUserKey, on: targetVC.view)
                    return false
                }
                return true
            }

            body.checkChatterDeniedReasonForDisabledPick = { isExternal in
                return isExternal
            }

            body.checkChatDeniedReasonForWillSelected = { (chatType, targetVC) in
                if chatType.isCrossTenant || chatType.isCrypto {
                    UDToast.showTips(with: self.disableGroupKey, on: targetVC.view)
                  return false
                }
                return true
            }

            body.checkChatDeniedReasonForDisabledPick = { chatType in
                if chatType.isCrossTenant || chatType.isCrypto {
                  return true
                }
                return false
            }
        }
        body.customHeaderView = customView
        body.defaultSelectedResult = getDefaultSelectedMembers()
        body.selectedCallback = { (vc, result) in
            guard let vc = vc else { return }
            var members: [LivePermissionMember] = []
            if !result.departments.isEmpty {
                for item in result.departments {
                    let name = LivePermissionMember.I18nString(zh_cn: item.name, en_us: nil, ja_jp: nil)
                    members.append(LivePermissionMember(memberId: item.id, memberType: .memberTypeDepartment, avatarUrl: nil, isExternal: nil, isChatManager: nil, isUserInChat: nil, userCount: 0, memberName: name))
                }
            }

            if !result.chatInfos.isEmpty {
                for item in result.chatInfos {
                    let name = LivePermissionMember.I18nString(zh_cn: item.name, en_us: nil, ja_jp: nil)
                    members.append(LivePermissionMember(memberId: item.id, memberType: .memberTypeChat, avatarUrl: item.avatarKey, isExternal: nil, isChatManager: nil, isUserInChat: nil, userCount: item.chatUserCount, memberName: name))
                }
            }

            if !result.chatterInfos.isEmpty {
                for item in result.chatterInfos {
                    let name = LivePermissionMember.I18nString(zh_cn: item.name, en_us: nil, ja_jp: nil)
                    members.append(LivePermissionMember(memberId: item.ID, memberType: .memberTypeUser, avatarUrl: item.avatarKey, isExternal: item.isExternal, isChatManager: nil, isUserInChat: nil, userCount: 1, memberName: name))
                }
            }

            self.pickedConfirmCallBack?(members)
            vc.dismiss(animated: true, completion: nil)
        }
        return body
    }

    func getDefaultSelectedMembers() -> ContactPickerResult? {
        var chatterInfos: [SelectChatterInfo] = []
        var chatInfos: [SelectChatInfo] = []
        var departments: [SelectDepartmentInfo] = []
        if let members = defaultSelectedMembers {
            for item in members {
                switch item.memberType {
                case .memberTypeUser:
                    var m = SelectChatterInfo(ID: item.memberId)
                    m.avatarKey = item.avatarUrl ?? ""
                    m.name = item.memberName?.zh_cn ?? ""
                    chatterInfos.append(m)
                case .memberTypeChat:
                    chatInfos.append(SelectChatInfo(id: item.memberId, name: item.memberName?.zh_cn ?? "", avatarKey: item.avatarUrl ?? "", chatUserCount: Int32(item.userCount ?? 0)))
                case .memberTypeDepartment:
                    departments.append(SelectDepartmentInfo(id: item.memberId, name: item.memberName?.zh_cn ?? ""))
                default: break
                }
            }
        }
        return ContactPickerResult(chatterInfos: chatterInfos, botInfos: [], chatInfos: chatInfos, departments: departments, mails: [], meetingGroupChatIds: [], mailContacts: [], extra: nil)
    }
}
