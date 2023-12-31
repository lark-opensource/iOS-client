//
//  BTFieldInputView.swift
//  SKBitable
//
//  Created by yinyuan on 2022/12/21.
//

import Foundation
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignToast

enum BTFieldInputType {
    case min
    case max
}

final class BTFieldInputView: UIView, UITextFieldDelegate {
    
    var didFieldInputValueChange: ((_ fieldInputView: BTFieldInputView, _ value: String?) -> Void)?
    var didFieldInputEditBegin: ((_ fieldInputView: BTFieldInputView) -> Void)?
    var didFieldInputEditEnd: ((_ fieldInputView: BTFieldInputView) -> Void)?
    
    lazy var headLabel = UILabel().construct { it in
        it.textColor = UDColor.textTitle
        it.setContentCompressionResistancePriority(.required, for: .horizontal)
        it.font = .systemFont(ofSize: 16)
    }
    
    lazy var inputTextField = BTConditionalTextField().construct { it in
        it.textAlignment = .right
        it.font = .systemFont(ofSize: 16)
        it.textColor = UDColor.textTitle
        it.autocorrectionType = .no
        it.spellCheckingType = .no
        it.returnKeyType = .done
        it.delegate = self
        it.baseContext = self.baseContext

        it.addTarget(self, action: #selector(fieldInputDidChange), for: .editingChanged)
        it.addTarget(self, action: #selector(fieldInputDidBeginEdit), for: .editingDidBegin)
        it.addTarget(self, action: #selector(fieldInputDidEndEdit), for: .editingDidEnd)
    }
    
    let type: BTFieldInputType
    let baseContext: BaseContext?
    
    init(type: BTFieldInputType, baseContext: BaseContext?) {
        self.type = type
        self.baseContext = baseContext
        super.init(frame: .zero)
        setUpUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpUI() {
        self.backgroundColor = UDColor.bgFloat
        layer.cornerRadius = 10
        
        addSubview(headLabel)
        addSubview(inputTextField)
        
        headLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        headLabel.snp.makeConstraints { make in
            make.height.equalTo(22)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
        
        inputTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        inputTextField.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.left.equalTo(headLabel.snp.right).offset(20)
        }
    }
    
    @objc
    func fieldInputDidChange() {
        didFieldInputValueChange?(self, self.inputTextField.text)
    }

    @objc
    func fieldInputDidBeginEdit() {
        didFieldInputEditBegin?(self)
    }

    @objc
    func fieldInputDidEndEdit() {
        didFieldInputEditEnd?(self)
    }
    
    //是否在手机横屏下，用来禁用某些控件的编辑能力
    var isPhoneLandscape: Bool {
        SKDisplay.phone && UIApplication.shared.statusBarOrientation.isLandscape
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if isPhoneLandscape, let window = self.window {
            UDToast.showWarning(with: BundleI18n.SKResource.Doc_Block_NotSupportEditInLandscape, on: window)
        }
        return !isPhoneLandscape
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        inputTextField.resignFirstResponder()
        return true
    }
}
