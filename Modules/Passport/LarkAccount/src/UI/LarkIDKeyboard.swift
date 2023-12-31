//
//  LarkIDKeyboard.swift
//  IDKeyboard
//
//  Created by Nix Wang on 2021/12/21.
//

import UIKit
import UniverseDesignFont
import UniverseDesignColor

private extension UIColor {
    
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traitsCollection) -> UIColor in
                if traitsCollection.userInterfaceStyle == .dark {
                    return dark
                } else {
                    return light
                }
            }
        } else {
            return light
        }
    }
}

class IDKeyboardButton: UIButton {
    fileprivate enum IDButtonType {
        case digit(Int)
        case x
        case del
    }
    
    fileprivate var idButtonType: IDButtonType = .digit(0) {
        didSet {
            switch idButtonType {
            case .digit(let number):
                setTitle("\(number)", for: .normal)
            case .x:
                setTitle("X", for: .normal)
            case .del:
                setTitle("⌫", for: .normal)
            }
            
            updateBackgroundColor()
        }
    }
    
    private var buttonBackgroundColor: UIColor {
        return UIColor.dynamic(light: .white, dark: UDColor.rgb(0x6F6F6F))
    }
    
    private var buttonHighlightedBackgroundColor: UIColor {
        return UIColor.dynamic(light: UDColor.rgb(0xC0C2C9), dark: UDColor.rgb(0x4B4B4B))
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
        layer.cornerRadius = 5
        backgroundColor = buttonBackgroundColor
        titleLabel?.font = UIFont.systemFont(ofSize: 25)
        setTitleColor(UIColor.ud.textTitle, for: .normal)
        accessibilityTraits = [.keyboardKey]
    }

    override public var isHighlighted: Bool {
        didSet {
            updateBackgroundColor()
        }
    }
    
    private func updateBackgroundColor() {
        switch idButtonType {
        case .digit(_):
            backgroundColor = isHighlighted ? buttonHighlightedBackgroundColor : buttonBackgroundColor
        case .x, .del:
            backgroundColor = .clear
        }
    }
}

class LarkIDKeyboard: UIInputView {
    weak var target: (UIKeyInput & UITextInput)?
    let gap: CGFloat = 6.0
    let buttonHeight: CGFloat = 46.0
    
    lazy var numericButtons: [IDKeyboardButton] = (0...9).map {
        let button = IDKeyboardButton()
        button.idButtonType = .digit($0)
        button.addTarget(self, action: #selector(didTapIDKeyboardButton(_:)), for: .touchUpInside)
        button.snp.makeConstraints { make in
            make.height.equalTo(self.buttonHeight)
        }
        return button
    }
    
    lazy var deleteButton: UIButton = {
        let button = IDKeyboardButton()
        button.idButtonType = .del
        button.addTarget(self, action: #selector(didTapDeleteButton(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var xButton: UIButton = {
        let button = IDKeyboardButton()
        button.idButtonType = .x
        button.addTarget(self, action: #selector(didTapXButton(_:)), for: .touchUpInside)
        return button
    }()
    
    init(target: UIKeyInput & UITextInput) {
        self.target = target
        super.init(frame: .zero, inputViewStyle: .default)
        self.backgroundColor = UIColor.dynamic(light: UDColor.rgb(0xD5D7DD), dark: UDColor.rgb(0x323232))
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK: - Actions

private extension LarkIDKeyboard {
    @objc func didTapIDKeyboardButton(_ sender: IDKeyboardButton) {
        if case .digit(let number) = sender.idButtonType {
            insertText("\(number)")
        }
    }
    
    @objc func didTapXButton(_ sender: IDKeyboardButton) {
        insertText("X")
    }
    
    @objc func didTapDeleteButton(_ sender: IDKeyboardButton) {
        target?.deleteBackward()
    }
}

// MARK: - Private initial configuration methods

private extension LarkIDKeyboard {
    func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        allowsSelfSizing = true
        addButtons()
    }
    
    var keyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                .first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        }
    }
    
    var bottomInset: CGFloat {
        var bottomInset = keyWindow?.safeAreaInsets.bottom ?? 0
        if bottomInset > 0 {
            bottomInset += 20
        }
        return bottomInset
    }
    
    func addButtons() {
        let stackView = createStackView(axis: .vertical)
        stackView.spacing = gap
        addSubview(stackView)
                
        stackView.snp.makeConstraints { make in
            make.top.left.equalTo(gap)
            make.right.equalToSuperview().inset(gap)
            make.bottom.equalToSuperview().inset(gap + bottomInset)
        }
        
        for row in 0 ..< 3 {
            let subStackView = createStackView(axis: .horizontal)
            stackView.addArrangedSubview(subStackView)
            
            for column in 0 ..< 3 {
                subStackView.addArrangedSubview(numericButtons[row * 3 + column + 1])
            }
        }
        
        let subStackView = createStackView(axis: .horizontal)
        stackView.addArrangedSubview(subStackView)
        
        subStackView.addArrangedSubview(xButton)
        subStackView.addArrangedSubview(numericButtons[0])
        subStackView.addArrangedSubview(deleteButton)
    }
    
    func createStackView(axis: NSLayoutConstraint.Axis) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = axis
        stackView.spacing = gap
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        return stackView
    }
    
    func insertText(_ string: String) {
        guard let range = target?.selectedRange else { return }
        
        if let textField = target as? UITextField, textField.delegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string) == false {
            return
        }
        
        if let textView = target as? UITextView, textView.delegate?.textView?(textView, shouldChangeTextIn: range, replacementText: string) == false {
            return
        }
        
        target?.insertText(string)
    }
}

// MARK: - UITextInput extension

extension UITextInput {
    var selectedRange: NSRange? {
        guard let textRange = selectedTextRange else { return nil }
        
        let location = offset(from: beginningOfDocument, to: textRange.start)
        let length = offset(from: textRange.start, to: textRange.end)
        return NSRange(location: location, length: length)
    }
}
