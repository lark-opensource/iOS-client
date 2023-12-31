//
//  CTADialogDebugController.swift
//  CTADialog
//
//  Created by aslan on 2023/10/10.
//

#if !LARK_NO_DEBUG

import Foundation
import EENavigator
import LarkNavigator
import LarkContainer
import SnapKit
import LarkAccountInterface

final class CTADialogDebugController: UIViewController {

    lazy var featureInput: UITextField = {
        let input = self.createTextField(placeholder: "feature key")
        return input
    }()

    lazy var sceneInput: UITextField = {
        let input = self.createTextField(placeholder: "scene")
        return input
    }()

    lazy var tenantIdInput: UITextField = {
        let input = self.createTextField(placeholder: "tenant Id")
        return input
    }()

    lazy var userIdInput: UITextField = {
        let input = self.createTextField(placeholder: "user Id")
        return input
    }()

    func createTextField(placeholder: String) -> UITextField {
        let input = UITextField()
        input.backgroundColor = .clear
        input.layer.borderWidth = 1
//        input.layer.borderColor = UIColor.ud.lineBorderComponent.cgColor
        input.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        input.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor: UIColor.ud.textPlaceholder])
        input.layer.cornerRadius = 6
        input.leftViewRect(forBounds: CGRectMake(0, 0, 10, 40))
        input.leftView = UIView(frame: CGRectMake(0, 0, 10, 40))
        input.leftViewMode = .always
        return input
    }

    lazy var dialogService: CTADialog = {
        /// debug code
        let userResolver: UserResolver = Container.shared.getCurrentUserResolver()
        let dialog = CTADialog(userResolver: userResolver)
        return dialog
    }()

    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.ud.bgBody

        self.view.addSubview(self.featureInput)
        self.featureInput.text = "vc_subtitle_function"
        self.featureInput.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(40)
            make.top.equalToSuperview().offset(120)
        }

        self.view.addSubview(self.sceneInput)
        self.sceneInput.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(40)
            make.top.equalTo(featureInput.snp.bottom).offset(10)
        }

        self.view.addSubview(self.tenantIdInput)
        self.tenantIdInput.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(40)
            make.top.equalTo(sceneInput.snp.bottom).offset(10)
        }

        self.view.addSubview(self.userIdInput)
        self.userIdInput.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(40)
            make.top.equalTo(tenantIdInput.snp.bottom).offset(10)
        }

        let button = UIButton(frame: CGRect(x: 100, y: 350, width: 200, height: 50))
        button.setTitle("SHOW DIALOG", for: .normal)
        button.addTarget(self, action: #selector(didTapShowDialog), for: .touchUpInside)
        button.setTitleColor(.blue, for: .normal)
        self.view.addSubview(button)
    }

    @objc
    func didTapShowDialog() throws {
        if let vc = Navigator.shared.mainSceneWindow?.fromViewController {
            let userResolver: UserResolver = Container.shared.getCurrentUserResolver()
            let checkpointUserId = !self.userIdInput.text.isEmpty ? self.userIdInput.text : "0"
            let passportUser = try userResolver.resolve(type: PassportUserService.self)
            let tenantId = (!self.tenantIdInput.text.isEmpty ? self.tenantIdInput.text : passportUser.userTenant.tenantID) ?? passportUser.userTenant.tenantID
            self.dialogService.show(from: vc, featureKey: self.featureInput.text ?? "", scene: self.sceneInput.text ?? "", checkpointTenantId: tenantId, checkpointUserId: checkpointUserId) { success in }
        }
    }
}

#endif
