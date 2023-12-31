//
//  ItemBodyInfoView.swift
//  CryptoSwift
//
//  Created by Yuri on 2023/5/30.
//

import UIKit
import SnapKit
import UniverseDesignColor

class ItemBodyInfoView: UIView, ItemViewContextable {
    var context: ListItemContext

    let stackView = UIStackView()

    var titleLabel = ItemLabel()
    lazy var statusView = ItemStatusView(context: self.context)
    var subtitleView = ItemSubtitleView()
    var tagView = ItemTagView()

    var node: ListItemNode? {
        didSet {
            titleLabel.attributedText = node?.title
            statusView.node = node
            tagView.update(tags: node?.tags)
            subtitleView.node = node
        }
    }

    init(context: ListItemContext) {
        self.context = context
        super.init(frame: .zero)
        render()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func render() {
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 8
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        stackView.addArrangedSubview(titleLabel)

        statusView.isHidden = true
        statusView.snp.makeConstraints {
            $0.height.equalTo(20)
        }
        stackView.addArrangedSubview(statusView)

        subtitleView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        subtitleView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        subtitleView.snp.makeConstraints {
            $0.width.greaterThanOrEqualTo(32)
        }
        stackView.addArrangedSubview(subtitleView)
        stackView.addArrangedSubview(tagView)
    }
}
