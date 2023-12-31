//
//  CalendarAccountCell.swift
//  Calendar
//
//  Created by heng zhu on 2019/4/15.
//

import UniverseDesignIcon
import Foundation
import CalendarFoundation
import SnapKit
import UIKit

protocol CalendarAccountAccessCellModel {
    var type: CalendarAccountType { get }
    var name: String { get }
    var desc: String? { get }
    /// 是否被指定为往外发送邮件的账户
    var isSelectedAsNotificaionEmail: Bool { get }
}

protocol CalendarAccountSwitchCellModel: CalendarAccountAccessCellModel {
    var isVisibility: Bool { get }
}

enum CalendarAccountType {
    case google
    case local
    case add
    case exchange

    var image: UIImage {
        switch self {
        case .google:
            return UDIcon.getIconByKeyNoLimitSize(.googleColorful)
        case .local:
            return UDIcon.getIconByKeyNoLimitSize(.phoneColorful)
        case .add:
            return UDIcon.getIconByKeyNoLimitSize(.moreAddOutlined).ud.withTintColor(UIColor.ud.colorfulBlue)
        case .exchange:
            return UDIcon.getIconByKeyNoLimitSize(.exchangeColorful)
        }
    }
}

class CalendarAccountBaseCell: UITableViewCell {
    fileprivate let icon: UIImageView = UIImageView()
    var topLine: UIView?
    var midBottomLine: UIView?
    var bottomLine: UIView?
    fileprivate let label: UILabel = UILabel.cd.textLabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        layoutIcon(icon)
        topLine = addTopBorder(inset: .zero, lineHeight: 0.5)
        midBottomLine = addCellBottomBorder()
        bottomLine = addBottomBorder(inset: .zero, lineHeight: 0.5)
        topLine?.isHidden = true
        bottomLine?.isHidden = true
        backgroundColor = UIColor.ud.bgFloat
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func layoutIcon(_ icon: UIView) {
        contentView.addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
    }

    fileprivate func layoutLabel(_ label: UIView, leftItem: ConstraintItem, rightItem: ConstraintItem) {
        contentView.addSubview(label)
        label.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(leftItem).offset(12)
            make.right.equalTo(rightItem).offset(-12)
        }
    }

    func updateBottomBorder(isHidden: Bool) {
        midBottomLine?.isHidden = isHidden
    }
}

final class CalendarAccountAddCell: CalendarAccountBaseCell {
    static let reuseIdentifier = "CalendarAccountAddCell"
    private let subLabel: UILabel = UILabel.cd.subTitleLabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 文案可配置能力
    public func configCellInfo(labelText: String ) {
        label.text = labelText
        icon.image = CalendarAccountType.add.image.withRenderingMode(.alwaysOriginal)
        layoutLabel(label, leftItem: icon.snp.right, rightItem: self.snp.right)
    }
}

final class CalendarAccountAccessCell: CalendarAccountBaseCell {
    private let accessArrow = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.rightOutlined).renderColor(with: .n3))
    private let subTitleLabel = UILabel.cd.subTitleLabel()
    private let stackView = UIStackView()

    // 认证即将过期的提示icon
    private lazy var warningIcon: UIImageView = {
        let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.warningOutlined).scaleInfoSize().ud.withTintColor(UIColor.ud.colorfulRed))
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        layoutAccessArrow(accessArrow)
        layoutWarningIcon(warningIcon)
        warningIcon.isHidden = true
        // 要显示 warningIcon，stackview 右边布局要向左偏移 16，16 是 warningIcon 的宽度
        let stackRightOffset = -16
        layoutStackView(stackView, leftItem: icon.snp.right, rightItem: accessArrow.snp.left, rightOffset: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(model: CalendarAccountAccessCellModel) {
        icon.image = model.type.image.withRenderingMode(.alwaysOriginal)
        label.text = model.name
        subTitleLabel.isHidden = true
    }

    public func update(model: CalendarAccountAccessCellModel, showAccountWarning: Bool = false) {
        update(model: model)
        warningIcon.isHidden = !showAccountWarning
        // 如果要显示 warningIcon，stackview 右边布局要向左偏移 16，16 是 warningIcon 的宽度
        if showAccountWarning {
            layoutStackView(stackView, leftItem: icon.snp.right, rightItem: accessArrow.snp.left, rightOffset: -16)
        } else {
            layoutStackView(stackView, leftItem: icon.snp.right, rightItem: accessArrow.snp.left, rightOffset: 0)
        }
    }

    private func layoutWarningIcon(_ warningIcon: UIView) {
        contentView.addSubview(warningIcon)
        warningIcon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.equalTo(16)
            make.height.equalTo(16)
            // -32=-12-16-4，-12 是右边距，16 是 accessArrow 宽度，4 是跟 accessArrow 间距
            make.right.equalToSuperview().offset(-32)
        }
    }

    private func layoutAccessArrow(_ accessArrow: UIView) {
        contentView.addSubview(accessArrow)
        accessArrow.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.equalTo(16)
            make.height.equalTo(16)
            make.right.equalToSuperview().offset(-12)
        }
    }

    func layoutStackView(_ stackView: UIStackView, leftItem: ConstraintItem, rightItem: ConstraintItem, rightOffset: Int = 0) {
        contentView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(leftItem).offset(12)
            make.right.equalTo(rightItem).offset(-12 + rightOffset)
            make.top.equalTo(contentView).offset(12)
        }
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(subTitleLabel)
    }
}

final class CalendarAccountSwitchCell: CalendarAccountBaseCell {
    private let switchView: UISwitch = UISwitch.blueSwitch()
    var onSwitch: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        layoutSwitchView(switchView)
        layoutLabel(label, leftItem: icon.snp.right, rightItem: switchView.snp.left)
        switchView.addTarget(self, action: #selector(switchViewOnChanged), for: .valueChanged)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(model: CalendarAccountSwitchCellModel) {
        icon.image = model.type.image.withRenderingMode(.alwaysOriginal)
        label.text = model.name
        switchView.isOn = model.isVisibility
    }

    @objc
    private func switchViewOnChanged() {
        onSwitch?(switchView.isOn)
    }

    private func layoutSwitchView(_ switchView: UIView) {
        contentView.addSubview(switchView)
        switchView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.equalTo(51)
            make.height.equalTo(31)
            make.right.equalToSuperview().offset(-15)
        }
    }

}
