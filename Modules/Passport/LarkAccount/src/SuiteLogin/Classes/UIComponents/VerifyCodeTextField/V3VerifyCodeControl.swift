//
//  V3VerifyCodeControl.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2019/12/11.
//

import Foundation
import SnapKit

class V3VerifyCodeControl {

    static let defaultCountDownNum: uint = 60

    static let maxInputNum = 6

    var resentBlock: (() -> Void)?

    var verifyCodeBlock: ((String) -> Void)?

    var textChangeBlock: ((String) -> Void)?

    var timeoutBlock: (() -> Void)?

    private var countDownNum: uint = V3VerifyCodeControl.defaultCountDownNum

    enum Source {
        case switchUser
        case login
    }

    private let source: Source

    private lazy var verifyCodeTextField: V3VerifyCodeTextField = {
        return V3VerifyCodeTextField(
            beginEdit: autoBeginEdit,
            selectCodeBlock: { [weak self] (value) in
                guard let self = self else { return }
                self.textChangeBlock?(value)
                if value.count >= V3VerifyCodeControl.maxInputNum {
                    self.verifyCodeBlock?(value)
                }
            })
    }()

    private var countDownTitle: String {
           let title: String
           switch source {
           case .switchUser:
               title = BundleI18n.suiteLogin.Lark_Login_IdP_resend(String(countDownNum))
           case .login:
               title = BundleI18n.suiteLogin.Lark_Login_DescOfAuthentication(String(countDownNum))
           }
           return title
    }

    lazy var countdownButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(countDownTitle, for: .normal)
        btn.setTitleColor(UIColor.ud.textPlaceholder, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.addTarget(self, action: #selector(recentVerify), for: .touchUpInside)
        btn.isUserInteractionEnabled = false
        return btn
    }()

    private var verifyTimer: Timer?

    /// 是否自动开始编辑（弹出键盘）
    private let autoBeginEdit: Bool
    let needCountDown: Bool
    var view: UIView = UIView()

    init(
        needCountDown: Bool = true,
        withResentBlock block: (() -> Void)? = nil,
        textChangeBlock changeBlock: ((String) -> Void)? = nil,
        verifyCodeBlock verifyBlock: ((String) -> Void)? = nil,
        beginEdit: Bool = true,
        timeoutBlock: (() -> Void)?,
        source: V3VerifyCodeControl.Source
    ) {
        self.needCountDown = needCountDown
        self.resentBlock = block
        self.verifyCodeBlock = verifyBlock
        self.textChangeBlock = changeBlock
        self.timeoutBlock = timeoutBlock
        self.autoBeginEdit = beginEdit
        self.source = source
        self.setupSubviews()
    }

    func setupSubviews() {
        view.accessibilityIdentifier = "input_verification_code_edit"
        view.addSubview(verifyCodeTextField)
        verifyCodeTextField.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            if !needCountDown {
                make.bottom.equalToSuperview()
            }
        }
        if needCountDown {
            view.addSubview(countdownButton)
            countdownButton.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.right.lessThanOrEqualToSuperview()
                make.top.equalTo(verifyCodeTextField.snp.bottom).offset(Layout.countDownBtnTopSpace)
                make.bottom.equalToSuperview()
            }
        }
    }

    func updateCountDownButton() {
        guard needCountDown else { return }
        if countDownNum <= 0 {
            timeoutBlock?()
            countdownButton.setTitle(BundleI18n.suiteLogin.Lark_Login_V3_ResendVerifyCode, for: .normal)
            countdownButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
            countdownButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
            countdownButton.isUserInteractionEnabled = true
            verifyTimer?.invalidate()
            verifyTimer = nil
        } else {
            countdownButton.setTitle(countDownTitle, for: .normal)
            countdownButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        }
    }

    func updateTextFieldUserInteraction(_ enable: Bool) {
        verifyCodeTextField.isUserInteractionEnabled = enable
    }
    

    @objc
    func recentVerify() {
        guard needCountDown else { return }
        self.countDownNum = V3VerifyCodeControl.defaultCountDownNum
        startTime()
        countdownButton.isUserInteractionEnabled = false
        countdownButton.setTitle(countDownTitle, for: .normal)
        countdownButton.setTitleColor(UIColor.ud.textPlaceholder, for: .normal)
        self.resentBlock?()
    }

    @objc
    func timeInvocation() {
        guard needCountDown else { return }
        if countDownNum > 0 {
            self.countDownNum -= 1
        }
        self.updateCountDownButton()
    }

    func resetView() {
        verifyCodeTextField.resetView()
    }

    func beginEdit() {
        verifyCodeTextField.beginEdit()
    }
    
    func startTime() {
        guard needCountDown else { return }
        endTimer()
        verifyTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            self?.timeInvocation()
        })
    }

    func endTimer() {
        verifyTimer?.invalidate()
        verifyTimer = nil
    }

    func updateCountDown(_ count: uint) {
        guard needCountDown else { return }
        countDownNum = count
    }

    deinit {
        endTimer()
    }

}

extension V3VerifyCodeControl {
    struct Layout {
        static let countDownBtnTopSpace: CGFloat = 16.0
    }
}
