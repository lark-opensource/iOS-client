//
//  TeamMemberViewController+NaviBar.swift
//  LarkTeam
//
//  Created by 夏汝震 on 2021/12/15.
//

import Foundation
import RxSwift
import LarkTag
import RxRelay
import LarkModel
import LarkUIKit
import EENavigator
import LarkNavigator
import LarkContainer
import LKCommonsLogging
import LarkSDKInterface
import UniverseDesignToast
import UniverseDesignDialog
import LarkMessengerInterface
import UniverseDesignActionPanel
import UniverseDesignColor
import UIKit

// MARK: 右侧导航 Item
extension TeamMemberViewController {
    func changeRightBarItemStyle(type: TeamMemberNavItemType) {
        viewModel.navItemType = type
        navigationItem.rightBarButtonItem = (type != .noneItem ? rightBarItem : nil)
        switch type {
        case .noneItem: break
        case .moreItem:
            rightBarItem.reset(title: nil, image: Resources.icon_more_outlined)
        case .removeItem:
            rightBarItem.reset(title: BundleI18n.LarkTeam.Project_T_CancelButton, image: nil)
            rightBarItem.setBtnColor(color: UIColor.ud.textTitle)
        case .addItem:
            rightBarItem.reset(title: BundleI18n.LarkTeam.Lark_Legacy_Add, image: nil)
            rightBarItem.setBtnColor(color: UIColor.ud.textTitle)
        @unknown default:
            break
        }
    }

    func changeRightBarItemStyleForNormal() {
        guard viewModel.displayMode == .normal,
              !viewModel.isTransferTeam else { return }
        changeRightBarItemStyle(type: viewModel.isShowRemoveMode() ? .moreItem : .addItem)
    }

    func _rightBarItemTapped(type: TeamMemberNavItemType) {
        switch type {
        case .noneItem:     break
        case .moreItem:     showSheet()
        case .removeItem:   changeListMode(.normal)
        case .addItem:      openAddTeamMemberPicker()
        }
    }

    private func showSheet() {
        guard let moreView = self.rightBarItem.customView else { return }
        let popSource = UDActionSheetSource(sourceView: moreView,
                                           sourceRect: moreView.bounds,
                                           arrowDirection: .up)
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: false, popSource: popSource))
        actionSheet.addDefaultItem(text: BundleI18n.LarkTeam.Project_T_AddButton) { [weak self] in
            self?.openAddTeamMemberPicker()
        }
        actionSheet.addDestructiveItem(text: BundleI18n.LarkTeam.Project_T_RemoveButton) { [weak self] in
            guard let self = self else { return }
            self.changeListMode(.multiRemoveTeamMember)
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkTeam.Project_T_CancelButton) {}
        self.present(actionSheet, animated: true, completion: nil)
    }
}

extension TeamMemberViewController {
    func disappear() {
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.popSelf()
        }
    }
}

extension TeamMemberViewController {
    private func openAddTeamMemberPicker() {
        guard viewModel.team?.isAllowAddTeamMember ?? false else {
            if let view = self.view.window {
                let text = BundleI18n.LarkTeam.Project_T_OnlyOwnerAndTheOther
                UDToast.showTips(with: text, on: view)
            }
            return
        }
        let forceSelectedChatterIds: [Int64]
        if let ownerID = self.viewModel.team?.ownerID {
            forceSelectedChatterIds = [ownerID]
        } else {
            forceSelectedChatterIds = []
        }
        let body = TeamAddMemberBody(teamId: self.viewModel.teamId,
                                     forceSelectedChatterIds: forceSelectedChatterIds)
        viewModel.navigator.present(
            body: body,
            from: self,
            prepare: { $0.modalPresentationStyle = .formSheet })
    }

    func deleteTeamMember() {
        guard !selectedItems.isEmpty else { return }
        removeSelectedItems()
        if viewModel.displayMode == .multiRemoveTeamMember {
            changeListMode(.normal)
        }
    }
}
