//
//  BOETTEnv.swift
//  PassportDebug
//
//  Created by ByteDance on 2022/7/25.
//

import Foundation
import LarkDebugExtensionPoint
import EENavigator
import RoundedHUD
import LarkEnv
import LarkContainer
import UniverseDesignDialog

struct BOETTEnvItem: DebugCellItem {
    var title: String { return "BOE X-TT-ENV header" }
    var detail: String { return DebugKey.shared.ttEnvHeader ?? "" }
    
    var canPerformAction: ((Selector) -> Bool)?
    var perfomAction: ((Selector) -> Void)?
    
    init() {
        self.canPerformAction = { (action) in
            if #selector(UIResponderStandardEditActions.copy(_:)) == action {
                return true
            } else {
                return false
            }
        }
        
        self.perfomAction = { (action) in
            if #selector(UIResponderStandardEditActions.copy(_:)) == action {
                UIPasteboard.general.string = DebugKey.shared.ttEnvHeader
            }
        }
    }
    
    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        func setFeatureEnv(_ env: String) {
            DebugKey.shared.ttEnvHeader = env
            exit(0)
        }
        
        let dialog = PassportDebugDialog(title: "修改 X-TT-ENV header",
                                         detail: "只适用于BOE环境的Passport APIs，修改后将重启App",
                                         text: DebugKey.shared.ttEnvHeader ?? "",
                                         placeHolder: "X-TT-ENV") { field in
            if DebugKey.shared.ttEnvHeader != field.text {
                let ttEnvHeader = field.text ?? ""
                setFeatureEnv(ttEnvHeader)
            }
        }
        DispatchQueue.main.async {
            Navigator.shared.present(dialog, from: debugVC)
        }
    }
}

class PassportDebugDialog: UDDialog {
    private var dialogTitle: String
    private var detail: String
    private var textFieldText: String
    private var placeHolder: String
    private var handler: (UITextField) -> Void
    private lazy var customView = UIView()
    lazy var detailLabel = UILabel()
    lazy var textField = UITextField()
    
    init(title: String, detail: String, text: String, placeHolder: String, handler: @escaping ((UITextField) -> Void)) {
        self.dialogTitle = title
        self.detail = detail
        self.textFieldText = text
        self.placeHolder = placeHolder
        self.handler = handler
        super.init(config: UDDialogUIConfig())
        self.customView.addSubview(detailLabel)
        self.customView.addSubview(textField)
        detailLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        textField.borderStyle = .roundedRect
        textField.snp.makeConstraints { make in
            make.height.equalTo(36).priority(500)
            make.bottom.left.right.equalToSuperview()
            make.top.equalTo(detailLabel.snp.bottom).offset(10)
        }
        self.detailLabel.textAlignment = .center
        self.detailLabel.numberOfLines = 0
        self.detailLabel.text = self.detail
        self.textField.text = self.textFieldText
        self.textField.placeholder = self.placeHolder
        self.setTitle(text: self.dialogTitle)
        self.setContent(view: self.customView)
        self.addSecondaryButton(text: "取消")
        self.addPrimaryButton(text: "确认", dismissCompletion:  { [weak self] in
            guard let self = self else { return }
            self.handler(self.textField)
        })
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class DebugKey {
    let disablePassportRustHTTPKey: String = "disablePassportRustHTTPKey"
    let disablePassportAPINewModelKey: String = "disablePassportAPINewModelKey"
    let passportTTEnvHeaderKey: String = "passportTTEnvHeaderKey"
    let enablePassportNetworkDebugToast: String = "passportNetworkDebugToast"
    
    static let shared = DebugKey()
    
    var ttEnvHeader: String? {
        didSet {
            UserDefaults.standard.set(ttEnvHeader, forKey: passportTTEnvHeaderKey)
        }
    }
    
    private init() {
        ttEnvHeader = UserDefaults.standard.string(forKey: passportTTEnvHeaderKey)
    }
}
