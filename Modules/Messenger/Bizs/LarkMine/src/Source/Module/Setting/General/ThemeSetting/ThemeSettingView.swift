//
//  ThemeSettingView.swift
//  LarkMine
//
//  Created by bytedance on 2021/4/20.
//

import Foundation
import UIKit
import UniverseDesignCheckBox
import LarkUIKit

final class ThemeSettingCell: BaseSettingCell {

    func configure(with items: [ThemeSettingItem]) {
        settingItemViews.removeAll()
        stackView.subviews.forEach { $0.removeFromSuperview() }
        for item in items {
            let itemView = ThemeSettingItemView()
            itemView.configure(item: item)
            settingItemViews.append(itemView)
            stackView.addArrangedSubview(itemView)
        }
    }

    private lazy var settingItemViews: [ThemeSettingItemView] = []

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        return stack
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(18)
            make.right.equalToSuperview().offset(-18)
            make.top.equalToSuperview().offset(32)
            make.bottom.equalToSuperview().offset(-28)
        }
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let offset = (bounds.width - 64 * 3) / 8
        stackView.snp.updateConstraints { update in
            update.left.equalToSuperview().offset(offset)
            update.right.equalToSuperview().offset(-offset)
        }
    }
}

final class ThemeSettingItemView: UIView {

    func configure(item: ThemeSettingItem) {
        self.item = item
        titleLabel.text = item.name
        imageView.image = item.image
        checkBox.isSelected = item.isSelected
        checkBox.isEnabled = item.isEnabled
    }

    private var item: ThemeSettingItem?

    @objc
    private func didTapItemView() {
        item?.onSelect?()
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Cons.itemFontColor
        label.font = Cons.itemFont
        label.numberOfLines = 0
        label.textAlignment = .center
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return label
    }()

    private lazy var checkBox: UDCheckBox = {
        let checkbox = UDCheckBox()
        checkbox.isUserInteractionEnabled = false
        return checkbox
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(checkBox)
        imageView.snp.makeConstraints { make in
            make.width.equalTo(64)
            make.height.equalTo(120)
            make.top.centerX.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.width.equalToSuperview().inset(4)
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(12)
            make.bottom.equalTo(checkBox.snp.top).offset(-8)
            make.height.greaterThanOrEqualTo(Cons.itemFont.figmaHeight)
        }
        checkBox.snp.makeConstraints { make in
            make.bottom.centerX.equalToSuperview()
            make.width.height.equalTo(20)
        }
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapItemView)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum Cons {
    static var itemFont: UIFont { UIFont.ud.body2 }
    static var itemFontColor: UIColor { UIColor.ud.textTitle }
}
