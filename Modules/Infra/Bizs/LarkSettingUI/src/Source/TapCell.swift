//
//  TapCell.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/19.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignTheme

public final class TapCellProp: CellProp, CellClickable {
    var title: String
    var color: UIColor
    public var onClick: ClickHandler?

    public init(title: String,
         color: UIColor = UIColor.ud.textTitle,
         cellIdentifier: String = "TapCell",
         separatorLineStyle: CellSeparatorLineStyle = .normal,
         selectionStyle: CellSelectionStyle = .normal,
         id: String? = nil,
         onClick: ClickHandler? = nil) {
        self.title = title
        self.color = color
        self.onClick = onClick
        super.init(cellIdentifier: cellIdentifier,
                   separatorLineStyle: separatorLineStyle,
                   selectionStyle: selectionStyle,
                   id: id)
    }
}

public final class TapCell: BaseCell {
    let minimalHeight: CGFloat = 28.0 // line 22 + vertical padding 2*13
    let verticalSpacing: CGFloat = 13.0
    let horizontalSpacing: CGFloat = 16.0

    /// 必须明确尺寸约束，否则会布局混乱
    func getLeadingView() -> UIView? {
        return nil
    }

    /// 必须明确尺寸约束，否则会布局混乱
    func getTrailingView() -> UIView? {
        return nil
    }

    lazy var contentContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 4
        return stack
    }()

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
//        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal) // 必须完整显示，不能被压缩
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(contentContainer)
        setupContainerStackView(contentContainer)
        contentContainer.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(minimalHeight).priority(.high)
            make.top.equalToSuperview().offset(verticalSpacing)
            make.bottom.equalToSuperview().offset(-verticalSpacing)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().offset(-2*horizontalSpacing)
        }
    }

    private func setupContainerStackView(_ contentContainer: UIStackView) {
        if let leadingView = getLeadingView() {
            contentContainer.addArrangedSubview(leadingView)
        }
        contentContainer.addArrangedSubview(titleLabel)
        if let trailingView = getTrailingView() {
            contentContainer.addArrangedSubview(trailingView)
        }
    }

    public override func update(_ info: CellProp) {
        super.update(info)
        guard let info = info as? TapCellProp else { return }
        titleLabel.textColor = info.color
        titleLabel.setFigmaText(info.title)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
