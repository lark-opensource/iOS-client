//
//  ItemTableViewCell.swift
//  LarkListItem
//
//  Created by Yuri on 2023/5/26.
//

import UIKit
import SnapKit

final public class ItemTableViewCell: UITableViewCell, ItemViewContextable {
    public var context: ListItemContext

    public var node: ListItemNode? {
        didSet {
            guard let node = node else { return }
            cellView.node = node
        }
    }
    public weak var delegate: ItemTableViewCellDelegate? {
        didSet {
            self.context.delegate = delegate
        }
    }

    lazy var cellView = ItemCellContentView(context: self.context)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.context = ListItemContext()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        render()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func render() {
        self.backgroundColor = .clear
        contentView.addSubview(cellView)
        cellView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(12)
            $0.bottom.equalToSuperview().inset(12)
        }
    }
}
