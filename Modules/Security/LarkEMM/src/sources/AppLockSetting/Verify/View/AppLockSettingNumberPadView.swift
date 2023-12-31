//
//  AppLockSettingNumberPadView.swift
//  LarkMine
//
//  Created by thinkerlj on 2021/12/30.
//

import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import LarkContainer
import EENavigator
import LarkActionSheet
import FigmaKit
import UIKit

typealias AppLockSettingNumberPadAction = (_ text: String?) -> Void

final class AppLockSettingNumberPadView: UIView {
    var focusIndex = 0 {
        didSet { updateFocus() }
    }

    var action: AppLockSettingNumberPadAction?

    // 字符：button
    private var buttonsDict: [String: AppLockSettingNumberButton] = [:]
    private var deleteButton: AppLockSettingNumberButton?

    private lazy var stackViewContainer: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .fill
        s.distribution = .fillEqually
        s.spacing = CGFloat(0)
        return s
    }()

    private var nodes: [AppLockSettingPINCodeVerifyNode] {
        return stackViewContainer.arrangedSubviews.compactMap({ $0 as? AppLockSettingPINCodeVerifyNode })
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addSubview(stackViewContainer)
        stackViewContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        redraw()
    }

    private func redraw() {
        stackViewContainer.arrangedSubviews.forEach { (v) in
            if let s = v as? UIStackView {
                s.arrangedSubviews.forEach { (b) in
                    s.removeArrangedSubview(b)
                    b.removeFromSuperview()
                }
                stackViewContainer.removeArrangedSubview(s)
                s.removeFromSuperview()
            }
        }
        buttonsDict = [:]
        deleteButton = nil
        for v in 0 ..< 4 {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.alignment = .fill
            stackView.distribution = .fillEqually
            stackView.spacing = CGFloat(28)
            for h in 0 ..< 3 {
                let index = v * 3 + h
                let numBtn = AppLockSettingNumberButton()
                numBtn.index = index
                numBtn.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .thin)
                numBtn.setTitleColor(UIColor.ud.rgb(0xD5F6F2), for: .normal)
                numBtn.addTarget(self, action: #selector(clickNumberAction), for: .touchUpInside)
                if index < 9 {
                    numBtn.setTitle("\(index + 1)", for: .normal)
                    buttonsDict["\(index + 1)"] = numBtn
                }
                if index == 9 {
                    numBtn.setTitle("", for: .normal)
                    numBtn.isEnabled = false
                }
                if index == 10 {
                    numBtn.setTitle("0", for: .normal)
                    buttonsDict["0"] = numBtn
                }
                if index == 11 {
                    numBtn.setImage(BundleResources.LarkEMM.number_pad_del_icon, for: .normal)
                    deleteButton = numBtn
                }
                stackView.addArrangedSubview(numBtn)
                numBtn.snp.makeConstraints { make in
                    make.height.equalTo(80)
                    make.width.equalTo(80)
                }
            }
            stackViewContainer.addArrangedSubview(stackView)
        }
        layoutIfNeeded()
    }

    private func updateFocus() {
        nodes.enumerated().forEach { (i, node) in
            node.active = i == focusIndex
        }
    }

    @objc
    private func clickNumberAction(sender: AppLockSettingNumberButton) {
        action?(sender.currentTitle)
    }

    @available(iOS 13.4, *)
    func handlePressBegan(key: UIKey) -> Bool {
        if !key.modifierFlags.isEmpty {
            return false
        }

        if key.keyCode == .keyboardDeleteOrBackspace {
            // 删除
            self.deleteButton?.isHighlighted = true
            return true
        }

        if key.keyCode.rawValue >= UIKeyboardHIDUsage.keyboard1.rawValue && key.keyCode.rawValue <= UIKeyboardHIDUsage.keyboard0.rawValue {
            // 输入数字
            let number = self.number(for: key)
            self.highlight(for: number, isHighlighted: true)
        }
        return false
    }

    @available(iOS 13.4, *)
    func handlePressesEnded(key: UIKey) -> Bool {
        if !key.modifierFlags.isEmpty {
            return false
        }

        if key.keyCode == .keyboardDeleteOrBackspace {
            // 删除
            self.action?(nil)
            self.deleteButton?.isHighlighted = false
            return true
        }

        if key.keyCode.rawValue >= UIKeyboardHIDUsage.keyboard1.rawValue && key.keyCode.rawValue <= UIKeyboardHIDUsage.keyboard0.rawValue {
            // 输入密码
            let number = self.number(for: key)
            self.highlight(for: number, isHighlighted: false)
            self.action?(number)
            return true
        }

        return false
    }

    @available(iOS 13.4, *)
    func handlePressCancled(key: UIKey) -> Bool {
        if !key.modifierFlags.isEmpty {
            return false
        }

        if key.keyCode == .keyboardDeleteOrBackspace {
            // 删除
            self.deleteButton?.isHighlighted = false
            return true
        }

        if key.keyCode.rawValue >= UIKeyboardHIDUsage.keyboard1.rawValue && key.keyCode.rawValue <= UIKeyboardHIDUsage.keyboard0.rawValue {
            // 输入密码
            let number = self.number(for: key)
            self.highlight(for: number, isHighlighted: false)
            return true
        }

        return false
    }

    @available(iOS 13.4, *)
    private func number(for key: UIKey) -> String {
        var number = ""
        if key.keyCode.rawValue == UIKeyboardHIDUsage.keyboard0.rawValue {
            number = "0"
        } else {
            number = "\((key.keyCode.rawValue - UIKeyboardHIDUsage.keyboard1.rawValue) + 1)"
        }
        return number
    }

    private func highlight(for number: String, isHighlighted: Bool) {
        guard let button = buttonsDict[number] else {
            return
        }
        button.isHighlighted = isHighlighted
    }
}

final class AppLockSettingNumberButton: UIButton {
    var index = 0
    private lazy var selectedView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        v.isUserInteractionEnabled = true
        v.alpha = 0.2
        v.layer.cornerRadius = self.frame.height / 2
        addSubview(v)
        v.snp.makeConstraints { make in
            make.width.height.equalTo(self.snp.height)
            make.center.equalToSuperview()
        }
        return v
    }()

    override var isHighlighted: Bool {
        didSet {
            self.selectedView.isHidden = !isHighlighted
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
}
