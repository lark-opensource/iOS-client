//
//  SetInformationCheckCell.swift
//  LarkContact
//
//  Created by 强淑婷 on 2020/7/15.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignCheckBox

final class SetInformationCheckItem: SetInformationItemProtocol {
    var cellIdentifier: String
    var title: String
    var isSelected: Bool
    var checkHandler: SetInforamtionCheckHandler

    init(cellIdentifier: String,
         title: String,
         isSelected: Bool,
         checkHandler: @escaping SetInforamtionCheckHandler) {
        self.cellIdentifier = cellIdentifier
        self.title = title
        self.isSelected = isSelected
        self.checkHandler = checkHandler
    }
}

final class SetInformationCheckCell: SetInformationBaseCell {
    private lazy var titleLabel: UILabel = UILabel()
    private lazy var checkBox: UDCheckBox = UDCheckBox(boxType: .list)
    private var isChecked: Bool = true

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectedBackgroundView = BaseCellSelectView()

        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.textAlignment = .left
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(16)
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }

        self.checkBox.isHidden = true
        self.checkBox.isUserInteractionEnabled = false
        self.contentView.addSubview(self.checkBox)
        self.checkBox.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let currItem = item as? SetInformationCheckItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        self.titleLabel.text = currItem.title
        self.checkBox.isSelected = currItem.isSelected
        self.checkBox.isHidden = !currItem.isSelected
        self.isChecked = currItem.isSelected
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected, let currItem = self.item as? SetInformationCheckItem {
            currItem.checkHandler(!currItem.isSelected)
            self.checkBox.isSelected = !currItem.isSelected
            self.checkBox.isHidden = currItem.isSelected
        }
    }

    func set(isSelected: Bool) {
        self.checkBox.isSelected = isSelected
        self.checkBox.isHidden = !isSelected
    }
}
