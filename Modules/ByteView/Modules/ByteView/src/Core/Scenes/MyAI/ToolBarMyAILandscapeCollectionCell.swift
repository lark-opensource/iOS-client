//
//  ToolBarMyAILandscapeCollectionCell.swift
//  ByteView
//
//  Created by 陈乐辉 on 2023/12/20.
//

import Foundation
import FigmaKit

final class ToolBarMyAILandscapeCollectionCell: ToolBarLandscapeCollectionCell {

    lazy var gradientLabel: FKGradientLabel = {
        let label = FKGradientLabel(pattern: GradientPattern(direction: .diagonal45, colors: [UIColor(hex: "#4752E6"), UIColor(hex: "#CF5ECF")]))
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    override func setupSubviews() {
        super.setupSubviews()
        contentView.addSubview(gradientLabel)
        gradientLabel.snp.makeConstraints { make in
            make.edges.equalTo(titleLabel)
        }
    }

    override func update(with item: ToolBarItem) {
        super.update(with: item)
        if case .none = item.titleColor {
            gradientLabel.isHidden = true
            titleLabel.isHidden = false
        } else {
            gradientLabel.isHidden = false
            titleLabel.isHidden = true
            gradientLabel.attributedText = NSAttributedString(string: item.title, attributes: Self.attributes)
        }
    }
}
