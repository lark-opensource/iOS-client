//
//  ItemCellContentView.swift
//  LarkListItem
//
//  Created by Yuri on 2023/5/26.
//

import UIKit
import SnapKit
import LarkUIKit

class ItemCellContentView: UIView, ItemViewContextable {
    var context: ListItemContext

    let stackView = UIStackView()
    public let checkBox = LKCheckbox(boxType: .multiple)
    lazy var mainView = ItemMainView(context: self.context)
    lazy var accessoryView = ItemAccessoryView(context: self.context)

    var node: ListItemNode? {
        didSet {
            accessoryView.node = node
            guard let node = node else { return }
            let hasCheckBox = node.checkBoxState.isShow
            let leadingOffset: CGFloat = hasCheckBox ? 16 : 22
            stackView.snp.updateConstraints {
                $0.leading.equalToSuperview().offset(leadingOffset)
            }
            mainView.node = node
            updateCheckBox(node: node)
        }
    }

    init(context: ListItemContext) {
        self.context = context
        super.init(frame: .zero)
        render()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateCheckBox(node: ListItemNode) {
        let state = node.checkBoxState
        checkBox.isHidden = !state.isShow
        checkBox.isSelected = state.isSelected
        checkBox.isEnabled = state.isEnable
    }

    private func render() {
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
        }
        renderCheckBox()

        stackView.addArrangedSubview(checkBox)
        stackView.addArrangedSubview(mainView)
        stackView.addArrangedSubview(accessoryView)
    }

    private func renderCheckBox() {
        checkBox.isUserInteractionEnabled = false
        checkBox.snp.makeConstraints({ make in
            make.size.equalTo(LKCheckbox.Layout.iconMidSize)
        })
    }
}
