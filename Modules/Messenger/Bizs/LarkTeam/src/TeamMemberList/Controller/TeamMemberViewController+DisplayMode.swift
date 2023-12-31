//
//  TeamMemberViewController+DisplayMode.swift
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

// MARK: 切换模式
extension TeamMemberViewController {

    func changeListMode(_ mode: TeamMemberMode, forceChange: Bool = false) {
        if !forceChange {
            guard viewModel.displayMode != mode else { return }
        }
        viewModel.displayMode = mode
        switch mode {
        case .normal:
            switchToNormal()
        case .multiRemoveTeamMember:
            switchToRemove()
        @unknown default:
            break
        }
    }

    func switchToNormal() {
        setNavigationItemTitle()
        if viewModel.isTransferTeam {
            changeRightBarItemStyle(type: .noneItem)
        } else {
            changeRightBarItemStyleForNormal()
        }
        viewModel.canLeftSlide = true
        self.pickerToolBar.isHidden = true
        self.pickerToolBar.updateSelectedItem(firstSelectedItems: [], secondSelectedItems: [], updateResultButton: true)
        tableView.snp.remakeConstraints { (maker) in
            if Feature.teamSearchEnable(userID: self.viewModel.currentUserId) {
                maker.top.equalTo(searchWrapper.snp.bottom)
            } else {
                maker.top.equalToSuperview()
            }
            maker.left.right.equalToSuperview()
            maker.bottom.equalTo(self.view.snp.bottom)
        }
        displayMode = .display
    }

    func setNavigationItemTitle() {
        if let count = viewModel.team?.memberCount, count + 1 > 1 {
            title = BundleI18n.LarkTeam.Project_T_GroupNameVariables(BundleI18n.LarkTeam.Project_T_SubtitleTeamMembers, count)
        } else {
            title = BundleI18n.LarkTeam.Project_T_SubtitleTeamMembers
        }
    }

    func switchToRemove() {
        title = BundleI18n.LarkTeam.Project_T_RemoveGroupMembers
        changeRightBarItemStyle(type: .removeItem)
        viewModel.canLeftSlide = false

        self.cancelEditting()
        self.pickerToolBar.isHidden = false
        tableView.snp.remakeConstraints { (maker) in
            if Feature.teamSearchEnable(userID: self.viewModel.currentUserId) {
                maker.top.equalTo(searchWrapper.snp.bottom)
            } else {
                maker.top.equalToSuperview()
            }
            maker.left.right.equalToSuperview()
            maker.bottom.equalTo(self.pickerToolBar.snp.top)
        }
        displayMode = .multiselect
    }
}
