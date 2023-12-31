//
//  ItemBodyView.swift
//  LarkListItem
//
//  Created by Yuri on 2023/5/31.
//

import UIKit
import SnapKit

class ItemBodyView: UIView, ItemViewContextable {
    var context: ListItemContext

    let stackView = UIStackView()
    lazy var infoView = ItemBodyInfoView(context: self.context)
    let contentView = ItemBodyContentView()
    let descView = ItemBodyDescriptionView()

    var node: ListItemNode? {
        didSet {
            guard let node = node else { return }
            infoView.node = node
            contentView.node = node
            descView.node = node
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
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 7
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview().inset(12)
        }

        contentView.isHidden = true
        descView.isHidden = true
        stackView.addArrangedSubview(infoView)
        stackView.addArrangedSubview(contentView)
        stackView.addArrangedSubview(descView)
    }
}
