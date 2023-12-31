//
//  BTFormSubmitCell.swift
//  SKBitable
//
//  Created by zhouyuan on 2021/8/4.
//

import Foundation
import SKResource
import UniverseDesignIcon
import UniverseDesignColor
import SKUIKit

final class BTFormSubmitCell: UICollectionViewCell {

    weak var delegate: BTFieldDelegate?

    private lazy var submitBtn = UIButton(type: .system).construct { (it) in
        it.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        it.layer.masksToBounds = true
        it.layer.cornerRadius = 8
        it.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        it.setTitle(BundleI18n.SKResource.Bitable_Form_Submit, for: .normal)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(submitBtn)
        submitBtn.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(BTFieldLayout.Const.containerLeftRightMargin)
            make.height.equalTo(48)
            make.top.equalToSuperview().offset(48)
        }
        submitBtn.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        let footerView = getFooterView()
        contentView.addSubview(footerView)
        footerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(20)
            make.top.equalTo(submitBtn.snp.bottom).offset(50)
        }
    }

    @objc
    private func tapped() {
        delegate?.didTapSubmit()
    }

    func setupData(canSubmit: Bool) {
        if canSubmit {
            submitBtn.backgroundColor = UDColor.primaryContentDefault
            submitBtn.isEnabled = true
        } else {
            submitBtn.backgroundColor = UDColor.fillDisabled
            submitBtn.isEnabled = false
        }
    }

    private func getFooterView() -> UIView {
        let wrapper = UIView()
        let iconView = UIImageView(image: UDIcon.fileRoundBitableColorful)
        let textLabel = UILabel()
        let linkText = BundleI18n.SKResource.Bitable_Common_BitableName()
        let content = BundleI18n.SKResource.Bitable_Form_SupportedByBitable(linkText)
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UDColor.textPlaceholder,
                                                         .font: UIFont.systemFont(ofSize: 12, weight: .regular)]
        let attributedString = NSMutableAttributedString(string: content, attributes: attributes)

        let contractRange = (content as NSString).range(of: linkText)
        attributedString.addAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .medium)],
                                       range: contractRange)
        textLabel.attributedText = attributedString

        let centerLayoutGuide = UILayoutGuide()
        wrapper.addLayoutGuide(centerLayoutGuide)
        centerLayoutGuide.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        wrapper.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
            make.left.centerY.equalTo(centerLayoutGuide)
        }
        wrapper.addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.right.centerY.equalTo(centerLayoutGuide)
            make.left.equalTo(iconView.snp.right).offset(6)
        }
        let leftLine = UIView()
        leftLine.backgroundColor = UDColor.lineDividerDefault
        let rightLine = UIView()
        rightLine.backgroundColor = UDColor.lineDividerDefault
        wrapper.addSubview(leftLine)
        wrapper.addSubview(rightLine)
        leftLine.snp.makeConstraints { make in
            make.height.equalTo(1.0 / SKDisplay.scale)
            make.left.equalToSuperview().offset(38)
            make.right.equalTo(centerLayoutGuide.snp.left).offset(-20)
            make.centerY.equalToSuperview()
        }

        rightLine.snp.makeConstraints { make in
            make.height.equalTo(1.0 / SKDisplay.scale)
            make.right.equalToSuperview().offset(-38)
            make.left.equalTo(centerLayoutGuide.snp.right).offset(20)
            make.centerY.equalToSuperview()
        }

        return wrapper
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
