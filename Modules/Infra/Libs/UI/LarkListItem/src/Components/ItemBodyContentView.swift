//
//  ItemBodyContentView.swift
//  CryptoSwift
//
//  Created by Yuri on 2023/5/30.
//

import UIKit

final class ItemBodyContentView: UIView {

    let stackView = UIStackView()

    var contentLabel = ItemLabel()

    var node: ListItemNode? {
        didSet {
            guard let node = node else { return }
            self.isHidden = node.content == nil
            self.contentLabel.attributedText = node.content
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
        contentLabel.textColor = UIColor.ud.textPlaceholder
        contentLabel.font = UIFont.systemFont(ofSize: fontSize)

        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 8
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
        }

        stackView.addArrangedSubview(contentLabel)
    }
}
