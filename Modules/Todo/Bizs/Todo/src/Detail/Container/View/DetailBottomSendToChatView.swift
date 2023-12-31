//
//  DetailBottomSendToChatView.swift
//  Todo
//
//  Created by baiyantao on 2023/3/31.
//

import Foundation
import UniverseDesignCheckBox
import UniverseDesignFont

final class DetailBottomSendToChatView: UIView {

    var onToggleCheckbox: ((_ isSelected: Bool) -> Void)?

    private lazy var checkbox = initCheckbox()
    private lazy var checkboxLabel = initCheckboxLabel()

    init(isSelected: Bool) {
        super.init(frame: .zero)

        addSubview(checkbox)
        checkbox.isUserInteractionEnabled = false
        checkbox.isSelected = isSelected
        checkbox.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview()
            $0.width.height.equalTo(20)
        }

        addSubview(checkboxLabel)
        checkboxLabel.isUserInteractionEnabled = false
        checkboxLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalTo(checkbox.snp.right).offset(8)
            $0.right.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleCheckbox))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateTitle(_ text: String?) {
        checkboxLabel.text = text
    }

    private func initCheckbox() -> UDCheckBox {
        var config = UDCheckBoxUIConfig()
        config.style = .circle
        let checkbox = UDCheckBox(boxType: .multiple, config: config)
        checkbox.isEnabled = true
        return checkbox
    }

    private func initCheckboxLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 16)
        label.numberOfLines = 1
        return label
    }

    @objc
    private func toggleCheckbox() {
        checkbox.isSelected = !checkbox.isSelected
        onToggleCheckbox?(checkbox.isSelected)
    }
}
