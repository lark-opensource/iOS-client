//
//  SecuritySetPwdViewController.swift
//  SuiteLogin
//
//  Created by sniperj on 2019/5/14.
//

import Foundation
import UIKit
import LarkUIKit
import LKCommonsLogging
import RxSwift
import LarkContainer
import UniverseDesignToast

indirect enum SecurityVerifyAction {
    case create         /// 创建密码
    case reset          /// 重设密码
    case modify         /// 修改密码
    case confirm(from: SecurityVerifyAction, oldPwd: String) /// 确认密码

    var rawValue: String {
        switch self {
        case .create: return "create"
        case .reset: return "reset"
        case .modify: return "modify"
        case .confirm(let from, _): return from.rawValue
        }
    }
}

class SecuritySetPwdViewController: BaseUIViewController {

    static let logger = Logger.plog(SecuritySetPwdViewController.self, category: "SuiteLogin.SecuritySetPwdViewController")

    lazy var pwdPreviewButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(Resource.pwd_ClosePreview.ud.withTintColor(UIColor.ud.iconN3), for: .normal)
        button.setBackgroundImage(Resource.pwd_Preview.ud.withTintColor(UIColor.ud.iconN3), for: .selected)
        button.addTarget(self, action: #selector(pwdPreviewClick), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return button
    }()

    let action: SecurityVerifyAction

    lazy var inputPwdView: InputPwdView = {
        let inputPwdView = InputPwdView(frame: CGRect(x: 8, y: 0, width: InputPwdView.Layout.width, height: InputPwdView.Layout.height))
        inputPwdView.pwdFinishBlock = { [weak self] (isNeedNext) in
            if isNeedNext {
                self?.next()
            }
        }
        return inputPwdView
    }()

    lazy var desLabel: UILabel = {
        let desLabel = UILabel()
        desLabel.text = BundleI18n.suiteLogin.Lark_Security_Verify_TipOfInputPassword
        desLabel.textColor = UIColor.ud.textTitle
        desLabel.font = UIFont.systemFont(ofSize: 16)
        desLabel.textAlignment = .left
        desLabel.sizeToFit()
        return desLabel
    }()

    lazy var subDesLabel: UILabel = {
        let subDesLabel = UILabel()
        subDesLabel.text = BundleI18n.suiteLogin.Lark_Security_Verify_SubTipOfInputPassword()
        subDesLabel.textColor = UIColor.ud.textPlaceholder
        subDesLabel.font = UIFont.systemFont(ofSize: 12)
        subDesLabel.numberOfLines = 0
        subDesLabel.textAlignment = .center
        subDesLabel.sizeToFit()
        return subDesLabel
    }()

    private var isClosePreview = true
    private let disposeBag = DisposeBag()
    @Provider var service: V3LoginService
    private let step: SetSecurityPasswordStepInfo
    private let complete: () -> Void
    
    init(action: SecurityVerifyAction, step: SetSecurityPasswordStepInfo, complete: @escaping () -> Void) {
        self.step = step
        self.complete = complete
        self.action = action
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgLogin

        switch action {
        case .create:
            title = step.title
        case .confirm:
            title = step.confirmTitle
        default:
            title = BundleI18n.suiteLogin.Lark_Security_Verify_TitleOfSetupNewPassword
        }

        let header = headerView()
        view.addSubview(header)
        header.snp.makeConstraints { (make) in
            make.top.equalTo(viewTopConstraint).offset(Security.Layout.desTopSpace)
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        view.addSubview(inputPwdView)
        inputPwdView.snp.makeConstraints { (make) in
            make.width.equalTo(InputPwdView.Layout.width)
            make.height.equalTo(InputPwdView.Layout.height)
            make.centerX.equalToSuperview()
            make.top.equalTo(header.snp.bottom).offset(CL.itemSpace * 2)
        }

        view.addSubview(subDesLabel)
        subDesLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(CL.itemSpace)
            make.top.equalTo(inputPwdView.snp.bottom).offset(CL.itemSpace * 2)
        }

        Self.logger.info("n_page_set_pwd_start", method: .local)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        inputPwdView.becomeFirstResponder()
    }

    func headerView() -> UIView {
        let back = UIView()
        back.addSubview(desLabel)
        back.addSubview(pwdPreviewButton)
        desLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        pwdPreviewButton.snp.makeConstraints { (make) in
            make.left.equalTo(desLabel.snp.right).offset(CL.itemSpace / 2)
            make.centerY.equalTo(desLabel)
            make.right.equalToSuperview()
            make.size.equalTo(CGSize(width: 15, height: 15))
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
        return back
    }

    override func backItemTapped() {
        // custom close
        switch action {
        case .create, .reset:
            // 从验证码过来 presentingViewController = OTPVC 返回流程结束直接dismiss
            if presentingViewController != nil {
                self.dismiss(animated: true, completion: {
                    self.complete()
                })
            } else {
                // fallback
                super.backItemTapped()
            }
        case .modify:
            // 从验证安全码过来，返回流程结束
            complete()
        case .confirm:
            super.backItemTapped()
        }
    }

    func next() {

        Self.logger.info("n_action_set_pwd_next", method: .local)
        
        if let pwd = inputPwdView.pwd {
            if pwd.range(of: step.pwdWeakRegExp, options: .regularExpression) != nil {
                Self.logger.info("n_action_set_weak_pwd")
                
                inputPwdView.clearTextField()
                UDToast.showFailure(with: step.pwdWeakErrMsg, on: view)
                return
            }
        }

        if case let .confirm(from, oldPwd) = action {
            if let pwd = inputPwdView.pwd, oldPwd == pwd {
                Self.logger.info("n_action_set_pwd_req")
                let hud = UDToast.showDefaultLoading(on: view)
                _ = service.securityAPI.setSecurityPassword(serverInfo: step, password: oldPwd) { [weak self] step, stepInfo in
                    guard let self = self else { return }
                    Self.logger.info("n_action_set_pwd_req_succ")

                    hud.remove()
                    self.complete()
                    switch from {
                    case .create:
                        UDToast.showTips(with: BundleI18n.suiteLogin.Lark_Passport_SetSecurityCodeSuccessToast, on: self.view)
                    default:
                        UDToast.showTips(with: BundleI18n.suiteLogin.Lark_Passport_ModifySecurityCodeSuccessToast, on: self.view)
                    }
                    
                    LoginPassportEventBus.shared.post(event: step, context: V3RawLoginContext(stepInfo: stepInfo, context: nil)) {
                    } error: { error in
                    }
                } failure: { [weak self]  error in
                    guard let `self` = self else { return }
                    Self.logger.error("n_action_set_pwd_req_fail", error: error)
                    hud.remove()
                    if case .badServerCode(let info) = error {
                        UDToast.showTipsOnScreenCenter(with: info.message, on: self.view)
                    }
                }
            } else {
                UDToast.showTips(with: I18N.Lark_Passport_SCWordNotSameToastPC, on: self.view)
                inputPwdView.clearTextField()
            }
        } else {
            guard let oldPwd = inputPwdView.pwd else {
                return
            }
            
            let vc = SecuritySetPwdViewController(
                action: .confirm(from: action, oldPwd: oldPwd),
                step: step,
                complete: { [weak self] in
                    guard let self = self else { return }
                    if self.navigationController?.presentingViewController != nil {
                        self.navigationController?.dismiss(animated: true, completion: { [weak self] in
                            self?.complete()
                        })
                    } else {
                        if let viewControllers = self.navigationController?.viewControllers, let lastVC = viewControllers.last {
                            var i = viewControllers.count - 1
                            var toVC: UIViewController = lastVC
                            while i > 0 && (toVC is SecuritySetPwdViewController || toVC is V4LoginVerifyViewController)  {
                                i -= 1
                                toVC = viewControllers[i]
                            }
                            self.navigationController?.popToViewController(toVC, animated: true)
                        }
                        
                        self.complete()
                    }
                }
            )
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc
    private func pwdPreviewClick() {
        isClosePreview = !isClosePreview
        pwdPreviewButton.isSelected = !isClosePreview
        inputPwdView.isShowExisting = !isClosePreview
    }
}
