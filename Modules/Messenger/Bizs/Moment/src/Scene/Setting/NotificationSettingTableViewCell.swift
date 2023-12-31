//
//  NotificationSettingTableViewCell.swift
//  Moment
//
//  Created by zc09v on 2021/6/11.
//

import UIKit
import Foundation
import LarkUIKit

final class NotifyMomentSettingItem: MomentSettingItem {
    var type: MomentSettingItemType = .notify
    var cellIdentifier: String = NotificationSettingTableViewCell.lu.reuseIdentifier
    var title: String
    var detail: String
    var isOn: Bool
    var handleIsOn: (Bool) -> Void
    var isEnable: Bool
    init(title: String, detail: String, isOn: Bool, isEnable: Bool, handleIsOn: @escaping (Bool) -> Void) {
        self.title = title
        self.detail = detail
        self.isOn = isOn
        self.isEnable = isEnable
        self.handleIsOn = handleIsOn
    }
}

final class NotificationSettingTableViewCell: BaseTableViewCell, MomentSettingTableViewCell {
    private var titleLabel: UILabel = UILabel()
    private var detailLabel: UILabel = UILabel()
    private var loadingSwitch: LoadingSwitch = LoadingSwitch(behaviourType: .normal)
    private(set) var settingItem: MomentSettingItem?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        /// 开关
        self.loadingSwitch.onTintColor = UIColor.ud.primaryContentDefault
        self.loadingSwitch.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.contentView.addSubview(self.loadingSwitch)
        self.loadingSwitch.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }

        self.loadingSwitch.valueChanged = { [weak self] (isOn) in
            (self?.settingItem as? NotifyMomentSettingItem)?.handleIsOn(isOn)
        }

        /// 标题
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.numberOfLines = 0
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.lessThanOrEqualTo(self.loadingSwitch.snp.left).offset(-16)
            make.top.equalTo(16)
        }

        /// 详情
        self.detailLabel.textColor = UIColor.ud.textPlaceholder
        self.detailLabel.numberOfLines = 0
        self.detailLabel.font = UIFont.systemFont(ofSize: 14)
        self.contentView.addSubview(self.detailLabel)
        self.detailLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.lessThanOrEqualTo(self.loadingSwitch.snp.left).offset(-16)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(2)
            make.bottom.equalTo(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setItem(_ item: MomentSettingItem?) {
        guard let settingItem = item as? NotifyMomentSettingItem else {
            assert(false, "item type error")
            return
        }
        self.settingItem = settingItem

        self.titleLabel.text = settingItem.title
        self.detailLabel.text = settingItem.detail
        self.loadingSwitch.setOn(settingItem.isOn, animated: false)
        self.loadingSwitch.isEnabled = settingItem.isEnable
    }
}
