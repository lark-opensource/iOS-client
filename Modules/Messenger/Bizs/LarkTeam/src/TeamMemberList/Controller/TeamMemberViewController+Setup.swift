//
//  TeamMemberViewController+Setup.swift
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

// MARK: 布局&监听
extension TeamMemberViewController {
    func setupSubviews() {
        rightBarItem.addTarget(self, action: #selector(rightBarItemTapped), for: .touchUpInside)
        rightBarItem.button.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        rightBarItem.button.setTitleColor(UIColor.ud.N400, for: .disabled)

        leftBarItem.addTarget(self, action: #selector(leftBarItemTapped), for: .touchUpInside)
        leftBarItem.button.setTitleColor(UIColor.ud.textTitle, for: .normal)

        pickerToolBar.setItems(pickerToolBar.toolbarItems(), animated: false)
        pickerToolBar.allowSelectNone = false
        pickerToolBar.updateSelectedItem(firstSelectedItems: [], secondSelectedItems: [], updateResultButton: true)
        pickerToolBar.confirmButtonTappedBlock = { [weak self] _ in self?.deleteTeamMember() }
        pickerToolBar.isHidden = true
        self.view.addSubview(pickerToolBar)
        self.view.bringSubviewToFront(pickerToolBar)
        self.pickerToolBar.snp.makeConstraints {
            $0.height.equalTo(49)
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(self.avoidKeyboardBottom)
        }
        changeListMode(viewModel.displayMode, forceChange: true)
    }
}
