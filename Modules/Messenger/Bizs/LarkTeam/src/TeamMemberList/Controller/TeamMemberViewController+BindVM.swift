//
//  TeamMemberViewController+BindVM.swift
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

// MARK: 监听VM
extension TeamMemberViewController {

    func bind() {
        // 更新不可取消选中的列表
        viewModel.unableCancelSelectedIdsRelay
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            }).disposed(by: disposeBag)

        viewModel.teamOb
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.setNavigationItemTitle()
                self?.changeRightBarItemStyleForNormal()
            }).disposed(by: disposeBag)
    }

    func selectedItem(delta: [TeamMemberItem], items: [TeamMemberItem]) {
        self.pickerToolBar.updateSelectedItem(
            firstSelectedItems: items,
            secondSelectedItems: [],
            updateResultButton: true)
    }

    func deselectedItem(delta: [TeamMemberItem], items: [TeamMemberItem]) {
        self.pickerToolBar.updateSelectedItem(
            firstSelectedItems: items,
            secondSelectedItems: [],
            updateResultButton: true)
    }

    func tapItem(item: TeamMemberItem) {
        guard let teamMember = item as? TeamMemberCellVM,
              teamMember.isChatter else { return }
        if let action = viewModel.selectdMemberCallback {
            action(teamMember.itemId, teamMember.itemName, self)
        } else {
            let body = PersonCardBody(chatterId: teamMember.itemId)
            viewModel.navigator.presentOrPush(
                body: body,
                wrap: LkNavigationController.self,
                from: self,
                prepareForPresent: { vc in
                    vc.modalPresentationStyle = .formSheet
                })
        }
    }
}
