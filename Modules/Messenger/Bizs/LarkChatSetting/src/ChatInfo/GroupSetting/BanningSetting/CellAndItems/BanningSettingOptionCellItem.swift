//
//  BanningSettingOptionCellItem.swift
//  LarkChat
//
//  Created by kkk on 2019/3/11.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkModel
import UniverseDesignCheckBox
import UniverseDesignColor

protocol BanningSettingOption: BanningSettingItem {
    var title: String { get set }
    var isSelected: Bool { get set }
    var isSeparaterHidden: Bool { get set }
}

struct BanningSettingOptionItem<T>: BanningSettingOption {
    var isSelected: Bool
    var title: String
    var seletedType: T // 供点击事件使用
    var isSeparaterHidden: Bool
    var identifier: String
}

final class BanningSettingOptionCell: BaseSettingCell, BanningSettingCell {
    private let titleLabel = UILabel()
    private let checkBox = UDCheckBox(boxType: .single)
    private(set) var item: BanningSettingItem?
    private lazy var separater: UIView = {
        let view = self.lu.addBottomBorder(leading: 16)
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // not intercept the cell click event
        checkBox.isUserInteractionEnabled = false
        contentView.addSubview(checkBox)
        checkBox.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(16)
            make.size.equalTo(LKCheckbox.Layout.iconMidSize)
        }

        titleLabel.textColor = UIColor.ud.N900
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        contentView.addSubview(titleLabel)
        titleLabel.numberOfLines = 0
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(14)
            maker.bottom.equalToSuperview().offset(-14)
            maker.left.equalTo(checkBox.snp.right).offset(16)
            maker.right.equalTo(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(item: BanningSettingItem) {
        guard let item = item as? BanningSettingOption else {
            assert(false, "item type error")
            return
        }
        self.item = item
        checkBox.isSelected = item.isSelected
        titleLabel.text = item.title
        separater.isHidden = item.isSeparaterHidden
    }
}
