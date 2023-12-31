//
//  SetInformationSwitchCell.swift
//  LarkContact
//
//  Created by 强淑婷 on 2020/7/15.
//

import UIKit
import Foundation
import LarkUIKit

struct SetInformationSwitchItem: SetInformationItemProtocol {
    var cellIdentifier: String
    var title: String
    var switchHandler: SetInforamtionSwitchHandler?
    var status: Bool
}

final class SetInformationSwitchCell: SetInformationBaseCell {
    /// 中间标题
    private lazy var titleLabel: UILabel = UILabel()
    /// 开关
    private lazy var loadingSwitch: LoadingSwitch = LoadingSwitch(behaviourType: .normal)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        /// 开关
        self.loadingSwitch.onTintColor = UIColor.ud.primaryContentDefault
        self.loadingSwitch.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.contentView.addSubview(self.loadingSwitch)
        self.loadingSwitch.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }
        self.loadingSwitch.valueChanged = { [weak self] (isOn) in
            if let strongSelf = self {
                guard let currItem = strongSelf.item as? SetInformationSwitchItem else {
                    assert(false, "\(strongSelf):item.Type error")
                    return
                }
                currItem.switchHandler?(isOn)
            }
        }

        /// 中间标题
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.numberOfLines = 0
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.right.lessThanOrEqualTo(self.loadingSwitch.snp.left).offset(-16)
            make.left.equalTo(16)
            make.top.equalTo(16)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let currItem = self.item as? SetInformationSwitchItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        self.titleLabel.text = currItem.title
        self.loadingSwitch.setOn(currItem.status, animated: false)
    }
}
