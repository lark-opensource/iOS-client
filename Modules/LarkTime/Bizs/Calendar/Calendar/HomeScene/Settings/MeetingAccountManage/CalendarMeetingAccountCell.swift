//
//  CalendarMeetingAccountCell.swift
//  Calendar
//
//  Created by pluto on 2022-10-19.
//

import UniverseDesignIcon
import Foundation
import CalendarFoundation
import SnapKit
import UIKit

enum CalendarMeetingAccountType {
    case add
    case zoom

    var image: UIImage {
        switch self {
        case .zoom:
            return UDIcon.getIconByKeyNoLimitSize(.zoomColorful)
        case .add:
            return UDIcon.getIconByKeyNoLimitSize(.moreAddOutlined).ud.withTintColor(UIColor.ud.colorfulBlue)
        }
    }
}

class CalendarMeetingAccountBaseCell: UITableViewCell {
    fileprivate let icon: UIImageView = UIImageView()
    fileprivate let label: UILabel = UILabel.cd.textLabel()

    fileprivate lazy var bgView: UIView = {
       let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.cornerRadius = 10
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        isUserInteractionEnabled = true
        backgroundColor = .clear

        layoutIcon(icon)

        contentView.addSubview(bgView)
        bgView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(48)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func layoutIcon(_ icon: UIView) {
        bgView.addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
    }

    fileprivate func layoutLabel(_ label: UIView, leftItem: ConstraintItem, rightItem: ConstraintItem) {
        bgView.addSubview(label)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(leftItem).offset(12)
            make.right.equalTo(rightItem).offset(-12)
        }
    }
}

final class CalendarMeetingAccountCell: CalendarMeetingAccountBaseCell {
    private let accessArrow = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.rightOutlined).renderColor(with: .n3))

    var status: ZoomAccountStatus = .inital {
        didSet {
            switch status {
            case .expired:
                expiredTipsView.isHidden = false
            default:
                expiredTipsView.isHidden = true
                break
            }
        }
    }

    var tapErrorTipsCallBack: (() -> Void)?
    private let tailingLabel: UILabel = {
        let label = UILabel.cd.textLabel(fontSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        label.text = I18n.Calendar_Settings_RemoveButton
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.numberOfLines = 1
        return label
    }()

    private let removeBtn: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.isUserInteractionEnabled = true
        return button
    }()

    private let expiredTipsView: ZoomAccountInfoView = {
       let view = ZoomAccountInfoView()
        view.status = .expired
        view.forAccountManage = true
        view.isHidden = true
        view.isUserInteractionEnabled = true
        view.sizeToFit()
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layoutRemoveBtn()
        layoutAccessArrow()
        layoutTailing(tailingLabel, rightItem: accessArrow.snp.left)
        layoutLabel(label, leftItem: icon.snp.right, rightItem: removeBtn.snp.left)
        layoutErrorTipsView()
        setupCallBack()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(model: MeetingAccountCellData, tapSelector: Selector) {
        icon.image = model.type.image.withRenderingMode(.alwaysOriginal)
        label.text = model.name
        removeBtn.addTarget(target, action: tapSelector, for: .touchUpInside)
    }

    private func layoutRemoveBtn() {
        bgView.addSubview(removeBtn)
        removeBtn.snp.makeConstraints { make in
            make.right.centerY.equalToSuperview()
        }
    }

    private func layoutAccessArrow() {
        removeBtn.addSubview(accessArrow)
        accessArrow.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.equalTo(16)
            make.height.equalTo(16)
            make.right.equalToSuperview().offset(-12)
        }
    }

    private func layoutTailing(_ tailLabel: UIView, rightItem: ConstraintItem) {
        removeBtn.addSubview(tailLabel)
        tailLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(rightItem).offset(-6)
            make.left.equalToSuperview()
        }
    }

    private func layoutErrorTipsView() {
        contentView.addSubview(expiredTipsView)
        expiredTipsView.snp.makeConstraints { make in
            make.top.equalTo(bgView.snp.bottom).offset(4)
            make.left.equalTo(bgView).offset(16)
            make.right.equalToSuperview()
        }
    }

    private func setupCallBack() {
        expiredTipsView.tapErrorTipsCallBack = { [weak self] in
            guard let self = self else { return }
            self.tapErrorTipsCallBack?()
        }
    }

    @objc
    private func tapErrorTips() {
        self.tapErrorTipsCallBack?()
    }

}
