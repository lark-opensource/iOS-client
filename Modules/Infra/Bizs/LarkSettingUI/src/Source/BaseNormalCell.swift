//
//  BaseNormalCell.swift
//  LarkMine
//
//  Created by panbinghua on 2021/12/7.
//

import Foundation
import UIKit
import UniverseDesignIcon

open class BaseNormalCellProp: CellProp {
    var title: String
    var detail: String?

    public init(title: String, detail: String? = nil,
         cellIdentifier: String = "BaseNormalCell",
         separatorLineStyle: CellSeparatorLineStyle = .normal,
         selectionStyle: CellSelectionStyle = .normal,
         id: String? = nil) {
        self.title = title
        self.detail = detail
        super.init(cellIdentifier: cellIdentifier,
                   separatorLineStyle: separatorLineStyle,
                   selectionStyle: selectionStyle,
                   id: id)
    }
}

open class BaseNormalCell: BaseCell {

    let verticalSpacing: CGFloat = 13.0
    let horizontalSpacing: CGFloat = 16.0
    let minimalHeight: CGFloat = 28.0

    open override func update(_ info: CellProp) {
        super.update(info)
        guard let info = info as? BaseNormalCellProp else { return }
        titleLabel.setFigmaText(info.title)
        detailLabel.setFigmaText(info.detail)
        detailLabel.isHidden = info.detail == nil
    }

    lazy var contentContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        return stack
    }()

    private lazy var textContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.addArrangedSubview(ViewHelper.stackPlaceholderSpring(axis: .horizontal,
                                                                                corssAxisLength: verticalSpacing))
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(detailLabel)
        stack.addArrangedSubview(ViewHelper.stackPlaceholderFixed(aspect: .height(verticalSpacing)))
        stack.spacing = 0
        return stack
    }()

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal) // 必须完整显示，不能被压缩
        return label
    }()

    private(set) lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)  // 可以被压(成多行)
        return label
    }()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(contentContainer)
        setupContainerStackView(contentContainer)
        contentContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(horizontalSpacing)
            make.trailing.equalToSuperview().offset(-horizontalSpacing)
            make.top.bottom.equalToSuperview()
            make.height.greaterThanOrEqualTo(minimalHeight).priority(.high)
        }
    }

    func setupContainerStackView(_ contentContainer: UIStackView) {
        if let leadingView = getLeadingView() {
            contentContainer.addArrangedSubview(leadingView)
        }
        contentContainer.addArrangedSubview(textContainer)
        if let trailingView = getTrailingView() {
            contentContainer.addArrangedSubview(trailingView)
        }
    }
    /// 必须明确尺寸约束，否则会布局混乱
    open func getLeadingView() -> UIView? {
        return nil
    }
    /// 必须明确尺寸约束，否则会布局混乱
    open func getTrailingView() -> UIView? {
        return nil
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
