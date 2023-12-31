//
//  ItemBodyDescriptionView.swift
//  CryptoSwift
//
//  Created by Yuri on 2023/5/30.
//

import UIKit
import SnapKit
import UniverseDesignColor

final class ItemBodyDescriptionView: UIView {
    let stackView = UIStackView()

    var descLabel = ItemLabel()

    var node: ListItemNode? {
        didSet {
            guard let node = node else { return }
            self.isHidden = node.desc == nil
            descLabel.attributedText = node.desc
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
        let fontSize: CGFloat = 14
        descLabel.textColor = UIColor.ud.textPlaceholder
        descLabel.font = UIFont.systemFont(ofSize: fontSize)

        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 8
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
        }

        stackView.addArrangedSubview(descLabel)
    }
}
