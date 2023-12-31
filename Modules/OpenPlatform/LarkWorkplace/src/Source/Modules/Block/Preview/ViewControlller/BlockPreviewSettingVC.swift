//
//  BlockPreviewSettingVC.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/10/15.
//

import UIKit
import UniverseDesignFont
import UniverseDesignToast

struct BlockPreviewSetting: Codable {
    var previewHeight: String?

    var isValid: Bool {
        if !checkPreviewHeight() {
            return false
        }
        return true
    }

    func checkPreviewHeight() -> Bool {
        guard let str = previewHeight, !str.isEmpty else {
            // nil, "",
            return true
        }
        if str == TMPLBlockStyles.autoHightValue {
            // "auto"
            return true
        }
        if let val = Float(str), val > 0 {
            // > 0 的 number
            return true
        }
        return false
    }
}

final class BlockPreviewSettingVC: UIViewController {
    var onSettingComplete: ((BlockPreviewSetting?) -> Void)?

    private var setting: BlockPreviewSetting

    private lazy var titleLabel: UILabel = {
        let ins = UILabel()
        ins.textColor = UIColor.ud.textTitle
        ins.font = UDFont.title1
        ins.text = "Settings"
        ins.textAlignment = .center
        return ins
    }()

    private lazy var cancelButton: UIButton = {
        let ins = UIButton(type: .system)
        ins.setContentHuggingPriority(.required, for: .horizontal)
        ins.setTitleColor(UIColor.ud.textPlaceholder, for: .normal)
        ins.setTitle(BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_Cancel, for: .normal)
        ins.titleLabel?.font = UDFont.body0
        ins.addTarget(self, action: #selector(onCancel(_:)), for: .touchUpInside)
        return ins
    }()

    private lazy var confirmButton: UIButton = {
        let ins = UIButton(type: .system)
        ins.setContentHuggingPriority(.required, for: .horizontal)
        ins.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        ins.setTitle(BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_Confirm, for: .normal)
        ins.titleLabel?.font = UDFont.body0
        ins.addTarget(self, action: #selector(onConfirm(_:)), for: .touchUpInside)
        return ins
    }()

    private lazy var previewHeightTF: UITextField = {
        let ins = UITextField()
        ins.placeholder = "\"auto\" or px value"
        ins.text = setting.previewHeight
        ins.textAlignment = .right
        ins.borderStyle = .line
        ins.layer.borderWidth = 1
        ins.layer.ud.setBorderColor(UIColor.ud.lineDividerDefault)
        ins.delegate = self
        return ins
    }()

    init(cache: BlockPreviewSetting?) {
        setting = cache ?? BlockPreviewSetting()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSubviews()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }

    @objc
    private func onCancel(_ sender: UIButton) {
        onSettingComplete?(nil)
        dismiss(animated: true, completion: nil)
    }

    @objc
    private func onConfirm(_ sender: UIButton) {
        guard setting.isValid else {
            UDToast.showFailure(with: "The setting is illegal, please check again", on: view)
            return
        }
        onSettingComplete?(setting)
        dismiss(animated: true, completion: nil)
    }

    private func setupSubviews() {
        view.backgroundColor = UIColor.ud.bgBody

        let wrapper0 = UIView()
        view.addSubview(wrapper0)
        wrapper0.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(16)
            make.height.equalTo(30)
        }

        wrapper0.addSubview(titleLabel)
        wrapper0.addSubview(cancelButton)
        wrapper0.addSubview(confirmButton)

        cancelButton.snp.makeConstraints { make in
            make.top.left.bottom.equalToSuperview()
        }

        confirmButton.snp.makeConstraints { make in
            make.top.right.bottom.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.bottom.centerX.equalToSuperview()
            make.left.greaterThanOrEqualTo(cancelButton.snp.right)
            make.right.lessThanOrEqualTo(confirmButton.snp.left)
        }

        let wrapper1 = UIView()
        view.addSubview(wrapper1)
        wrapper1.snp.makeConstraints { make in
            make.top.equalTo(wrapper0.snp.bottom).offset(15)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }

        let label = UILabel()
        label.text = "Preview Height"
        label.textColor = UIColor.ud.textCaption
        label.font = UDFont.body0
        wrapper1.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
        }

        wrapper1.addSubview(previewHeightTF)
        previewHeightTF.snp.makeConstraints { make in
            make.top.right.bottom.equalToSuperview()
            make.left.equalTo(label.snp.right).offset(16)
        }
    }
}

extension BlockPreviewSettingVC: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if textField == previewHeightTF {
            let nsString = textField.text as NSString?
            setting.previewHeight = nsString?.replacingCharacters(in: range, with: string)
            if setting.checkPreviewHeight() {
                textField.layer.ud.setBorderColor(UIColor.ud.functionSuccessContentDefault)
            } else {
                textField.layer.ud.setBorderColor(UIColor.ud.functionDangerContentDefault)
            }
        }
        return true
    }
}
