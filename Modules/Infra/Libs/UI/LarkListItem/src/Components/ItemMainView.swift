//
//  ItemMainView.swift
//  LarkListItem
//
//  Created by Yuri on 2023/5/29.
//

import UIKit
import LarkUIKit

final class ItemMainView: UIView, ItemViewContextable {
    var context: ListItemContext

    let avatarSize = CGSize(width: 48, height: 48)
    // stack view
    let stackView = UIStackView()
    // components
    public lazy var iconView = ItemIconView(context: self.context)
    public lazy var bodyView = ItemBodyView(context: self.context)

    var node: ListItemNode? {
        didSet {
            guard let node = node else { return }
            iconView.icon = node.icon
            bodyView.node = node
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
        renderAvatar()

        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(bodyView)
    }

    private func renderAvatar() {
        iconView.snp.makeConstraints {
            $0.size.equalTo(avatarSize)
        }
    }

    private func renderBody() {

    }
}
