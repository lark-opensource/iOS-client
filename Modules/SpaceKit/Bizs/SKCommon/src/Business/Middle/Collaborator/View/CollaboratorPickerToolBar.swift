//
//  CollaboratorPickerToolBar.swift
//  SKCommon
//
//  Created by liweiye on 2020/9/2.
//

import Foundation
import UIKit
import LarkButton
import LarkUIKit
import SKResource
import UniverseDesignColor

public final class CollaboratorPickerToolBar: PickerToolBar {
    public var selectedButtonTappedBlock: ((CollaboratorPickerToolBar) -> Void)?
    public var confirmButtonTappedBlock: ((CollaboratorPickerToolBar) -> Void)?

    public lazy var confirmButtonItem: UIBarButtonItem = {
        let confirmButton = TypeButton(style: .normalA)
        confirmButton.setTitle(BundleI18n.SKResource.Doc_Share_Next, withFontSize: 14, fontWeight: .regular, color: UDColor.primaryOnPrimaryFill, forState: .normal)
        confirmButton.setTitle(BundleI18n.SKResource.Doc_Share_Next, withFontSize: 14, fontWeight: .regular, color: UDColor.udtokenBtnPriTextDisabled, forState: .disabled)
        confirmButton.setBackgroundColor(UDColor.fillDisable, for: .disabled)

        confirmButton.isEnabled = false
        confirmButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        confirmButton.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)
        confirmButton.sizeToFit()
        confirmButton.docs.addStandardLift()
        return UIBarButtonItem(customView: confirmButton)
    }()

    public lazy var selectedResultButtonItem: UIBarButtonItem = {
        let resultButton = TypeButton(style: .textA)
        resultButton.addTarget(self, action: #selector(didTapSelected), for: .touchUpInside)
        resultButton.sizeToFit()
        resultButton.isEnabled = true
        return UIBarButtonItem(customView: resultButton)
    }()

    public override func toolbarItems() -> [UIBarButtonItem] {
        let fixedSpaceBarItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpaceBarItem.width = 16
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

        confirmBtn.sizeToFit()
        confirmButtonItem.width = confirmBtn.frame.size.width

        let title = BundleI18n.SKResource.Doc_Permission_AddUserSelectedTips(firstSelectedItems.count)
        selectedButton.setTitle(title, for: .normal)
        selectedButton.sizeToFit()
        selectedButton.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        selectedButton.backgroundColor = UDColor.bgBody
        selectedResultButtonItem.width = selectedButton.frame.size.width

        if self.allowSelectNone {
            confirmBtn.isEnabled = true
        } else {
            confirmBtn.isEnabled = (secondSelectedItems.count + firstSelectedItems.count) > 0
        }

        contentDidUpdateBlock?(self)
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
