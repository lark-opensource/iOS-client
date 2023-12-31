//
//  RedPacketHistoryTableHeaderView.swift
//  LarkFinance
//
//  Created by SuPeng on 12/21/18.
//

import Foundation
import UIKit
import LarkCore
import LarkUIKit
import DateToolsSwift
import LarkBizAvatar

protocol RedPacketHistoryTableHeaderViewDelegate: AnyObject {
    func headerView(_ headerView: RedPacketHistoryTableHeaderView, didTapped year: Int)
}

final class RedPacketHistoryTableHeaderView: UIView {

    weak var delegate: RedPacketHistoryTableHeaderViewDelegate?
    private var currentYear: Int = Date().year

    private let yearLabel = UILabel()
    private let avatarImageView = BizAvatar()
    private let avatarSize: CGFloat = 64
    private let descriptionLabel = UILabel()
    private let stackView = UIStackView()
    private let moneyLabel = UILabel()
    private let unitLabel = UILabel()

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBase

        let yearSelectView = UIView()
        addSubview(yearSelectView)
        yearSelectView.lu.addTapGestureRecognizer(action: #selector(yearDidTapped), target: self)
        yearSelectView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        let imageView = UIImageView(image: Resources.red_patcket_year.ud.withTintColor(UIColor.ud.iconN2))
        yearSelectView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.centerY.trailing.equalToSuperview()
        }

        yearSelectView.addSubview(yearLabel)
        yearLabel.text = String(format: BundleI18n.LarkFinance.Lark_Legacy_HongbaoHistoryYear, currentYear)
        yearLabel.textColor = UIColor.ud.N900
        yearLabel.snp.makeConstraints { (make) in
            make.top.left.bottom.equalToSuperview()
            make.right.equalTo(imageView.snp.left).offset(-4)
        }

        addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: avatarSize, height: avatarSize))
            make.top.equalToSuperview().offset(32)
        }

        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { (make) in
            make.top.equalTo(avatarImageView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }

        stackView.axis = .horizontal
        stackView.alignment = .lastBaseline
        addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(16)
        }

        stackView.addArrangedSubview(moneyLabel)
        moneyLabel.snp.makeConstraints {
            $0.centerX.equalTo(self.snp.centerX) // 设计要求金额和页面居中
        }
        moneyLabel.font = UIFont(name: "DINAlternate-Bold", size: 48) ?? UIFont.systemFont(ofSize: 48)
        moneyLabel.textColor = redPacketYellow

        stackView.addArrangedSubview(unitLabel)
        unitLabel.font = UIFont.systemFont(ofSize: 14)
        unitLabel.textColor = redPacketYellow
        unitLabel.text = BundleI18n.LarkFinance.Lark_Legacy_SendHongbaoMoneyUnit
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(entityId: String?, avatarKey: String?, descriptionText: String?, sumOfMoney: Int?) {
        avatarImageView.setAvatarByIdentifier(entityId ?? "", avatarKey: avatarKey ?? "", avatarViewParams: .init(sizeType: .size(avatarSize)))
        moneyLabel.text = sumOfMoney.flatMap { String(format: "%.2f", Float($0) / 100.0) }

        if
            let descriptionText = descriptionText,
            let regex = try? NSRegularExpression(pattern: "[0-9]+", options: []) {

            let attributedText = NSMutableAttributedString(string: descriptionText)
            attributedText.addAttribute(.foregroundColor,
                                        value: UIColor.ud.N600,
                                        range: NSRange(location: 0, length: descriptionText.count))
            let range = NSRange(location: 0, length: descriptionText.count)
            regex
                .matches(in: descriptionText, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: range)
                .forEach { (result) in
                    attributedText.addAttribute(.foregroundColor,
                                                value: redPacketYellow,
                                                range: result.range)
                }
            descriptionLabel.attributedText = attributedText
        } else {
            descriptionLabel.attributedText = nil
        }

        unitLabel.isHidden = (sumOfMoney == nil)
    }

    func set(year: Int) {
        currentYear = year
        yearLabel.text = String(format: BundleI18n.LarkFinance.Lark_Legacy_HongbaoHistoryYear, currentYear)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        layoutIfNeeded()
        return CGSize(width: size.width, height: stackView.frame.bottom + 32)
    }

    @objc
    private func yearDidTapped() {
        delegate?.headerView(self, didTapped: currentYear)
    }
}
