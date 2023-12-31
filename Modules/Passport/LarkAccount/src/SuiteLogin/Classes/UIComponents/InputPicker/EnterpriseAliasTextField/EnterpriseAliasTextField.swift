//
//  EnterpiseAliasTextField.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2020/2/27.
//

import LarkReleaseConfig
import UIKit
import UniverseDesignIcon

extension EnterpriseAliasTextField {
    public var placeHolder: String? {
        set { textFieldView.placeholder = newValue }
        get { textFieldView.placeholder }
    }
    public var textFieldFont: UIFont? {
         get { textFieldView.font }
         set { textFieldView.font = newValue }
     }
    public var returnKeyType: UIReturnKeyType {
        get { textFieldView.returnKeyType }
        set { textFieldView.returnKeyType = newValue }
    }
    public var selectOption: String? {
        get { suffixTextField.text }
        set { suffixTextField.text = newValue }
    }
}

protocol EnterpriseAliasTextFieldDelegate: AnyObject {
    func enterpriseAliasTextField(_ textField: EnterpriseAliasTextField, didTap suffixSelectButton: UIButton)
}

class EnterpriseAliasTextField: UIView, UITextFieldDelegate {
    
    weak var delegate: EnterpriseAliasTextFieldDelegate?

    var prefixText: String? {
        guard let text = textFieldView.text else {
            return nil
        }
        return SuiteLoginUtil.removeWhiteSpaceAndNewLines(text)
    }

    var suffixText: String? {
        guard let text = suffixTextField.text else {
            return nil
        }
        return SuiteLoginUtil.removeWhiteSpaceAndNewLines(text)
    }

    var currentText: String? {
        guard var text = textFieldView.text else {
            return nil
        }
        text += suffixTextField.text ?? ""
        return SuiteLoginUtil.removeWhiteSpaceAndNewLines(text)
    }

    var returnBtnClicked: ((EnterpriseAliasTextField) -> Void)?

    lazy var textFieldView: UITextField = {
        let textView = AllowPasteTextField()
        textView.contentVerticalAlignment = .center
        textView.tintColor = UIColor.ud.primaryContentDefault
        textView.clearButtonMode = .whileEditing
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.delegate = self
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.addTarget(
            self,
            action: #selector(textFieldEditingChanged),
            for: .editingChanged
        )
        textView.keyboardType = .asciiCapable
        return textView
    }()

    lazy var suffixTextField: UITextField = {
        let tf = AllowPasteTextField()
        let size: CGFloat = ReleaseConfig.isLark ? 14 : 17
        tf.font = .systemFont(ofSize: size, weight: .regular)
        tf.textColor = UIColor.ud.textTitle
        tf.tintColor = UIColor.ud.primaryContentDefault
        tf.delegate = self
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.keyboardType = .asciiCapable
        tf.setContentHuggingPriority(.required, for: .horizontal)
        tf.setContentCompressionResistancePriority(.required, for: .horizontal)
        tf.returnKeyType = .done
        tf.textAlignment = .right
        return tf
    }()
    
    lazy var suffixSelectButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(BundleResources.UDIconResources.downBoldOutlined.ud.withTintColor(UIColor.ud.iconN3), for: .normal)
        return button
    }()
    
    init() {
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        addSubview(borderView)
        addSubview(textFieldView)
        addSubview(suffixTextField)
        
        borderView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 5.19 开始，Lark SSO 登录增加域名后缀选择，飞书不变
        if ReleaseConfig.isLark {
            let separatorView = UIView()
            separatorView.backgroundColor = UIColor.ud.N400
            addSubview(separatorView)
            separatorView.snp.makeConstraints { make in
                make.width.equalTo(1)
                make.height.equalTo(28)
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-160)
            }
            textFieldView.snp.makeConstraints { (make) in
                make.left.equalToSuperview().inset(Layout.insetSpace)
                make.right.equalTo(separatorView.snp.left).offset(-Layout.insetSpace)
                make.centerY.equalToSuperview()
                make.height.equalTo(24)
            }
            suffixTextField.snp.makeConstraints { (make) in
                make.right.equalToSuperview().inset(36)
                make.centerY.equalToSuperview()
                make.left.equalTo(separatorView.snp.right).offset(Layout.insetSpace)
            }
            
            suffixSelectButton.addTarget(self, action: #selector(onSuffixSelectButtonTapped(_:)), for: .touchUpInside)
            addSubview(suffixSelectButton)
            suffixSelectButton.snp.makeConstraints { make in
                make.width.height.equalTo(34)
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-1)
            }
        } else {
            textFieldView.snp.makeConstraints { (make) in
                make.left.equalToSuperview().inset(Layout.insetSpace)
                make.right.equalTo(suffixTextField.snp.left).offset(-Layout.internalSpace)
                make.centerY.equalToSuperview()
                make.width.greaterThanOrEqualTo(self.snp.width).multipliedBy(0.5).offset(-Layout.insetSpace / 2)
                make.height.equalTo(24)
            }
            
            suffixTextField.snp.makeConstraints { (make) in
                make.right.equalToSuperview().inset(Layout.insetSpace)
                make.centerY.equalToSuperview()
                make.width.greaterThanOrEqualTo(Layout.selectOptionLabelMinWidth)
            }
        }
        
    }

    override func becomeFirstResponder() -> Bool {
        return textFieldView.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        return textFieldView.resignFirstResponder()
    }

    @objc
    func textFieldEditingChanged(_ textView: UITextField) {

    }
    
    @objc
    private func onSuffixSelectButtonTapped(_ sender: UIButton) {
        updateSuffixSelectButton(true)
        delegate?.enterpriseAliasTextField(self, didTap: sender)
    }
    
    func updateSuffixSelectButton(_ isSelected: Bool) {
        UIView.animate(withDuration: 0.25, animations: {
            if isSelected {
                self.suffixSelectButton.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            } else {
                self.suffixSelectButton.transform = .identity
            }
        })
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        // 处理两个 textField 切换focus，边框高亮状态保持不变
        NSObject.cancelPreviousPerformRequests(
            withTarget: borderView,
            selector: #selector(V3BorderView.cancelHighlight),
            object: nil
        )
        borderView.update(highlight: true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        // 处理两个 textField 切换focus，边框高亮状态保持不变
        borderView.perform(#selector(V3BorderView.cancelHighlight), with: nil, afterDelay: 0.01)
        if !ReleaseConfig.isLark {
            // 保证重新布局，使textFieldView伸展为最大宽度
            suffixTextField.invalidateIntrinsicContentSize()
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        returnBtnClicked?(self)
        return true
    }

    // MARK: border
    lazy var borderView: V3BorderView = {
        return V3BorderView()
    }()

}

extension EnterpriseAliasTextField {
    struct Layout {
        static let internalSpace: CGFloat = 6.0
        static let insetSpace: CGFloat = 12.0
        static let textFieldViewMinWidth: CGFloat = 120
        static let selectOptionLabelMinWidth: CGFloat = 60
    }
}
