//
//  PickerSelectListCell.swift
//  LarkListItem
//
//  Created by Yuri on 2023/10/20.
//

import Foundation
import SnapKit

final public class PickerSelectListCell: UITableViewCell, ItemViewContextable {
    public var context: ListItemContext

    public var node: ListItemNode? {
        didSet {
            iconView.icon = node?.icon
            infoView.node = node
            accessoriesView.node = node
        }
    }
    public weak var delegate: ItemTableViewCellDelegate? {
        didSet {
            self.context.delegate = delegate
        }
    }

    let stackView = UIStackView()
    let infoStackView = UIStackView()
    lazy var iconView = ItemIconView(context: self.context)
    lazy var infoView = ItemBodyInfoView(context: self.context)
    lazy var accessoriesView = ItemAccessoryView(context: self.context)
    let divide = ItemDivideView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.context = ListItemContext()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        render()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func render() {
        contentView.addSubview(stackView)
        self.backgroundColor = .clear
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.top.bottom.equalToSuperview()
            $0.trailing.equalTo(-16)
        }

        infoStackView.axis = .horizontal
        infoStackView.spacing = 12


        stackView.addArrangedSubview(infoStackView)
        stackView.addArrangedSubview(accessoriesView)

        iconView.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 40, height: 40))
        }
        infoStackView.addArrangedSubview(iconView)
        infoStackView.addArrangedSubview(infoView)

        contentView.addSubview(divide)
        divide.snp.makeConstraints {
            $0.leading.equalTo(infoView.snp.leading)
            $0.height.equalTo(1 / UIScreen.main.scale)
            $0.bottom.equalToSuperview()
            $0.trailing.equalTo(self.snp.trailing)
        }
    }
}
