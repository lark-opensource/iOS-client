//
//  ItemSubtitleView.swift
//  LarkListItem
//
//  Created by Yuri on 2023/10/9.
//

import UIKit
import SnapKit
import UniverseDesignColor

class ItemSubtitleView: UIView {

    var stackView = UIStackView()
    var lineView = UIView()
    var titleLabel = ItemLabel()

    var node: ListItemNode? {
        didSet {
            self.isHidden = node?.subtitle == nil
            guard let node else { return }
            titleLabel.attributedText = node.subtitle
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        render()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func render() {
        stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        lineView.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 1, height: 12))
        }
        stackView.addArrangedSubview(lineView)

        titleLabel.textColor = UIColor.ud.textPlaceholder
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        stackView.addArrangedSubview(titleLabel)
    }
}
