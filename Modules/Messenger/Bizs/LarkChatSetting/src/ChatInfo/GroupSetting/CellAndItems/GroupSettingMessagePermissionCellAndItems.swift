//
//  GroupSettingMessagePermissionCellAndItems.swift
//  LarkChatSetting
//
//  Created by zc09v on 2022/7/11.
//

import UIKit
import Foundation

// MARK: - 编辑群信息权限 - item
struct MessagePreventLeakItem: GroupSettingItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var detail: String
    var status: Bool
    var switchHandler: ChatInfoSwitchHandler
}

// MARK: - 编辑群信息权限 - cell
final class MessagePreventLeakCell: GroupSettingCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 16, bottom: 0, right: 79))
        }

        detailLabel.numberOfLines = 0
        detailLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(titleLabel.snp.bottom).offset(4)
            maker.left.right.bottom.equalToSuperview().inset(UIEdgeInsets(top: 37, left: 16, bottom: 14, right: 79))
        }

        defaultLayoutSwitchButton()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? MessagePreventLeakItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = item.title
        detailLabel.text = item.detail
        switchButton.isOn = item.status
        layoutSeparater(item.style)
    }

    override func switchButtonStatusChange(to status: Bool) {
        guard let item = item as? MessagePreventLeakItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        item.switchHandler(switchButton, status)
    }
}

struct MessagePreventLeakSubSwitchItem: GroupSettingItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var status: Bool
    var switchHandler: ChatInfoSwitchHandler
}

final class MessagePreventLeakSubSwitchCell: GroupSettingCell {
    lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.iconDisabled
        view.layer.cornerRadius = 0.65
        view.layer.masksToBounds = true
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        contentView.addSubview(titleLabel)
        titleLabel.snp.remakeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
                .inset(UIEdgeInsets(top: 15, left: 36, bottom: 0, right: 75))
            maker.bottom.equalToSuperview().offset(-14)
        }

        contentView.addSubview(lineView)
        lineView.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(self.titleLabel)
            maker.left.equalToSuperview().offset(18)
            maker.width.equalTo(12)
            maker.height.equalTo(1.3)
        }

        contentView.addSubview(switchButton)

        defaultLayoutSwitchButton()

        arrow.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? MessagePreventLeakSubSwitchItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = item.title
        switchButton.isOn = item.status
        layoutSeparater(item.style)
    }

    override func switchButtonStatusChange(to status: Bool) {
        guard let item = item as? MessagePreventLeakSubSwitchItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        item.switchHandler(switchButton, status)
    }
}

struct MessagePreventLeakBurnTimeItem: GroupSettingItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var detailDescription: String
    var status: String
    var disable: Bool
    var tapHandler: (() -> Void)?
}

final class MessagePreventLeakBurnTimeCell: GroupSettingCell {
    private var statusLabel = UILabel()
    lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.iconDisabled
        view.layer.cornerRadius = 0.65
        view.layer.masksToBounds = true
        return view
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(statusLabel)

        defaultLayoutArrow()
        statusLabel.textColor = UIColor.ud.textPlaceholder
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        statusLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-32)
            make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(5)
        }

        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.numberOfLines = 0
        titleLabel.snp.remakeConstraints { (maker) in
            maker.top.left.equalToSuperview()
                .inset(UIEdgeInsets(top: 15, left: 36, bottom: 0, right: 0))
            maker.right.lessThanOrEqualToSuperview().offset(-75)
        }

        detailLabel.numberOfLines = 0
        detailLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(titleLabel.snp.bottom).offset(4)
            maker.left.right.bottom.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 36, bottom: 14, right: 75))
        }

        contentView.addSubview(lineView)
        lineView.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(self.titleLabel)
            maker.left.equalToSuperview().offset(18)
            maker.width.equalTo(12)
            maker.height.equalTo(1.3)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? MessagePreventLeakBurnTimeItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = item.title
        statusLabel.text = item.status
        layoutSeparater(item.style)
        detailLabel.text = item.detailDescription
        if item.disable {
            titleLabel.textColor = UIColor.ud.textDisabled
        } else {
            titleLabel.textColor = UIColor.ud.textTitle
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let item = item as? MessagePreventLeakBurnTimeItem {
            item.tapHandler?()
        }
        super.setSelected(selected, animated: animated)
    }
}

struct MessagePreventLeakWhiteListItem: GroupSettingItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var status: String
    var tapHandler: (() -> Void)?
}

final class MessagePreventLeakWhiteListCell: GroupSettingCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        defaultLayoutArrow()
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.numberOfLines = 0
        titleLabel.snp.remakeConstraints { (maker) in
            maker.top.left.equalToSuperview()
                .inset(UIEdgeInsets(top: 15, left: 16, bottom: 0, right: 0))
            maker.right.lessThanOrEqualToSuperview().offset(-75)
        }

        detailLabel.numberOfLines = 0
        detailLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(titleLabel.snp.bottom).offset(4)
            maker.left.right.bottom.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 12, right: 75))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? MessagePreventLeakWhiteListItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = item.title
        detailLabel.text = item.status
        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let item = item as? MessagePreventLeakWhiteListItem {
            item.tapHandler?()
        }
        super.setSelected(selected, animated: animated)
    }
}
