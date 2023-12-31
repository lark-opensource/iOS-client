//
//  AppLockSettingSquareNumberPadView.swift
//  LarkEMM
//
//  Created by chenjinglin on 2023/11/3.
//

import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import UniverseDesignColor
import LarkContainer
import EENavigator
import LarkActionSheet
import FigmaKit
import UIKit
import UniverseDesignFont
import UniverseDesignButton

final class AppLockSettingSquareNumberPadView: UIView {
    var action: AppLockSettingNumberPadAction?

    // 字符：button
    private var buttonsDict: [String: AppLockSettingSquareNumberButton] = [:]
    private var deleteButton: AppLockSettingSquareNumberButton?
    let rowCount = 4
    let columnCount = 3

    private lazy var stackViewContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = CGFloat(6)
        return stackView
    }()
    
    // MARK: Overrides
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: Internal
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
    func handlePressCancelled(key: UIKey) -> Bool {
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
    // MARK: Private
    private func setup() {
        addSubview(stackViewContainer)
        stackViewContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        drawNumberPadView()
    }

    private func drawNumberPadView() {
        clearStackViewContainer()
        for r in 0 ..< rowCount {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.alignment = .fill
            stackView.distribution = .fillEqually
            stackView.spacing = CGFloat(6)
            for c in 0 ..< columnCount {
                let index = r * 3 + c
                let numBtn = createNumberButton(index: index)
                stackView.addArrangedSubview(numBtn)
            }
            stackViewContainer.addArrangedSubview(stackView)
        }
    }
    
    private func clearStackViewContainer() {
        stackViewContainer.arrangedSubviews.forEach { (view) in
            if let stackView = view as? UIStackView {
                stackView.arrangedSubviews.forEach { (button) in
                    stackView.removeArrangedSubview(button)
                    button.removeFromSuperview()
                }
                stackViewContainer.removeArrangedSubview(stackView)
                stackView.removeFromSuperview()
            }
        }
        buttonsDict = [:]
        deleteButton = nil
    }
    
    private func createNumberButton(index: Int) -> AppLockSettingSquareNumberButton {
        let numBtn = AppLockSettingSquareNumberButton()
        numBtn.index = index
        numBtn.addTarget(self, action: #selector(clickNumberAction), for: .touchUpInside)
        if index < 9 {
            numBtn.setTitle("\(index + 1)", for: .normal)
            buttonsDict["\(index + 1)"] = numBtn
        }
        if index == 9 {
            numBtn.setTitle("", for: .normal)
            numBtn.isEnabled = false
            numBtn.backgroundColor = .clear
        }
        if index == 10 {
            numBtn.setTitle("0", for: .normal)
            buttonsDict["0"] = numBtn
        }
        if index == 11 {
            numBtn.setImage(BundleResources.LarkEMM.number_pad_del_icon_with_theme, for: .normal)
            deleteButton = numBtn
            numBtn.backgroundColor = .clear
            numBtn.normalBackgroundColor = .clear
            numBtn.highLightedBackgroundColor = .clear
        }
        return numBtn
    }

    @objc
    private func clickNumberAction(sender: AppLockSettingSquareNumberButton) {
        action?(sender.currentTitle)
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

final class AppLockSettingSquareNumberButton: UIButton {
    var index = 0
    var normalBackgroundColor = UIColor.ud.N00.withAlphaComponent(0.5) & UIColor.ud.N400.alwaysDark
    var highLightedBackgroundColor = UIColor.ud.N00.withAlphaComponent(0.05) & UIColor.ud.N600.alwaysDark

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = highLightedBackgroundColor
            } else {
                backgroundColor = normalBackgroundColor
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    private func setUp() {
        titleLabel?.font = UDFont.title1
        setTitleColor(UIColor.ud.textTitle & UIColor.ud.N00.alwaysLight, for: .normal)
        backgroundColor = normalBackgroundColor
        layer.cornerRadius = 5
        layer.masksToBounds = true
    }
}
