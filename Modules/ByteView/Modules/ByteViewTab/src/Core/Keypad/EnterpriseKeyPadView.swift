//
//  EnterpriseKeyPadView.swift
//  ByteView
//
//  Created by fakegourmet on 2021/10/20.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import ByteViewCommon
import ByteViewUI

class EnterpriseKeyPadView: UIView {

    lazy var phoneNumberWrapper = UIView()
    lazy var phoneNumberLabel: EnterpriseKeyPadLabel = {
        let phoneNumberLabel = EnterpriseKeyPadLabel()
        phoneNumberLabel.labelTextDidChange = { [weak self] in
            guard let self = self else { return }
            let isHidden: Bool = ($0 == nil) || ($0?.isEmpty == true)
            self.toggleAnimatedHidden(target: self.deleteButton, isHidden)
        }
        return phoneNumberLabel
    }()

    lazy var descLabel: UILabel = {
        let descLabel = UILabel()
        descLabel.numberOfLines = 1
        return descLabel
    }()

    lazy var callButton: AnimatedBackgroundButton = {
        let callButton = AnimatedBackgroundButton(type: .custom)
        let size: CGFloat = Display.iPhoneMaxSeries ? 36 : 32
        let icon = UDIcon.getIconByKey(.callFilled, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: size, height: size))
        callButton.setImage(icon, for: .normal)
        callButton.setImage(icon, for: .disabled)
        callButton.setBackgroundColor(.ud.functionSuccessContentDefault, for: .normal)
        callButton.setBackgroundColor(.ud.functionSuccessContentPressed, for: .highlighted)
        callButton.setBackgroundColor(.ud.fillDisabled, for: .disabled)
        callButton.clipsToBounds = true
        callButton.isExclusiveTouch = true
        return callButton
    }()

    lazy var deleteButton: AnimatedBackgroundButton = {
        let deleteButton = AnimatedBackgroundButton(type: .custom)
        deleteButton.setBackgroundImage(BundleResources.ByteViewTab.EnterpriseCall.DeleteButtonBackground, for: .normal)
        deleteButton.setBackgroundImage(BundleResources.ByteViewTab.EnterpriseCall.DeleteButtonBackgroundHighlighted, for: .highlighted)
        deleteButton.setImage(UDIcon.getIconByKey(.closeBoldOutlined, iconColor: .ud.iconN1, size: CGSize(width: 18, height: 18)), for: .normal)
        deleteButton.imageEdgeInsets = .init(top: 0, left: 8, bottom: 0, right: 0)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapDelete))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self
        deleteButton.addGestureRecognizer(tapGesture)
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressDelete))
        longGesture.minimumPressDuration = 0.5
        longGesture.delegate = self
        deleteButton.addGestureRecognizer(longGesture)
        deleteButton.isExclusiveTouch = true
        deleteButton.extendEdge = .init(top: -9,
                                        left: 0,
                                        bottom: -9,
                                        right: -6)
        deleteButton.alpha = 0
        return deleteButton
    }()

    var timer: Timer = Timer()

    lazy var balanceLabel: UILabel = {
        let balanceLabel = UILabel()
        balanceLabel.numberOfLines = 0
        return balanceLabel
    }()

    lazy var phoneButtons: [EnterpriseKeyPadButton] = {
        [
            ("1", "", "1", nil),
            ("2", "ABC", "2", nil),
            ("3", "DEF", "3", nil),
            ("4", "GHI", "4", nil),
            ("5", "JKL", "5", nil),
            ("6", "MNO", "6", nil),
            ("7", "PQRS", "7", nil),
            ("8", "TUV", "8", nil),
            ("9", "WXYZ", "9", nil),
            ("*", "", "*", nil),
            ("0", "+", "0", "+"),
            ("#", "", "#", nil)
        ].map {
            let style: EnterpriseKeyPadButton.Style = Display.typeIsLike < Display.DisplayType.iPhone6 ? .tiny : (Display.iPhoneMaxSeries ? .max : .default)

            let button = EnterpriseKeyPadButton(style: style,
                                                title: $0.0, subtitle: $0.1, mainText: $0.2, subText: $0.3)
            let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(appendNumber(gesture:)))
            tapGesture.minimumPressDuration = 0.0
            tapGesture.delegate = self
            tapGesture.cancelsTouchesInView = false
            button.addGestureRecognizer(tapGesture)
            let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(appendLetter(gesture:)))
            longGesture.minimumPressDuration = 1.0
            longGesture.delegate = self
            button.addGestureRecognizer(longGesture)
            return button
        }
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            self.callButton.layer.cornerRadius = self.callButton.bounds.width / 2
        }
    }

    private func setupViews() {
        let phoneButtonView = UIView()
        addSubview(phoneNumberWrapper)
        phoneNumberWrapper.addSubview(phoneNumberLabel)
        phoneNumberWrapper.addSubview(descLabel)
        addSubview(phoneButtonView)
        addSubview(callButton)
        addSubview(deleteButton)
        addSubview(balanceLabel)

        let phoneNumberTopOffset: CGFloat
        let keyPadTopOffset: CGFloat
        let buttonWidth: CGFloat
        let horizontalSpacing: CGFloat
        let verticalSpacing: CGFloat
        let callBtnTopOffset: CGFloat
        let deleteLeftOffset: CGFloat
        let balanceTopOffset: CGFloat
        let displayType = Display.typeIsLike
        if displayType < Display.DisplayType.iPhone6 {
            phoneNumberTopOffset = 0.0
            keyPadTopOffset = 8.0
            buttonWidth = 64.0
            horizontalSpacing = 20.0
            verticalSpacing = 10.0
            callBtnTopOffset = verticalSpacing
            deleteLeftOffset = 28.0
            balanceTopOffset = 4.0
        } else if displayType < Display.DisplayType.iPhoneX {
            phoneNumberTopOffset = 4.0
            keyPadTopOffset = 18.0
            buttonWidth = 72.0
            horizontalSpacing = 32.0
            verticalSpacing = 20.0
            callBtnTopOffset = verticalSpacing
            deleteLeftOffset = 44.0
            balanceTopOffset = 14.0
        } else if Display.iPhoneMaxSeries {
            phoneNumberTopOffset = Display.typeIsLike == .iPhoneXR ? 31 : 21
            keyPadTopOffset = 79.0
            buttonWidth = 82.0
            horizontalSpacing = 32.0
            verticalSpacing = 20.0
            callBtnTopOffset = Display.typeIsLike == .iPhoneXR ? 24 : 34
            deleteLeftOffset = 44.0
            balanceTopOffset = 41.0
        } else {
            phoneNumberTopOffset = 16.0
            keyPadTopOffset = 70.0
            buttonWidth = 72.0
            horizontalSpacing = 32.0
            verticalSpacing = 20.0
            callBtnTopOffset = verticalSpacing
            deleteLeftOffset = 44.0
            balanceTopOffset = 41.0
        }
        phoneNumberWrapper.snp.makeConstraints {
            $0.top.equalToSuperview().offset(phoneNumberTopOffset)
            $0.centerX.equalToSuperview()
            $0.left.right.equalToSuperview()
        }
        phoneNumberLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.height.greaterThanOrEqualTo(44.0)
            $0.left.right.equalToSuperview().inset(48.0)
        }
        descLabel.snp.makeConstraints {
            $0.top.equalTo(phoneNumberLabel.snp.bottom).offset(3.0)
            $0.centerX.equalTo(phoneNumberLabel)
            $0.height.greaterThanOrEqualTo(22.0)
        }
        phoneButtonView.snp.makeConstraints {
            $0.top.equalTo(phoneNumberWrapper.snp.bottom)
            $0.top.greaterThanOrEqualTo(descLabel.snp.bottom).offset(keyPadTopOffset)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(3 * buttonWidth + 2 * horizontalSpacing)
            $0.height.equalTo(4 * buttonWidth + 3 * verticalSpacing)
        }

        let leftOffset: CGFloat = buttonWidth + horizontalSpacing
        let topOffset: CGFloat = buttonWidth + verticalSpacing
        phoneButtons.enumerated().forEach { [weak phoneButtonView] in
            let button = $0.element
            let idx = $0.offset
            let leftOffset = CGFloat(idx % 3) * leftOffset
            let topOffset = CGFloat(floor(Double(idx) / 3)) * topOffset
            phoneButtonView?.addSubview(button)
            button.snp.makeConstraints { make in
                make.width.height.equalTo(buttonWidth)
                make.left.equalTo(leftOffset)
                make.top.equalTo(topOffset)
            }
        }

        callButton.snp.makeConstraints {
            $0.width.height.equalTo(buttonWidth)
            $0.centerX.equalTo(phoneButtonView)
            $0.top.equalTo(phoneButtonView.snp.bottom).offset(callBtnTopOffset)
        }

        deleteButton.snp.makeConstraints {
            $0.left.equalTo(callButton.snp.right).offset(deleteLeftOffset)
            $0.centerY.equalTo(callButton)
            $0.width.equalTo(42.0)
            $0.height.equalTo(30.0)
        }

        balanceLabel.snp.makeConstraints {
            $0.top.equalTo(callButton.snp.bottom).offset(balanceTopOffset)
            $0.centerX.equalToSuperview()
            $0.left.right.equalTo(phoneButtonView)
        }
    }

    private func toggleAnimatedHidden(target: UIView, _ isHidden: Bool) {
        UIView.transition(with: target,
                          duration: isHidden ? 0.5 : 0.25,
                          options: .transitionCrossDissolve,
                          animations: {
                            target.alpha = isHidden ? 0 : 1
                          },
                          completion: nil)
    }

    @objc func appendNumber(gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let button = gesture.view as? EnterpriseKeyPadButton else { return }
        phoneNumberLabel.append(button.mainText)
    }

    @objc func appendLetter(gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let button = gesture.view as? EnterpriseKeyPadButton else { return }
        phoneNumberLabel.append(button.subText, replaceLast: true)
    }

    @objc func tapDelete() {
        phoneNumberLabel.dropLast()
    }

    @objc func longPressDelete(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            timer.invalidate()
            timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(tapDelete), userInfo: nil, repeats: true)
        }
        if gesture.state == .ended {
            timer.invalidate()
        }
    }
}

extension EnterpriseKeyPadView {
    func updatePhoneDesc(province: String?, isp: String?, countryName: String?, ipPhoneLarkUserName: String?) {
        Util.runInMainThread {
            var text = ""
            if let ipPhoneLarkUserName = ipPhoneLarkUserName, !ipPhoneLarkUserName.isEmpty {
                text = ipPhoneLarkUserName
            } else {
                if let province = province, !province.isEmpty {
                    text += province
                }
                if let isp = isp, !isp.isEmpty {
                    text += " \(isp)"
                }
                if text.isEmpty, let countryName = countryName {  //province和isp为空的情况下
                    text = countryName
                }
            }
            self.descLabel.attributedText = NSAttributedString(string: text, config: .body)
            self.toggleAnimatedHidden(target: self.descLabel, text.isEmpty)
        }
    }

    func updateBalance(date: String, balance: Int32, department: String) {
        Util.runInMainThread {
            let text: String
            let isValid: Bool = balance > 0
            let balance: String = " \(balance)".replacingOccurrences(of: "\\B(?=(\\d{3})+\\b)", with: ",", options: .regularExpression)
            if department.isEmpty {
                text = I18n.View_MV_OfficePhoneQuotaRemain_Note(balance, date)
            } else {
                text = I18n.View_MV_OfficePhoneQuotaForName_Colon(date, balance, department)
            }
            let mutableString = NSMutableAttributedString(string: text, config: .enterpriseKeyPadBalance, alignment: .center, textColor: .ud.textPlaceholder)

            let regex = try? NSRegularExpression.init(pattern: #"(?<!/|\d)(\d|,)+(?!/|\d)"#)
            if let range = regex?.rangeOfFirstMatch(in: text, options: .reportProgress, range: NSRange(location: 0, length: text.count)) {
                let balanceColor: UIColor = isValid ? .ud.textTitle : .ud.functionDangerContentDefault
                mutableString.addAttributes([.foregroundColor: balanceColor], range: range)
            }
            self.balanceLabel.attributedText = mutableString
        }
    }
}

extension EnterpriseKeyPadView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

fileprivate extension VCFontConfig {
    static let enterpriseKeyPadBalance = VCFontConfig(fontSize: 12, lineHeight: 20, fontWeight: .semibold)
}
