//
//  FeedMsgDisplaySettingView.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/23.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignCheckBox

class FeedMsgDisplayCell: BaseTableViewCell {
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        return label
    }()

    var bottomSeperator: UIView?
    let singleCheckbox = UDCheckBox(boxType: .single)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func setupViews() {
        selectionStyle = .none
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(48)
            make.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(12)
        }

        singleCheckbox.isUserInteractionEnabled = false
        contentView.addSubview(singleCheckbox)
        singleCheckbox.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(16)
            make.width.height.equalTo(20)
        }

        bottomSeperator = lu.addBottomBorder(leading: 16)
    }

    var item: FeedMsgDisplayCellItem? {
        didSet {
            setCellInfo()
        }
    }

    open func setCellInfo() {
        guard let currItem = self.item as? FeedMsgDisplayCellViewModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = currItem.title
        bottomSeperator?.isHidden = currItem.isLastRow
        singleCheckbox.isSelected = currItem.isSelected
    }
}

final class FeedMsgDisplayCheckBoxCell: FeedMsgDisplayCell {
    let multipleCheckbox = UDCheckBox(boxType: .multiple)

    override func setupViews() {
        selectionStyle = .none
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(80)
            make.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(12)
        }

        multipleCheckbox.isUserInteractionEnabled = false
        contentView.addSubview(multipleCheckbox)
        multipleCheckbox.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(48)
            make.width.height.equalTo(20)
        }

        bottomSeperator = lu.addBottomBorder(leading: 48)
    }

    override func setCellInfo() {
        guard let currItem = self.item as? FeedMsgDisplayCellViewModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = currItem.title
        bottomSeperator?.isHidden = currItem.isLastRow
        multipleCheckbox.isSelected = currItem.isSelected
        multipleCheckbox.isEnabled = currItem.editEnable
    }
}
