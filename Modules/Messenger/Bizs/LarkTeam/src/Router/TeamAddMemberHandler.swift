//
//  TeamAddMemberHandler.swift
//  LarkTeam
//
//  Created by 赵家琛 on 2021/7/26.
//

import UIKit
import RxSwift
import RxCocoa
import Swinject
import LarkCore
import Foundation
import EENavigator
import LarkMessengerInterface
import UniverseDesignToast
import LarkSDKInterface
import LKCommonsLogging
import LarkContainer
import UniverseDesignDialog
import LarkModel
import LarkNavigator

final class TeamAddMemberHandler: UserTypedRouterHandler {
    private var teamAPI: TeamAPI?
    private let disposeBag = DisposeBag()
    var sending = false

    static func compatibleMode() -> Bool { TeamUserScope.userScopeCompatibleMode }

    func handle(_ body: TeamAddMemberBody, req: EENavigator.Request, res: Response) throws {
        guard let from = req.context.from() else { return }
        self.teamAPI = try self.userResolver.resolve(assert: TeamAPI.self)
        var pickerBody = TeamChatterPickerBody()
        pickerBody.customLeftBarButtonItem = body.customLeftBarButtonItem
        pickerBody.selectStyle = .multi
        pickerBody.title = body.title ?? BundleI18n.LarkTeam.Project_MV_TeamMembersAdd
        pickerBody.searchPlaceholder = BundleI18n.LarkTeam.Project_T_ContactsDepartManage
        pickerBody.waterChannelHeaderTitle = BundleI18n.LarkTeam.Project_MV_ToastGroupsManage
        pickerBody.usePickerTitleView = true
        pickerBody.supportSelectGroup = true
        pickerBody.supportSelectOrganization = true
        pickerBody.supportSelectChatter = true
        pickerBody.supportUnfoldSelected = true
        pickerBody.includeShieldGroup = true
        let teamIdStr = String(body.teamId)
        let chatterEntity = PickerConfig.ChatterContent(field: .init(directlyTeamIds: [teamIdStr]))
        let chatEntity = PickerConfig.ChatContent(field: .init(directlyTeamIds: [teamIdStr]))
        pickerBody.pickerContentConfigurations = [chatterEntity, chatEntity]
        pickerBody.itemDisableBehavior = { (item: SearchOption) in
           switch item.meta {
           case .chatter(let info): return info.isInTeam ?? false
           case .chat(let info): return info.isInTeam ?? false
           default: return false
           }
        }
        pickerBody.itemDisableSelectedToastBehavior = { _ in
           return BundleI18n.LarkTeam.Project_T_MemberAlreadyExists_HoverToast
        }
        let currentChatterId = userResolver.userID
        var forceSelectedChatterIds = body.forceSelectedChatterIds
        forceSelectedChatterIds.append(currentChatterId)
        // 需清晰区分已有的团队成员
        pickerBody.forceSelectedChatterIds = forceSelectedChatterIds
        // Picker默认展示组织架构栏，但不支持用户搜索或选择部门，仅支持选择部门下级的个人成员
        pickerBody.cancelCallback = body.completionHandler
        // 支持添加为团队成员的群组类型有：普通群、话题群、会议群、部门群、公开群；暂时不支持：外部群、密聊群、家校群
        pickerBody.checkChatDeniedReasonForDisabledPick = { chatType in
            if chatType.isCrossTenant
                || chatType.isCrypto
                || chatType.isPrivateMode {
                return true
            }
            return false
        }
        pickerBody.checkChatDeniedReasonForWillSelected = { (chatType, targetVC) in
            if chatType.isCrossTenant
                || chatType.isCrypto
                || chatType.isPrivateMode {
                UDToast.showTips(with: BundleI18n.LarkTeam.Project_MV_UnableToSelectExternalGroups, on: targetVC.view)
                return false
            }
            return true
        }
        pickerBody.checkChatterDeniedReasonForDisabledPick = { isExternal in
            return isExternal
        }
        pickerBody.checkChatterDeniedReasonForWillSelected = { (isExternal, targetVC) in
            if isExternal {
                UDToast.showTips(with: BundleI18n.LarkTeam.Project_MV_DontChooseExternal, on: targetVC.view)
                return false
            }
            return true
        }
        pickerBody.selectedCallback = { [weak self] controller, contactPickerResult in
            guard let self = self, let controller = controller else { return }
            self.addTeamMember(body: body,
                               contactPickerResult: contactPickerResult,
                               currentVC: controller)
        }
        navigator.present(body: pickerBody,
                                 from: from,
                                 prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
        res.end(resource: EmptyResource())
    }

    private func addTeamMember(body: TeamAddMemberBody,
                               contactPickerResult: ContactPickerResult,
                               currentVC: UIViewController) {
        guard !sending else { return }
        sending = true
        let chatterIds = contactPickerResult.chatterInfos.map({ $0.ID })
        let chatIds = contactPickerResult.chatInfos.map { $0.id }
        let departmentIds = contactPickerResult.departments.map { $0.id }
        let successCallback = { [weak currentVC] in
            if let view = currentVC?.view.window {
                UDToast.showSuccess(with: BundleI18n.LarkTeam.Project_MV_AddedSuccessfully, on: view)
            }
            currentVC?.dismiss(animated: true, completion: nil)
            body.completionHandler?()
        }

        let failCallback = { [weak currentVC, weak self] (error: Error) in
            if let view = currentVC?.view.window {
                let text = Self.parseError(error: error) ?? BundleI18n.LarkTeam.Project_MV_CannotAddTeamMembersNow
                let dialog = UDDialog()
                dialog.setTitle(text: text, alignment: .center)
                dialog.addPrimaryButton(text: BundleI18n.LarkTeam.Project_T_GotIt_PopupButton)
                self?.navigator.present(dialog, from: view)
            }
        }
        teamAPI?.putTeamMemberRequest(teamId: body.teamId,
                                          chatterIds: chatterIds,
                                          chatIds: chatIds,
                                          departmentIds: departmentIds)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] _ in
            successCallback()
            self?.sending = false
        }, onError: { [weak self] error in
            failCallback(error)
            self?.sending = false
        }).disposed(by: disposeBag)

    }

    private static func parseError(error: Error) -> String? {
        guard let apiError = error.underlyingError as? APIError else { return nil }
        if !apiError.serverMessage.isEmpty {
            return apiError.serverMessage
        }
        if !apiError.displayMessage.isEmpty {
            return apiError.displayMessage
        }
        return nil
    }
}
