//
//  TeamGroupPrivacySettingVM.swift
//  LarkTeam
//
//  Created by xiaruzhen on 2023/2/20.
//

import UIKit
import Foundation
import RustPB
import LarkTab
import RxSwift
import LarkCore
import RxCocoa
import LarkUIKit
import LarkModel
import EENavigator
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import UniverseDesignToast
import UniverseDesignDialog
import LarkMessengerInterface

final class TeamGroupPrivacySettingVM: TeamBaseViewModel {
    var name = "TeamGroupPrivacySettingVM"
    var title = BundleI18n.LarkTeam.Project_T_PrivacySettingsInTeam_Title
    var leftItemInfo: String? = BundleI18n.LarkTeam.Lark_Legacy_Cancel
    var rightItemInfo: (Bool, String) = (true, BundleI18n.LarkTeam.Project_T_PrivacySettings_Done_Button)
    // 决定navigaitonBar右边的按钮是否可点击的事件流
    var rightItemEnableRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    weak var fromVC: UIViewController?
    weak var targetVC: TeamBaseViewControllerAbility?
    var reloadData: Driver<Void> { return _reloadData.asDriver(onErrorJustReturn: ()) }
    private var _reloadData = PublishSubject<Void>()
    private(set) var items: TeamSectionDatasource = []

    private let teamAPI: TeamAPI
    private let chatAPI: ChatAPI
    private let teamId: Int64
    private let chatId: String
    private let teamName: String

    // 条件
    // 是否是外部群
    private let isCrossTenant: Bool
    // 是否是团队/群管理员
    private let ownerAuthority: Bool

    // 是否可查看历史消息
    private var messageVisibility: Bool
    // 消息可见性设置
    private var isMessageVisible: Bool
    // 群可发现设置
    private var discoverableEnabled: Bool
    private var discoverable: Bool

    let disposeBag = DisposeBag()
    private let preDiscoverable: Bool
    private let preMessageVisible: Bool
    let navigator: EENavigator.Navigatable

    init(teamId: Int64,
         chatId: String,
         teamName: String,
         isMessageVisible: Bool,
         isCrossTenant: Bool,
         ownerAuthority: Bool,
         discoverable: Bool,
         messageVisibility: Bool,
         teamAPI: TeamAPI,
         chatAPI: ChatAPI,
         navigator: EENavigator.Navigatable) {
        self.teamId = teamId
        self.chatId = chatId
        self.teamName = teamName
        self.preMessageVisible = isMessageVisible
        self.preDiscoverable = discoverable

        self.isMessageVisible = isMessageVisible
        self.isCrossTenant = isCrossTenant
        self.ownerAuthority = ownerAuthority
        self.discoverable = discoverable
        self.teamAPI = teamAPI
        self.messageVisibility = messageVisibility
        self.chatAPI = chatAPI
        self.navigator = navigator

        if isMessageVisible || isCrossTenant || !ownerAuthority {
            self.discoverableEnabled = false
        } else {
            self.discoverableEnabled = true
        }
        var info = "teamlog/groupPrivacySet. teamId:\(teamId), chatId:\(chatId), isMessageVisible:\(isMessageVisible)"
        info.append(", discoverable:\(discoverable), isCrossTenant:\(isCrossTenant), messageVisibility:\(messageVisibility), ")
        TeamMemberViewModel.logger.info(info)
    }

    func closeItemClick() {
        targetVC?.dismiss(animated: true, completion: nil)
    }

    func rightItemClick() {
        changeAuthority()
    }

    func viewDidLoadTask() {
        // 发射初始化信号
        self.items = structureItems()
        _reloadData.onNext(())
    }

    func structureItems() -> TeamSectionDatasource {
        let sections = [
            self.privacySection()
        ].compactMap { $0 == nil ? $0 : $0?.items.isEmpty == true ? nil : $0 }
        return sections
    }
}

// 数据源
extension TeamGroupPrivacySettingVM {
    private func privacySection() -> TeamSectionModel {
        var sectionVM = TeamSectionModel(items: [
            messageVisibleItem(),
            chatVisibleItem()
        ].compactMap({ $0 }))
        sectionVM.headerTitle = BundleI18n.LarkTeam.Project_T_GroupSettings_PrivacySettings_PC_Title(self.teamName)
        return sectionVM
    }

    private func messageVisibleItem() -> TeamCellViewModelProtocol? {
        let title = isMessageVisible ? BundleI18n.LarkTeam.Project_T_GroupPrivacy_Public_Title : BundleI18n.LarkTeam.Project_T_GroupPrivacy_Private_Title
        let desc = isMessageVisible ? BundleI18n.LarkTeam.Project_T_GroupPrivacy_Public_Desc : BundleI18n.LarkTeam.Project_T_GroupPrivacy_Private_Desc
        return TeamInfoCellViewModel(type: .groupMode,
                                     cellIdentifier: TeamInfoCell.lu.reuseIdentifier,
                                     style: .half,
                                     isShowDescription: true,
                                     isShowArrow: true,
                                     title: title,
                                     description: desc) { [weak self] _ in
            guard let self = self, let targetVC = self.targetVC else { return }
            let errorTips: String?
            if self.isCrossTenant {
                errorTips = BundleI18n.LarkTeam.Project_T_ExternalGroupCantPublic_Hover
            } else if !self.ownerAuthority {
                //errorTips = "无权限配置"
                errorTips = nil
            } else {
                errorTips = nil
            }
            let isMessageEnabled = !((self.isCrossTenant) || (!self.ownerAuthority))
            let vc = MessageVisibleVC(isMessageVisible: self.isMessageVisible,
                                      isMessageEnabled: isMessageEnabled,
                                      messageVisibility: self.messageVisibility,
                                      errorTips: errorTips)
            self.navigator.push(vc, from: targetVC)
            vc.selectedCallback = { [weak self] isMessageVisible in
                guard let self = self else { return }
                self.isMessageVisible = isMessageVisible
                if isMessageVisible {
                    self.discoverable = true
                    self.discoverableEnabled = false
                }
                self.items = self.structureItems()
                self._reloadData.onNext(())
            }
            if !self.messageVisibility {
                vc.messageVisibilityCallback = { [weak self] callback in
                    self?.showMessageVisibilitAlert(successCallback: {
                        callback()
                    })
                }
            }
        }
    }

    private func chatVisibleItem() -> TeamCellViewModelProtocol? {
        let title = BundleI18n.LarkTeam.Project_T_GroupPrivacy_MakeDiscoverable_Checkbox
        return TeamConfigCellViewModel(type: .default,
                                           cellIdentifier: TeamConfigCell.lu.reuseIdentifier,
                                           style: .auto,
                                           title: title,
                                           descContent: "",
                                           status: self.discoverable,
                                       cellEnable: self.discoverableEnabled,
                                       switchHandler: { [weak self] (_, status) in
            guard let self = self else { return }
            self.discoverable = status
            self.items = self.structureItems()
            self._reloadData.onNext(())
        }, switchunUseHandler: { [weak self] in
            guard let self = self else { return }
            let targetVC = self.targetVC
            let window = targetVC?.view.window
            if let window = window {
                let errorTips: String?
                if self.isCrossTenant {
                    errorTips = BundleI18n.LarkTeam.Project_T_ExternalGroupCantPublic_Hover
                } else if !self.ownerAuthority {
                    //errorTips = "无权限配置"
                    errorTips = nil
                } else if self.isMessageVisible && self.discoverable {
                    errorTips = BundleI18n.LarkTeam.Project_T_GroupPrivacy_MakeDiscoverable_PublicGroupCantEdit_Hover
                } else {
                    errorTips = nil
                }

                if let errorTips = errorTips {
                    UDToast.showFailure(with: errorTips, on: window)
                }
            }
        })
    }
}

extension TeamGroupPrivacySettingVM {
    func changeAuthority() {
        guard (preDiscoverable != self.discoverable) || (preMessageVisible != isMessageVisible) else {
            targetVC?.popSelf()
            return
        }
        let targetVC = self.targetVC
        teamAPI.patchTeamChatByIdRequest(teamId: teamId,
                                         chatId: Int64(chatId) ?? 0,
                                         teamChatType: self.isMessageVisible ? .open : .private,
                                         isDiscoverable: self.discoverable)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak targetVC] _ in
                targetVC?.popSelf()
             }, onError: { [weak targetVC] error in
                 if let window = targetVC?.currentWindow() {
                     UDToast.showFailure(with: BundleI18n.LarkTeam.Lark_Legacy_ErrorMessageTip, on: window, error: error)
                 }
             }).disposed(by: self.disposeBag)
    }

    private func showMessageVisibilitAlert(successCallback: @escaping () -> Void) {
        guard let targetVC = self.targetVC else { return }
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkTeam.Project_T_NeedToSetMemberReadHistory_Title)
        dialog.setContent(text: BundleI18n.LarkTeam.Project_T_NeedToSetMemberReadHistory_Text)
        dialog.addCancelButton()
        dialog.addPrimaryButton(text: BundleI18n.LarkTeam.Project_T_NeedToSetMemberReadHistory_ButtonOpen,
                                dismissCompletion: { [weak self] in
            self?.updateMessageVisibility(successCallback: successCallback)
        })
        navigator.present(dialog, from: targetVC)
    }

    private func updateMessageVisibility(successCallback: @escaping () -> Void) {
        chatAPI.updateChat(chatId: String(chatId), messageVisibilitySetting: .allMessages)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.messageVisibility = true
                self.isMessageVisible = true
                self.discoverable = true
                self.discoverableEnabled = false
                self.items = self.structureItems()
                self._reloadData.onNext(())
                successCallback()
            }, onError: { [weak self] error in
                if let window = self?.targetVC?.view.window {
                    UDToast.showFailure(with: BundleI18n.LarkTeam.Project_T_CantSetToast, on: window, error: error)
                }
        }).disposed(by: self.disposeBag)
    }
}
