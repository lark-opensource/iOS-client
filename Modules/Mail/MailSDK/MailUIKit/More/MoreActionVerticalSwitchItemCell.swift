//
//  MoreActionVerticalSwitchItemCell.swift
//  MailSDK
//
//  Created by Ender on 2023/9/13.
//

import Foundation
import LarkInteraction
import UniverseDesignSwitch

class MoreActionVerticalSwitchItemCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let bottomLineView = UIView()
    private let switchButton: UDSwitch = UDSwitch()
    private var switchHandler: MailSwitchActionCallBack?

    private static let leftOffset: CGFloat = 16
    private static let topOffset: CGFloat = 13
    private static let spacing: CGFloat = 12
    private static let minLabelHeight: CGFloat = 22
    private static let titleFont = UIFont.systemFont(ofSize: 16)
    private static let switchButtonWidth: CGFloat = 48

    static func cellHeightFor(title: String, cellWidth: CGFloat) -> CGFloat {
        let titleWidth = cellWidth - 2 * MoreActionVerticalSwitchItemCell.leftOffset - MoreActionVerticalSwitchItemCell.spacing - MoreActionVerticalSwitchItemCell.switchButtonWidth
        let titleHeight = (title as NSString).boundingRect(with: CGSize(width: titleWidth, height: CGFloat.greatestFiniteMagnitude),
                                                           options: .usesLineFragmentOrigin,
                                                           attributes: [.font: MoreActionVerticalSwitchItemCell.titleFont],
                                                           context: nil).height
        let titleLabelHeight = min(ceil(MoreActionVerticalSwitchItemCell.titleFont.lineHeight * 2), ceil(titleHeight))
        return titleLabelHeight + 2 * MoreActionVerticalSwitchItemCell.topOffset
    }

    func updateBottomLine(isHidden: Bool) {
        bottomLineView.isHidden = isHidden
    }

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = UIColor.ud.bgFloat

        titleLabel.font = MoreActionVerticalSwitchItemCell.titleFont
        titleLabel.backgroundColor = .clear
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 2

        bottomLineView.backgroundColor = UIColor.ud.lineDividerDefault

        contentView.addSubview(titleLabel)
        contentView.addSubview(bottomLineView)
        contentView.addSubview(switchButton)

        switchButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(-MoreActionVerticalSwitchItemCell.leftOffset)
        }
        switchButton.valueChanged = { [weak self] value in
            guard let self = self else { return }
            self.switchHandler?(value)
        }

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(MoreActionVerticalSwitchItemCell.leftOffset)
            make.right.lessThanOrEqualTo(switchButton.snp.left).offset(-MoreActionVerticalSwitchItemCell.spacing)
            make.top.equalTo(MoreActionVerticalSwitchItemCell.topOffset)
            make.bottom.equalTo(-MoreActionVerticalSwitchItemCell.topOffset)
        }

        bottomLineView.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: PointerStyle(effect: .hover())
            )
            self.addLKInteraction(pointer)
        }
    }

    func setup(title: String, status: Bool, switchHandler: @escaping MailSwitchActionCallBack) {
        self.titleLabel.text = title
        self.switchButton.setOn(status, animated: false)
        self.switchHandler = switchHandler
        setupViews()
    }
}
