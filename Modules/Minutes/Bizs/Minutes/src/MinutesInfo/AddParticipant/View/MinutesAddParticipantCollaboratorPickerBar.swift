//
//  MinutesAddParticipantCollaboratorPickerBar.swift
//  Minutes
//
//  Created by panzaofeng on 2021/6/16.
//  Copyright © 2021年 panzaofeng. All rights reserved.
//

import UIKit
import SnapKit
import MinutesFoundation
import Kingfisher
import LarkUIKit
import LarkButton

public final class MinutesAddParticipantCollaboratorPickerBar: PickerToolBar {

    public var selectedButtonTappedBlock: ((MinutesAddParticipantCollaboratorPickerBar) -> Void)?
    public var confirmButtonTappedBlock: ((MinutesAddParticipantCollaboratorPickerBar) -> Void)?

    public lazy var confirmButtonItem: UIBarButtonItem = {
        let confirmButton = TypeButton(style: .normalA)
        confirmButton.backgroundColor = UIColor.ud.primaryContentDefault
        confirmButton.setTitle(BundleI18n.Minutes.MMWeb_G_AddAsParticipant_Button, for: .normal)
        confirmButton.layer.cornerRadius = 14
        confirmButton.isEnabled = false
        confirmButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        confirmButton.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)
        confirmButton.sizeToFit()
        return UIBarButtonItem(customView: confirmButton)
    }()

    public lazy var selectedResultButtonItem: UIBarButtonItem = {
        let resultButton = TypeButton(style: .textA)
        resultButton.backgroundColor = .clear
        resultButton.addTarget(self, action: #selector(didTapSelected), for: .touchUpInside)
        resultButton.sizeToFit()
        resultButton.setTitleColor(UIColor.ud.textPlaceholder, for: .normal)
        resultButton.isEnabled = true
        return UIBarButtonItem(customView: resultButton)
    }()

    public override func toolbarItems() -> [UIBarButtonItem] {
        let fixedSpaceBarItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        // disable-lint: magic number
        fixedSpaceBarItem.width = 20
        // enable-lint: magic number
        let flexibleSpaceBarItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        guard let confirmBtn = self.confirmButtonItem.customView as? UIButton else { return [] }
        guard let selectedButton = self.selectedResultButtonItem.customView as? UIButton else { return [] }

        confirmBtn.sizeToFit()
        confirmButtonItem.width = confirmBtn.frame.size.width

        selectedButton.sizeToFit()
        selectedResultButtonItem.width = selectedButton.frame.size.width

        return [selectedResultButtonItem, flexibleSpaceBarItem, confirmButtonItem, fixedSpaceBarItem]
    }

    public override func updateSelectedItem(firstSelectedItems: [Any],
                                            secondSelectedItems: [Any],
                                            updateResultButton: Bool) {
        super.updateSelectedItem(firstSelectedItems: firstSelectedItems,
                                 secondSelectedItems: secondSelectedItems,
                                 updateResultButton: updateResultButton)

        guard let confirmBtn = self.confirmButtonItem.customView as? UIButton else { return }
        guard let selectedButton = self.selectedResultButtonItem.customView as? UIButton else { return }

        handleUpdateUI(confirmBtn: confirmBtn, selectedButton: selectedButton, firstSelectedItems: firstSelectedItems, secondSelectedItems: secondSelectedItems)
        contentDidUpdateBlock?(self)
    }
    
    private func handleUpdateUI(confirmBtn: UIButton, selectedButton: UIButton, firstSelectedItems: [Any], secondSelectedItems:  [Any]) {
        confirmBtn.sizeToFit()
        confirmButtonItem.width = confirmBtn.frame.size.width

        let title = BundleI18n.Minutes.MMWeb_G_Selected + "\(firstSelectedItems.count)"
        selectedButton.setTitle(title, for: .normal)
        selectedButton.sizeToFit()
        selectedResultButtonItem.width = selectedButton.frame.size.width

        if self.allowSelectNone {
            confirmBtn.isEnabled = true
        } else {
            confirmBtn.isEnabled = (secondSelectedItems.count + firstSelectedItems.count) > 0
        }

    }

    @objc
    private func didTapConfirm() {
        confirmButtonTappedBlock?(self)
    }

    @objc
    private func didTapSelected() {
        selectedButtonTappedBlock?(self)
    }
}
