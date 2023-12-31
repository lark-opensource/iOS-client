//
//  FloatActionCell.swift
//  SKCommon
//
//  Created by zoujie on 2021/1/4.
//  


import Foundation
import LarkUIKit
import SnapKit
import UniverseDesignColor

extension FloatActionCell {

    enum Layout {
        // 图标大小
        static let iconSize: CGFloat = 20.0
        // 图标左边距
        static let iconLeading: CGFloat = 15.0
        // 标题左边距
        static let titleLeading: CGFloat = 10.0
        // 标题右边距
        static let titleTrailing: CGFloat = 56.0
    }

}

class FloatActionCell: UIControl {

    let item: FloatActionItem

    private let iconView = UIImageView(frame: .zero)

    private let titleLabel = UILabel(frame: .zero)

    override var isHighlighted: Bool {
        didSet {
            self.backgroundColor = isHighlighted ? UDColor.bgFiller : UDColor.bgFloat
        }
    }

    init(item: FloatActionItem) {
        self.item = item
        super.init(frame: .zero)

        setupViews()
        setupLayouts()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        if !item.enable {
            //不可点击需置灰
            self.backgroundColor = UDColor.bgFloat
        }

        self.isEnabled = item.enable
        self.docs.addStandardHover()
        iconView.image = item.icon.ud.withTintColor(UDColor.iconN1)

        titleLabel.font = .systemFont(ofSize: 16.0, weight: .regular)
        titleLabel.textColor = UDColor.N900
        titleLabel.text = item.title

        lu.addBottomBorder(color: UIColor.ud.commonTableSeparatorColor)
    }

    private func setupLayouts() {
        addSubview(iconView)
        addSubview(titleLabel)

        iconView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: Layout.iconSize, height: Layout.iconSize))
            make.leading.equalToSuperview().offset(Layout.iconLeading)
            make.centerY.equalToSuperview()
        }

        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(iconView.snp.trailing).offset(Layout.titleLeading)
            make.trailing.equalToSuperview().offset(-Layout.titleTrailing)
            make.centerY.equalToSuperview()
        }
    }
}
