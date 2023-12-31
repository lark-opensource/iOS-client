//
//  SecurityViewController.swift
//  SuiteLogin
//
//  Created by sniperj on 2019/5/14.
//

import LarkUIKit
import UIKit
import Lottie
import RxSwift
import EENavigator
import LarkAccountInterface
import LarkSceneManager
import LKCommonsLogging
import LarkContainer
import UniverseDesignToast

let inputPwdBgViewY: CGFloat = (667.0 - 424.5) / 667.0
let inputPwdBgViewHeight: CGFloat = 424.5 / 667.0

let inputPwdViewHeight: CGFloat = 16.0 / 667.0
let inputPwdViewWidth: CGFloat = 40.0 / 375.0
let inputPwdViewY: CGFloat = 104.5 / 667.0

let loadingViewY: CGFloat = 110.5 / 667.0

class SecurityViewController: UIViewController {

    static let logger = Logger.plog(SecurityViewController.self, category: "LarkAccount.SecurityViewController")

    private var isOpenSecurity: Bool

    private var isNeedUpdate: Bool = false

    public var result: SecurityResult?

    private var securityError: SecurityError = .userCancel
    
    private let verifyStep: VerifySecurityPasswordStepInfo?
    private let resetStep: V4StepData?

    // MARK: - customView
    private lazy var inputPwdView: InputPwdView = {
        let pwdView = InputPwdView(
            frame: CGRect(
                x: (view.frame.width - InputPwdView.Layout.width) / 2,
                y: inputPwdViewY * view.frame.height,
                width: InputPwdView.Layout.width,
                height: InputPwdView.Layout.height
        ))
        pwdView.pwdFinishBlock = { [weak self] (isFinish) in
            if isFinish {
                guard let `self` = self, let verifyStep = self.verifyStep else { return }
                _ = self.service.securityAPI.verifySecurityPassword(serverInfo: verifyStep, appID: self.service.securityAppID ?? "", password: self.inputPwdView.pwd ?? "") { [weak self] event, stepInfo in
                    guard let self = self, let token = stepInfo?["token"] as? String else { return }
                    /// 请求成功
                    self.service.securityResult?(SecurityResultCode.success, "Security verification succeeded.", token)
                    self.service.securityResult = nil
                    self.detachFromWindow()
                } failure: { [weak self] error in
                    guard let `self` = self else { return }
                    self.loading(false)
                    self.inputPwdView.isHidden = false
                    self.forgetPwdButton.isHidden = false
                    if case .badServerCode(let info) = error {
                        if info.rawCode == V3ServerBizError.securityPasswordRetryLimited.rawValue {
                            self.securityError = .incorrectPwdRestrict
                            self.showPwdErrorMoreAlert(errorString: info.message)
                        } else if info.rawCode == V3ServerBizError.securityPasswordWrong.rawValue {
                            self.securityError = .incorrectPwd
                            self.showPwdErrorAlert(errorString: info.message)
                        } else {
                            UDToast.showTips(with: info.message, on: self.view)
                            self.cancelOperation()
                        }
                    } else {
                        UDToast.showFailure(with: error.localizedDescription, on: self.view)
                        self.cancelOperation()
                    }
                }
                
                self.loading(true)
                self.inputPwdView.clearTextField()
                self.inputPwdView.resignFirstResponder()
                self.inputPwdView.isHidden = true
                self.forgetPwdButton.isHidden = true
            }
        }
        return pwdView
    }()

    private var loadingView: LOTAnimationView?

    private lazy var inputPwdBgView: UIView = {
        let inputPwdBgView = UIView()
        inputPwdBgView.backgroundColor = UIColor.ud.bgBody
        inputPwdBgView.layer.cornerRadius = Common.Layer.commonPopPanelRadius
        return inputPwdBgView
    }()

    private lazy var inputPwdTitleLabel: UILabel = {
        let inputPwdTitleLabel = UILabel()
        inputPwdTitleLabel.textAlignment = .center
        inputPwdTitleLabel.text = verifyStep?.title ?? BundleI18n.suiteLogin.Lark_Security_Verify_TitleOfInputPassword
        inputPwdTitleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        inputPwdTitleLabel.textColor = UIColor.ud.textTitle
        inputPwdTitleLabel.autoresizingMask = .flexibleWidth
        inputPwdTitleLabel.adjustsFontSizeToFitWidth = true
        return inputPwdTitleLabel
    }()

    private lazy var maskView: UIView = {
        let maskView = UIView(frame: .zero)
        maskView.backgroundColor = UIColor.ud.bgMask//UIColor.ud.color(0, 0, 0, 0.3)
        return maskView
    }()

    private lazy var forgetPwdButton: UIButton = {
        let forgetPwdBtn = UIButton(type: .custom)
        forgetPwdBtn.setTitle(verifyStep?.forgetButton.text ?? BundleI18n.suiteLogin.Lark_Security_Verify_TipOfForgetPassword, for: .normal)
        forgetPwdBtn.setTitleColor(UIColor.ud.css("#3377ff"), for: .normal)
        forgetPwdBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        forgetPwdBtn.addTarget(self, action: #selector(forgetPwd), for: .touchUpInside)
        forgetPwdBtn.sizeToFit()
        return forgetPwdBtn
    }()

    private lazy var closeButton: UIButton = {
        let closeButton = UIButton(type: .custom)
        let btnImg = BundleResources.UDIconResources.closeOutlined
        closeButton.setImage(btnImg, for: .normal)
        closeButton.addTarget(self, action: #selector(clickClose), for: .touchUpInside)
        return closeButton
    }()

    private var securityWindow = SecurityWindow(frame: UIScreen.main.bounds)

    private var firstAppear: Bool = true

    private let disposeBag = DisposeBag()

    @Provider private var service: V3LoginService

    private let context: UniContextProtocol

    ///
    /// - Parameters:
    ///   - isOpen: 已有安全验证密码
    ///   - appID: 应用Id
    public init(
        isOpen: Bool,
        verifyStep: VerifySecurityPasswordStepInfo? = nil,
        resetStep: V4StepData? = nil,
        context: UniContextProtocol
    ) {
        assert((isOpen && verifyStep != nil) || (!isOpen && resetStep != nil), "Invalid server data")
        self.isOpenSecurity = isOpen
        self.verifyStep = verifyStep
        self.resetStep = resetStep
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func attachVCToWindow() {
        securityWindow.windowLevel = .normal
        securityWindow.isHidden = false
        securityWindow.rootViewController = self
        let mainScene = Scene.mainScene()
        SceneManager.shared.active(scene: mainScene, from: nil) { (window, error) in
            if error == nil,
               let mainSceneWindow = window {
                Self.logger.info("succeed to activate main scene", method: .local)
                if #available(iOS 13.0, *) {
                    self.securityWindow.windowScene = mainSceneWindow.windowScene
                }
                self.securityWindow.frame = mainSceneWindow.bounds
            } else {
                Self.logger.info("failed to activate main scene")
            }
        }

        securityWindow.makeKeyAndVisible()
    }

    public func detachFromWindow() {
        securityWindow.isHidden = true
        securityWindow.rootViewController = nil
        securityWindow.accessibilityIdentifier = nil
        view.removeFromSuperview()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        // 有安全验证密码 显示
        if isOpenSecurity {
            createInputPwdView()
        }
        observeKeyboard()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /// 没有安全验证码密码 显示提示
        if !isOpenSecurity, firstAppear {
            firstAppear = false
            showAlert()
        }
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        inputPwdView.resignFirstResponder()
    }

    private func observeKeyboard() {
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .bind { [weak self] (noti) in
                guard let self = self else { return }
                if self.inputPwdBgView.superview == nil { return }
                if let keyboardSize = (noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                    // 键盘高度 - 「忘记密码」Button 以下高度
                    let bottomDistance = self.inputPwdBgHeight - (self.forgetPwdButton.frame.maxY + Security.Layout.verifyForgetButtonBottomSpaceKeyboardShow)
                    let offset = keyboardSize.height - bottomDistance
                    if offset > 0 {
                        self.inputPwdBgView.snp.updateConstraints { (make) in
                            make.height.equalTo(self.inputPwdBgHeight + offset)
                        }
                        self.view.layoutIfNeeded()
                    }
                }
            }.disposed(by: self.disposeBag)

        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
            .bind { [weak self] (_) in
                guard let self = self else { return }
                if self.navigationController?.topViewController != self {
                    return
                }
                self.inputPwdBgView.snp.updateConstraints({ (make) in
                    make.height.equalTo(self.inputPwdBgHeight)
                })
                self.view.layoutIfNeeded()
            }.disposed(by: self.disposeBag)
    }

    private func showAlert() {
        let alertVC = UIAlertController(title: nil, message: BundleI18n.suiteLogin.Lark_Security_Verify_MessageOfGotoSetPassword, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: BundleI18n.suiteLogin.Lark_Security_Verify_TextOfGoToSetPassword, style: .default) { [weak self] (_) in
            
            self?.detachFromWindow()
            
            // 未设置安全密码
            guard let event = self?.resetStep?.stepName, let stepInfo = self?.resetStep?.stepInfo else {
                assertionFailure("Invalid server data")
                Self.logger.error("SecurityViewController: Invalid reset step server data")
                self?.cancelOperation()
                return
            }
            LoginPassportEventBus.shared.post(event: event, context: V3RawLoginContext(stepInfo: stepInfo, context: self?.context)) {
            } error: { error in
            }
        }
        let cancelAction = UIAlertAction(title: BundleI18n.suiteLogin.Lark_Security_Verify_TextOfCancel, style: .cancel) { (_) in
            self.cancelOperation()
        }
        alertVC.addAction(confirmAction)
        alertVC.addAction(cancelAction)
        self.present(alertVC, animated: false)
    }

    private func showPwdErrorAlert(errorString: String) {
        let alertVC = UIAlertController(title: nil, message: errorString, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: BundleI18n.suiteLogin.Lark_Security_Verify_TextOfRetryInputPassword, style: .default)
        alertVC.addAction(confirmAction)
        self.present(alertVC, animated: false)
    }

    private func showPwdErrorMoreAlert(errorString: String) {
        let alertVC = UIAlertController(title: nil, message: errorString, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: BundleI18n.suiteLogin.Lark_Security_Verify_TextOfCancel, style: .default)
        let cancelAction = UIAlertAction(title: BundleI18n.suiteLogin.Lark_Security_Verify_TextOfGetBackPassword, style: .cancel) { [weak self] (_) in
            self?.forgetSecurityPassword()
        }
        alertVC.addAction(confirmAction)
        alertVC.addAction(cancelAction)
        self.present(alertVC, animated: false)
    }

    private func loading(_ isLoading: Bool) {
        if loadingView == nil {
            // swiftlint:disable ForceUnwrapping
            loadingView = LOTAnimationView(filePath: BundleConfig.LarkAccountBundle.path(forResource: "data", ofType: "json", inDirectory: "Lottie/pwd_loading")!)
            // swiftlint:enable ForceUnwrapping

            loadingView?.frame = CGRect(x: (view.frame.width - 44) / 2, y: loadingViewY * view.frame.height, width: 44, height: 44)
            loadingView?.loopAnimation = true
            
            if let loadingView = loadingView {
                self.inputPwdBgView.addSubview(loadingView)
            }
        }
        loadingView?.isHidden = !isLoading
        if isLoading {
            loadingView?.play()
        } else {
            loadingView?.stop()
        }
    }

    private func createInputPwdView() {
        if maskView.superview == nil {
            view.addSubview(maskView)
            maskView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        if inputPwdBgView.superview == nil {
            maskView.addSubview(inputPwdBgView)
            inputPwdBgView.snp.makeConstraints { (make) in
                make.height.equalTo(inputPwdBgViewHeight * view.frame.height + Common.Layer.commonPopPanelRadius)
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        }
        let closeButtonWidth: CGFloat = 24.0
        if inputPwdTitleLabel.superview == nil {
            inputPwdBgView.addSubview(inputPwdTitleLabel)
            let leftPadding = Security.Layout.closeBtnRight + closeButtonWidth
            inputPwdTitleLabel.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview().inset(leftPadding)
                make.top.equalToSuperview().offset(Security.Layout.titleTopSpace)
//                make.height.equalTo(Security.Layout.titleHeight)
            }

        }
        if closeButton.superview == nil {
            inputPwdBgView.addSubview(closeButton)
            closeButton.snp.makeConstraints { (make) in
                make.height.width.equalTo(closeButtonWidth)
                make.centerY.equalTo(inputPwdTitleLabel.snp.centerY)
                make.right.equalToSuperview().offset(-Security.Layout.closeBtnRight)
            }
        }
        if inputPwdView.superview == nil {
            inputPwdBgView.addSubview(inputPwdView)
            inputPwdView.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.top.equalTo(inputPwdTitleLabel.snp.bottom).offset(Security.Layout.verifyInputTopSpace)
                make.height.equalTo(InputPwdView.Layout.height)
                make.width.equalTo(InputPwdView.Layout.width)
            }
        }
        if forgetPwdButton.superview == nil {
            inputPwdBgView.addSubview(forgetPwdButton)
            forgetPwdButton.snp.makeConstraints { (make) in
                make.top.equalTo(inputPwdView.snp.bottom).offset(Security.Layout.verifyForgetButtonSpace)
                make.centerX.equalToSuperview()
            }
        }
        // 需要先计算frame，否则iPad横屏时键盘弹起处理错误
        view.layoutIfNeeded()
    }

    @objc
    private func clickClose() {
        cancelOperation()
    }

    @objc
    private func forgetPwd() {
        view.endEditing(true)
        
        forgetSecurityPassword()
    }

    private func cancelOperation() {
        detachFromWindow()
        handleError()
    }

    private func handleError() {
        switch securityError {
        case .userCancel:
            service.securityResult?(
                SecurityResultCode.userCancelOrFailed,
                securityError.rawValue,
                nil
            )
        case .incorrectPwd:
            service.securityResult?(
                SecurityResultCode.passwordError,
                securityError.rawValue,
                nil
            )
        case .incorrectPwdRestrict:
            service.securityResult?(
                SecurityResultCode.retryTimeLimit,
                securityError.rawValue,
                nil
            )
        }
        service.securityResult = nil
    }
    
    private func forgetSecurityPassword() {
        detachFromWindow()
        
        guard let event = verifyStep?.forgetButton.next?.stepName,
              let stepInfo = verifyStep?.forgetButton.next?.stepInfo else {
            return
        }
        
        LoginPassportEventBus.shared.post(event: event, context: V3RawLoginContext(stepInfo: stepInfo, context: context)) {
        } error: { error in
        }
    }
    
    var inputPwdBgHeight: CGFloat { inputPwdBgViewHeight * view.frame.height }
}

class SecurityWindow: UIWindow {

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)

        if hitView == self {
            return nil
        }

        return hitView
    }
}

extension SecurityWindow {
    class func showSecurityVC(
        isOpen: Bool,
        verifyStep: VerifySecurityPasswordStepInfo? = nil,
        resetStep: V4StepData? = nil,
        context: UniContextProtocol
    ) {
        
        let securityViewController = SecurityViewController(isOpen: isOpen, verifyStep: verifyStep, resetStep: resetStep, context: context)
        securityViewController.attachVCToWindow()
    }
}
