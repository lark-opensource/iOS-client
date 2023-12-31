//
//  FeedFloatMenuOptionView.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/12/3.
//

import Foundation
import LarkUIKit
import SnapKit
import UniverseDesignIcon
import LarkInteraction
import LarkOpenFeed
import UIKit

extension FeedFloatMenuOptionView {

    enum Layout {
        // 图标大小
        static let iconSize: CGFloat = 20.0
        // 图标左边距
        static let iconLeading: CGFloat = 15.0
        // 标题左边距
        static let titleLeading: CGFloat = 10.0
        // 标题右边距
        static let titleTrailing: CGFloat = 15.0
        // 高亮边距
        static let highlightInset: CGFloat = 4.0
    }

}

final class FeedFloatMenuOptionView: UIView {

    let item: FloatMenuOptionItem

    private let iconView = UIImageView(frame: .zero)

    private let titleLabel = UILabel(frame: .zero)

    /// 高亮区域、Pointer 区域、点击热区
    let tapArea = MenuHighlightControl()

    init(item: FloatMenuOptionItem) {
        self.item = item
        super.init(frame: .zero)

        setupViews()
        setupLayouts()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        iconView.image = item.icon
        titleLabel.font = .systemFont(ofSize: 16.0, weight: .regular)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.text = item.title
        tapArea.backgroundColor = .clear
        tapArea.layer.cornerRadius = 6.0
        tapArea.feedFloatMenuOptionView = self
    }

    private func setupLayouts() {
        addSubview(tapArea)
        tapArea.addSubview(iconView)
        tapArea.addSubview(titleLabel)

        tapArea.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(Layout.highlightInset)
            make.centerY.equalToSuperview()
        }
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: PointerStyle(
                    effect: .hover(prefersScaledContent: false)
                )
            )
            tapArea.addLKInteraction(pointer)
        }

        iconView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: Layout.iconSize, height: Layout.iconSize))
            make.leading.equalToSuperview().offset(Layout.iconLeading - Layout.highlightInset)
            make.centerY.equalToSuperview()
        }

        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(
            UILayoutPriority(rawValue: UILayoutPriority.defaultHigh.rawValue - 1),
            for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(iconView.snp.trailing).offset(Layout.titleLeading)
            make.trailing.equalToSuperview().inset(Layout.titleTrailing - Layout.highlightInset)
            make.centerY.equalToSuperview()
        }
    }
}

final class MenuHighlightControl: UIControl {
    weak var feedFloatMenuOptionView: FeedFloatMenuOptionView?
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor.ud.fillHover : .clear
        }
    }
}
