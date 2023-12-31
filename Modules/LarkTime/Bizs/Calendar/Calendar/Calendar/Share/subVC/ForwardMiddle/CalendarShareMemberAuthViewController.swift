//
//  CalendarShareMemberAuthViewController.swift
//  Calendar
//
//  Created by Hongbin Liang on 8/18/23.
//

import Foundation
import LarkUIKit
import RxSwift
import UniverseDesignToast

/// 底部弹出的权限设置页

class CalendarShareMemberAuthViewController: UIViewController {

    var roleChanged: ((_ role: Rust.CalendarAccessRole) -> Void)?

    private let memberData: CalendarMemberCellDataType
    private let displayedOptions: [Rust.CalendarAccessRole] = [.freeBusyReader, .reader, .writer, .owner]

    private typealias Panel = CalendarEditRoleSelectionView

    init(memberData: CalendarMemberCellDataType) {
        self.memberData = memberData
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ud.bgBody

        let header = ActionPanelHeader(title: I18n.Calendar_Detail_PermissionSettingsTitle)
        header.addBottomBorder(lineHeight: CGFloat(1.0 / UIScreen.main.scale))
        header.closeCallback = { [weak self] in
            self?.dismiss(animated: true)
        }
        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.height.equalTo(MemberAuthEidtUI.headerHeight)
            make.top.leading.trailing.equalToSuperview()
        }

        let options = displayedOptions.map {
            let canSelect: Bool
            if let highestRole = memberData.highestRole {
                canSelect = $0 <= highestRole
            } else { canSelect = false }
            return SelectionCellData(canSelect: canSelect, title: $0.cd.shareOption, content: $0.cd.shareOptionDescription)
        }

        let optionsPanel = Panel(contents: options, separatorFilled: true)
        optionsPanel.clipsToBounds = true
        optionsPanel.selectedIndex = displayedOptions.firstIndex(of: memberData.role) ?? -1
        view.addSubview(optionsPanel)
        if Display.pad {
            header.isHidden = true
            view.backgroundColor = optionsPanel.backgroundColor
            optionsPanel.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.leading.equalToSuperview()
                make.trailing.equalToSuperview().inset(12)
            }
        } else {
            optionsPanel.snp.makeConstraints { make in
                make.top.equalTo(header.snp.bottom)
                make.leading.trailing.equalToSuperview().inset(16)
            }
        }
        optionsPanel.onSelect = { [weak self] optionIndex, needBlock in
            guard let self = self, let selectedRole = self.displayedOptions[safeIndex: optionIndex] else { return }
            guard !needBlock else {
                let isGroupOwner = selectedRole == .owner && self.memberData.isGroup

                let maxPermission: String
                if let highestRole = self.memberData.highestRole {
                    maxPermission = highestRole.cd.shareOption
                } else { maxPermission = I18n.Calendar_Share_Private_Option }

                let tipStr = isGroupOwner ? I18n.Calendar_Share_ThisNoSetDefaultOption : I18n.Calendar_Share_MaxPermissionSetAs(MaxPermission: maxPermission)

                UDToast.showTips(with: tipStr, on: self.view)
                return
            }
            self.roleChanged?(selectedRole)
            self.dismiss(animated: true)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarShareMemberAuthViewController {

    var panelHeight: CGFloat {
        let itemNum = displayedOptions.count
        let sepeNum = Double(itemNum - 1)
        let panelHeight = Double(Panel.UI.cellHeight * itemNum) + Panel.UI.seperatorHeight * sepeNum
        return panelHeight
    }

    var contentHeight: CGFloat {
        let bottomMargin = 32.0
        return MemberAuthEidtUI.headerHeight + panelHeight + bottomMargin
    }

    fileprivate struct MemberAuthEidtUI {
        static let headerHeight = 48.0
    }
}
