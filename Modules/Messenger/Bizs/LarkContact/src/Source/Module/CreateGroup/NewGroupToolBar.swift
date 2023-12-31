//
//  NewGroupToolBar.swift
//  LarkContact
//
//  Created by lizhiqiang on 2019/5/15.
//

import UIKit
import Foundation

import LarkUIKit
import LarkButton

public final class NewGroupToolBar: PickerToolBar {
    public var selectedButtonTappedBlock: ((PickerToolBar) -> Void)?
    public var confirmButtonTappedBlock: ((PickerToolBar) -> Void)?
    public var confirmButtonTittle = BundleI18n.LarkContact.Lark_Group_CreateGroup_CreateGroup_TypePublic_CreateButton {
        didSet {
            confirmButton.setTitle(confirmButtonTittle, for: .normal)
            confirmButton.sizeToFit()
        }
    }

    public lazy var confirmButton: TypeButton = {
        let confirmButton = TypeButton(style: .normalA)
        confirmButton.setTitle(confirmButtonTittle, for: .normal)
        confirmButton.isEnabled = false
        confirmButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        confirmButton.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)
        confirmButton.sizeToFit()

        return confirmButton
    }()

    public lazy var confirmButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(customView: confirmButton)
    }()

    public lazy var selectedResultButtonItem: UIBarButtonItem = {
        let resultButton = TypeButton(style: .textA)
        resultButton.addTarget(self, action: #selector(didTapSelected), for: .touchUpInside)
        resultButton.sizeToFit()
        return UIBarButtonItem(customView: resultButton)
    }()

    public override var frame: CGRect {
        didSet {
            resizeConfirmButton(with: bounds.width)
        }
    }

    private func resizeConfirmButton(with maxAvailableWidth: CGFloat) {
        guard let confirmBtn = self.confirmButtonItem.customView as? UIButton else { return }

        let defaultMinWidth = confirmButton.defaultMinWidth(with: maxAvailableWidth)
        confirmBtn.sizeToFit()
        let width = confirmBtn.frame.size.width < defaultMinWidth ? defaultMinWidth : confirmBtn.frame.size.width
        let height = confirmButton.defaultHeight
        confirmBtn.frame = CGRect(origin: .zero, size: CGSize(width: width, height: height))
        confirmButtonItem.width = width
    }

    override public func toolbarItems() -> [UIBarButtonItem] {
        let fixedSpaceBarItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpaceBarItem.width = 5
        let flexibleSpaceBarItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        guard let selectedButton = self.selectedResultButtonItem.customView as? UIButton else { return [] }

        resizeConfirmButton(with: bounds.width)

        selectedButton.sizeToFit()
        selectedResultButtonItem.width = selectedButton.frame.size.width

        return [selectedResultButtonItem, flexibleSpaceBarItem, confirmButtonItem, fixedSpaceBarItem]
    }

    override public func updateSelectedItem(firstSelectedItems: [Any],
                                            secondSelectedItems: [Any],
                                            updateResultButton: Bool) {
        super.updateSelectedItem(firstSelectedItems: firstSelectedItems,
                                 secondSelectedItems: secondSelectedItems,
                                 updateResultButton: updateResultButton)

        guard let confirmBtn = self.confirmButtonItem.customView as? UIButton else { return }
        guard let selectedButton = self.selectedResultButtonItem.customView as? UIButton else { return }

        let totalSelect = firstSelectedItems.count + secondSelectedItems.count
        if updateResultButton {
            if totalSelect > 0 {
                confirmBtn.setTitle("\(confirmButtonTittle)(\(totalSelect))", for: .normal)
            } else {
                confirmBtn.setTitle(confirmButtonTittle, for: .normal)
            }
        } else {
            confirmBtn.setTitle(confirmButtonTittle, for: .normal)
        }

        selectedResultButtonItem.isEnabled = totalSelect > 0

        confirmBtn.sizeToFit()
        confirmButtonItem.width = confirmBtn.frame.size.width
        var title = BundleI18n.LarkContact.Lark_Legacy_HasSelected
        if firstSelectedItems.count > 1 {
            title.append(String(format: BundleI18n.LarkContact.Lark_Legacy_SelectedNumberOfPeople, firstSelectedItems.count))
        } else {
            title.append(String(format: BundleI18n.LarkContact.Lark_Legacy_SelectedSinglePerson, firstSelectedItems.count))
        }

        if secondSelectedItems.count > 1 {
            title.append("+")
            title.append(BundleI18n.LarkContact.Lark_Legacy_SelectedNumberOfChats(secondSelectedItems.count))
        } else if secondSelectedItems.count == 1 {
            title.append("+")
            title.append(BundleI18n.LarkContact.Lark_Legacy_SelectedSingleChat(secondSelectedItems.count))
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
