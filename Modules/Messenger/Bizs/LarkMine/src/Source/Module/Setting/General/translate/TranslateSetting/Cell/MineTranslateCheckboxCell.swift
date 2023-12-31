//
//  MineTranslateCheckboxCell.swift
//  Lark
//
//  Created by zhenning on 2020/02/11.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignCheckBox

struct MineTranslateCheckboxModel: MineTranslateItemProtocol {
    var cellIdentifier: String
    var title: String
    var detail: String = ""
    var status: Bool
    var enabled: Bool = true
    var switchHandler: MineTranslateSwitchHandler
}

/// title + detail + checkbox
final class MineTranslateCheckboxCell: MineTranslateBaseCell {

    /// 开关
    private lazy var checkBox: UDCheckBox = {
        let checkbox = UDCheckBox(boxType: .multiple)
        checkbox.isEnabled = false
        checkbox.isUserInteractionEnabled = false
        return checkbox
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()

    /// 中间标题
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()

    /// 详情
    private lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(checkBox)
        contentView.addSubview(contentStack)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(detailLabel)
        checkBox.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }
        contentStack.snp.makeConstraints { make in
            make.top.greaterThanOrEqualToSuperview().offset(16)
            make.bottom.lessThanOrEqualToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
            make.leading.equalTo(checkBox.snp.trailing).offset(16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let currItem = self.item as? MineTranslateCheckboxModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        checkBox.isSelected = currItem.status
        checkBox.isEnabled = currItem.enabled
        titleLabel.text = currItem.title
        detailLabel.text = currItem.detail
        let shouldHideDetail = currItem.detail.isEmpty
        detailLabel.isHidden = shouldHideDetail
    }

    func checkBoxTapHandle() {
        self.checkBox.isSelected = !self.checkBox.isSelected
        if let currItem = self.item as? MineTranslateCheckboxModel {
            currItem.switchHandler(checkBox.isSelected)
        }
    }
}
