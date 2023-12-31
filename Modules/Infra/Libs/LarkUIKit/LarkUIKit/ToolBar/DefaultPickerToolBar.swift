//
//  DefaultPickerToolBar.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/6/1.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkButton

public final class DefaultPickerToolBar: PickerToolBar {
    public var selectedButtonTappedBlock: ((DefaultPickerToolBar) -> Void)?
    public var confirmButtonTappedBlock: ((DefaultPickerToolBar) -> Void)?

    public lazy var confirmButtonItem: UIBarButtonItem = {
        let confirmButton = TypeButton(style: .normalA)
        confirmButton.setTitle(BundleI18n.LarkUIKit.Lark_Legacy_ConfirmTip, for: .normal)
        confirmButton.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.fillDisabled), for: .disabled)
        confirmButton.setTitleColor(UIColor.ud.udtokenBtnPriTextDisabled, for: .disabled)
        confirmButton.isEnabled = false
        confirmButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        confirmButton.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)
        confirmButton.sizeToFit()
        return UIBarButtonItem(customView: confirmButton)
    }()

    public lazy var selectedResultButtonItem: UIBarButtonItem = {
        let resultButton = TypeButton(style: .textA)
        resultButton.backgroundColor = .clear
        resultButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        resultButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .disabled)
        resultButton.addTarget(self, action: #selector(didTapSelected), for: .touchUpInside)
        resultButton.sizeToFit()
        return UIBarButtonItem(customView: resultButton)
    }()

    public override func toolbarItems() -> [UIBarButtonItem] {
        let fixedSpaceBarItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpaceBarItem.width = 16
        let flexibleSpaceBarItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        guard let confirmBtn = self.confirmButtonItem.customView as? UIButton else { return [] }
        guard let selectedButton = self.selectedResultButtonItem.customView as? UIButton else { return [] }

        confirmBtn.sizeToFit()
        if let titleLabel = confirmBtn.titleLabel,
           confirmBtn.frame.size.width > 60 || confirmBtn.frame.size.width - titleLabel.frame.size.width < 16 {
                titleLabel.minimumScaleFactor = 0.9
                titleLabel.numberOfLines = 1
                titleLabel.adjustsFontSizeToFitWidth = true
                confirmBtn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
                confirmBtn.layoutIfNeeded()
        }
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

        let totalSelect = firstSelectedItems.count + secondSelectedItems.count
        var confirmBtntitle: String = ""
        if updateResultButton {
            if totalSelect > 0 {
                confirmBtntitle = "\(BundleI18n.LarkUIKit.Lark_Legacy_ConfirmTip)(\(totalSelect))"
            } else {
                confirmBtntitle = BundleI18n.LarkUIKit.Lark_Legacy_ConfirmTip
            }
        } else {
            confirmBtntitle = BundleI18n.LarkUIKit.Lark_Legacy_ConfirmTip
        }

        selectedResultButtonItem.isEnabled = totalSelect > 0

        confirmBtn.setTitle(confirmBtntitle, for: .normal)
        if let font = confirmBtn.titleLabel?.font {
            let width = ceil(confirmBtntitle.getWidth(font: font)) + confirmBtn.contentEdgeInsets.left + confirmBtn.contentEdgeInsets.right
            let rect = confirmBtn.frame
            confirmBtn.frame = CGRect(origin: rect.origin, size: CGSize(width: width, height: rect.size.height))
        }
        confirmButtonItem.width = confirmBtn.frame.size.width

        var title = BundleI18n.LarkUIKit.Lark_Legacy_HasSelected
        if firstSelectedItems.count > 1 {
            title.append(String(format: BundleI18n.LarkUIKit.Lark_Legacy_SelectedNumberOfPeople, firstSelectedItems.count))
        } else {
            title.append(String(format: BundleI18n.LarkUIKit.Lark_Legacy_SelectedSinglePerson, firstSelectedItems.count))
        }

        if secondSelectedItems.count > 1 {
            title.append("+")
            title.append(BundleI18n.LarkUIKit.Lark_Legacy_SelectedNumberOfChats(secondSelectedItems.count))
        } else if secondSelectedItems.count == 1 {
            title.append("+")
            title.append(BundleI18n.LarkUIKit.Lark_Legacy_SelectedSingleChat(secondSelectedItems.count))
        }

        selectedButton.setTitle(title, for: .normal)
        selectedButton.sizeToFit()
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
