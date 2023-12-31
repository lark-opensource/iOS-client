//
//  ItemCollectionIconCell.swift
//  LarkListItem
//
//  Created by Yuri on 2023/8/31.
//

import UIKit
import SnapKit

public class ItemCollectionIconCell: UICollectionViewCell, ItemViewContextable {
    public var context: ListItemContext

    public var node: ListItemNode? {
        didSet {
            guard let node = node else { return }
            iconView.icon = node.icon
        }
    }

    lazy var iconView: ItemIconView = { ItemIconView(context: self.context) }()

    override init(frame: CGRect) {
        self.context = ListItemContext()
        super.init(frame: frame)
        render()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func render() {
        contentView.addSubview(iconView)
        iconView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
