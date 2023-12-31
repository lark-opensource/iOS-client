//
//  CCMTypeFilterCell.swift
//  CCMMod
//
//  Created by Weston Wu on 2023/5/17.
//

import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignCheckBox

class CCMTypeFilterCell: UITableViewCell {

    private lazy var checkBox: UDCheckBox = {
        let checkBox = UDCheckBox(boxType: .multiple)
        // checkBox 不直接响应选中事件，走 TableView 的处理流程
        checkBox.isUserInteractionEnabled = false
        return checkBox
    }()

    private var inMultiSelectionMode = false

    private lazy var bottomSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    private lazy var typeNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UDColor.textColor
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(typeNameLabel)
        typeNameLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(16)
            make.height.greaterThanOrEqualTo(22)
            make.right.lessThanOrEqualToSuperview().inset(16)
        }

        contentView.addSubview(checkBox)
        checkBox.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.centerY.equalToSuperview()
            // 默认展示在视图外
            make.left.equalToSuperview().offset(-16)
        }
        checkBox.isHidden = true

        contentView.addSubview(bottomSeparatorView)
        bottomSeparatorView.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview()
            make.left.equalTo(typeNameLabel.snp.left)
            make.height.equalTo(0.5)
        }
    }

    func switchToMultiSelectionStyle(animated: Bool) {
        if inMultiSelectionMode { return }
        selectionStyle = .none
        inMultiSelectionMode = true
        checkBox.isHidden = false
        let animationBlock: () -> Void = { [self] in
            checkBox.snp.updateConstraints { make in
                make.left.equalToSuperview().offset(16)
            }
            typeNameLabel.snp.updateConstraints { make in
                make.left.equalToSuperview().inset(48)
            }
            contentView.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: animationBlock)
        } else {
            animationBlock()
        }
    }

    func update(title: String) {
        typeNameLabel.text = title
    }

    func update(shouldHideSeparator: Bool) {
        bottomSeparatorView.isHidden = shouldHideSeparator
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        checkBox.isSelected = selected
    }
}
