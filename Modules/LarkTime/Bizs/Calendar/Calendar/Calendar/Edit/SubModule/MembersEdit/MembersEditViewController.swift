//
//  MembersEditViewController.swift
//  Calendar
//
//  Created by Hongbin Liang on 4/7/23.
//

import Foundation
import LarkUIKit
import RxSwift
import UniverseDesignToast

class MembersEditViewController: UIViewController {

    var roleChanged: ((_ role: Rust.CalendarAccessRole) -> Void)?
    var deleteHandler: (() -> Void)?

    private let header = MemberPanelDisplayHeader()
    private let removeBtn = CalendarEditOperationButton()

    private let memberData: CalendarMemberCellDataType
    private let displayedOptions: [Rust.CalendarAccessRole] = [.freeBusyReader, .reader, .writer, .owner]

    private typealias Panel = CalendarEditRoleSelectionView

    init(memberData: CalendarMemberCellDataType) {
        self.memberData = memberData
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ud.bgFloatBase

        header.setUp(with: memberData)
        header.addBottomBorder(lineHeight: CGFloat(1.0 / UIScreen.main.scale))
        header.closeBtn.isHidden = modalPresentationStyle == .popover
        header.closeBtnOnClicked = { [weak self] in
            self?.dismiss(animated: true)
        }
        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.height.equalTo(MemberEditUI.headerHeight)
            make.top.leading.trailing.equalToSuperview()
        }

        let options = displayedOptions.map {
            let canSelect: Bool
            if let highestRole = memberData.highestRole {
                canSelect = $0 <= highestRole
            } else { canSelect = false }
            return SelectionCellData(canSelect: canSelect, title: $0.cd.shareOption, content: $0.cd.shareOptionDescription)
        }
        let optionsPanel = Panel(contents: options, bgColor: .ud.bgFloat)
        optionsPanel.backgroundColor = .ud.bgFloat
        optionsPanel.layer.cornerRadius = 12
        optionsPanel.clipsToBounds = true
        optionsPanel.selectedIndex = displayedOptions.firstIndex(of: memberData.role) ?? -1
        view.addSubview(optionsPanel)
        optionsPanel.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
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

        removeBtn.backgroundColors = (UIColor.ud.bgFloat, UIColor.ud.fillPressed)
        removeBtn.setTitle(with: I18n.Calendar_Share_RemoveMemberButton, color: .ud.functionDangerContentDefault)
        removeBtn.layer.cornerRadius = 12
        view.addSubview(removeBtn)
        removeBtn.snp.makeConstraints { make in
            make.top.equalTo(optionsPanel.snp.bottom).offset(16)
            make.height.equalTo(MemberEditUI.removeBtnHeight)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        removeBtn.onClick = { [weak self] in
            self?.deleteHandler?()
            self?.dismiss(animated: true)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MembersEditViewController {
    var contentHeight: CGFloat {
        let itemNum = displayedOptions.count
        let sepeNum = Double(itemNum - 1)
        let panelHeight = Double(Panel.UI.cellHeight * itemNum) + Panel.UI.seperatorHeight * sepeNum
        let bottomMargin = 32.0
        return MemberEditUI.headerHeight + panelHeight + MemberEditUI.removeBtnHeight + 32 + bottomMargin
    }

    fileprivate struct MemberEditUI {
        static let headerHeight = 68.0
        static let removeBtnHeight = 48.0
    }
}
