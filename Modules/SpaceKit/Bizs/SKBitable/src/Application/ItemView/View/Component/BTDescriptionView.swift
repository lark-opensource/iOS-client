//
// Created by duanxiaochen.7 on 2021/12/5.
// Affiliated with SKBitable.
//
// Description:

import Foundation
import UIKit
import SnapKit
import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignFont


protocol BTDescriptionViewDelegate: AnyObject {
    func toggleLimitMode(to: Bool)
}

final class BTDescriptionView: UIView {

    static let maxNumberOfLines: CGFloat = 4

    private let limitButtonFont: UIFont

    weak var textViewDelegate: BTReadOnlyTextViewDelegate?

    weak var limitButtonDelegate: BTDescriptionViewDelegate?

    private lazy var descriptionTextView = BTReadOnlyTextView().construct { it in
        it.btDelegate = textViewDelegate
    }

    private var showExpandConstraint: Constraint?

    private var showFoldConstraint: Constraint?
    
    private var bgColor: UIColor

    private lazy var buttonLeadingMaskView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: limitButtonFont.figmaHeight)).construct { it in
        let layer = CAGradientLayer()
        layer.position = it.center
        layer.bounds = it.bounds
        it.layer.addSublayer(layer)
        layer.ud.setColors([
            bgColor.withAlphaComponent(0),
            bgColor.withAlphaComponent(1)
        ])
        layer.locations = [0, 1]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
    }

    private lazy var limitButton = UIButton(type: .custom).construct { it in
        it.backgroundColor = bgColor
        it.addTarget(self, action: #selector(didChangeLimitState), for: .touchUpInside)
        it.addSubview(buttonTextLabel)
        it.addSubview(buttonIndicator)
        buttonTextLabel.snp.makeConstraints { make in
            make.leading.equalTo(4)
            make.top.bottom.equalToSuperview()
        }
        buttonIndicator.snp.makeConstraints { make in
            make.leading.equalTo(buttonTextLabel.snp.trailing).offset(4)
            make.centerY.equalTo(buttonTextLabel)
            make.trailing.equalToSuperview()
            make.width.height.equalTo(16)
        }
    }

    private lazy var buttonTextLabel = UILabel().construct { it in
        it.font = limitButtonFont
        it.textColor = UDColor.primaryContentDefault
    }

    private lazy var buttonIndicator = UIImageView()

    init(limitButtonFont: UIFont,
         bgColor: UIColor = UDColor.bgBody,
         textViewDelegate: BTReadOnlyTextViewDelegate,
         limitButtonDelegate: BTDescriptionViewDelegate) {
        self.limitButtonFont = limitButtonFont
        self.bgColor = bgColor
        self.textViewDelegate = textViewDelegate
        self.limitButtonDelegate = limitButtonDelegate
        super.init(frame: .zero)
        clipsToBounds = true
        addSubview(descriptionTextView)
        descriptionTextView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }
        let lineHeight = limitButtonFont.figmaHeight
        addSubview(limitButton)
        addSubview(buttonLeadingMaskView)
        limitButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.height.equalTo(lineHeight)
            showFoldConstraint = make.top.equalTo(descriptionTextView.snp.bottom).constraint
            showFoldConstraint?.deactivate()
            showExpandConstraint = make.top.equalTo(lineHeight * (BTDescriptionView.maxNumberOfLines - 1)).constraint
        }
        buttonLeadingMaskView.snp.makeConstraints { make in
            make.trailing.equalTo(limitButton.snp.leading)
            make.top.equalTo(limitButton)
            make.width.equalTo(40)
            make.height.equalTo(lineHeight)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setDescriptionText(_ attrText: NSAttributedString, showingHeight: CGFloat) {
        descriptionTextView.attributedText = attrText

        let isLimited = descriptionTextView.intrinsicContentSize.height > showingHeight
        if isLimited {
            buttonLeadingMaskView.isHidden = false
            showFoldConstraint?.deactivate()
            showExpandConstraint?.activate()
            buttonTextLabel.text = BundleI18n.SKResource.Bitable_Common_Expand
            buttonIndicator.image = UDIcon.downBoldOutlined.ud.withTintColor(UDColor.primaryContentDefault)
        } else {
            buttonLeadingMaskView.isHidden = true
            showExpandConstraint?.deactivate()
            showFoldConstraint?.activate()
            buttonTextLabel.text = BundleI18n.SKResource.Bitable_Common_Hide
            buttonIndicator.image = UDIcon.upBoldOutlined.ud.withTintColor(UDColor.primaryContentDefault)
        }
    }

    func setLimitButtonVisible(visible: Bool) {
        limitButton.isHidden = !visible
    }

    @objc
    private func didChangeLimitState() {
        if buttonTextLabel.text == BundleI18n.SKResource.Bitable_Common_Expand {
            limitButtonDelegate?.toggleLimitMode(to: false)
        } else {
            limitButtonDelegate?.toggleLimitMode(to: true)
        }
    }
}
