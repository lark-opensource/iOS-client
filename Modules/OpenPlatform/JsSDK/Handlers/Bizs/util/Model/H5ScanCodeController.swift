//
//  H5ScanCodeController.swift
//  LarkWeb
//
//  Created by 武嘉晟 on 2019/11/13.
//

import UIKit
import QRCode
import SnapKit

class H5ScanCodeController: ScanCodeViewController {
    public var shouldShowInput: Bool = false
    private lazy var button: HlightButton = {
        let button = HlightButton(type: .custom)
        button.setTitle(BundleI18n.JsSDK.OpenPlatform_AppCenter_EnterBarcode, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 20
        button.layer.borderColor = UIColor(white: 1, alpha: 0.6).cgColor
        button.layer.borderWidth = 1
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 40, bottom: 10, right: 40)
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        return button
    }()
    private lazy var label: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.JsSDK.OpenPlatform_AppCenter_CannotIdentifyBarcode
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        if !shouldShowInput {
            return
        }
        let vh = view.frame.height
        let rectSize: CGFloat = 257
        let h = vh / 2 + rectSize / 2 + 40 - rectSize * 0.15
        view.addSubview(label)
        view.addSubview(button)
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(h)
            make.centerX.equalToSuperview()
            make.height.equalTo(20)
        }
        button.snp.makeConstraints { (make) in
            make.top.equalTo(label.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.height.equalTo(40)
        }
    }
    @objc
    private func didTapButton() {
        let alert = UIAlertController(title: BundleI18n.JsSDK.OpenPlatform_AppCenter_PleaseEnterBarcode, message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.clearButtonMode = .whileEditing
            textField.placeholder = BundleI18n.JsSDK.OpenPlatform_AppCenter_PleaseEnterBarcode
        }
        alert.addAction(UIAlertAction(title: BundleI18n.JsSDK.OpenPlatform_AppCenter_Cancel, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: BundleI18n.JsSDK.OpenPlatform_AppCenter_Confirm, style: .default) { [weak self, weak alert] (_) in
            guard let str = alert?.textFields?.first?.text,
                !str.isEmpty else {
                    return
            }
            self?.didScanQRCode(dataStr: str, from: .camera)
        })
        present(alert, animated: true, completion: nil)
    }
}
