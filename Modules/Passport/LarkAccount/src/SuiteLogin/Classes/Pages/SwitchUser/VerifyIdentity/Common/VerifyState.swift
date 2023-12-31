//
//  VerifyState.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2020/2/16.
//

import Foundation
import RxRelay
import RxSwift

protocol VerifyTipProtocol {
    var verifyTip: NSAttributedString { get }
}

protocol VerifyProtocol {
    func applyCode() -> Observable<Void>
    func verify() -> Observable<Void>
}

protocol WebauthNServiceProtocol: AnyObject {
    var webAuthNService: PassportWebAuthService? { get set }
}

protocol VerifyStateProtocol: AnyObject {
    var verifyTip: NSAttributedString { get }
    var title: String { get }
    var subtitle: NSAttributedString { get }

    var isVerifying: Bool { get set }

    var switchBtnTitle: String { get }
    var retrieveLinkTitle: String { get }
    var needSwitchButton: Bool { get }
    var enableClientLoginMethodMemory: Bool { get }
    var recordVerifyType: VerifyType? { set get }
}

protocol VerifyViewModelProtocol: VerifyStateProtocol {
    var state: VerifyStateProtocol { get }
}

extension VerifyViewModelProtocol {
    var verifyTip: NSAttributedString { state.verifyTip }
    var title: String { state.title }
    var subtitle: NSAttributedString { state.subtitle }
    var isVerifying: Bool {
        set {
            state.isVerifying = newValue
        }
        get {
            state.isVerifying
        }
    }
    var switchBtnTitle: String { state.switchBtnTitle }
    var needSwitchButton: Bool { state.needSwitchButton }
    var enableClientLoginMethodMemory: Bool { state.enableClientLoginMethodMemory }
}

class VerifyPwdState: VerifyTipProtocol {

    var password: String = ""

    private let enableResetPwd: Bool

    init(enableResetPwd: Bool) {
        self.enableResetPwd = enableResetPwd
    }

    var verifyTip: NSAttributedString {
        return NSAttributedString.tip(str: "")
    }
    
    func resetPwdTip(pageInfo: VerifyPageInfo?) -> NSAttributedString {
        if let retrieveBtn = pageInfo?.retrieveButton {
            let attributedString = NSMutableAttributedString.tip(str: retrieveBtn.text+" ", color: UIColor.ud.textPlaceholder)
            let suffixLink = NSAttributedString.link(
                str: I18N.Lark_Login_V3_ResetPwd,
                url: Link.resetPwdURL,
                font: UIFont.systemFont(ofSize: 14.0)
            )
            attributedString.append(suffixLink)
            return attributedString
        }else {
            return NSAttributedString.tip(str: "")
        }
    }
}


//验证短信上行的State
class VerifyMoState: VerifyTipProtocol {
    
    private var verifyMoTip: String?
    
    var verifyTip: NSAttributedString {
        if let tipStr = verifyMoTip {
            return NSAttributedString.tip(str: tipStr)
        }
        return NSAttributedString.tip(str: "")
    }

    init(verifyMoTip: String?) {
        self.verifyMoTip = verifyMoTip
    }

}

//验证Fido2的State
class VerifyFidoState: VerifyTipProtocol {

    private var verifyFidoTip: String?

    var verifyTip: NSAttributedString {
        if let tipStr = verifyFidoTip {
            return NSAttributedString.tip(str: tipStr)
        }
        return NSAttributedString.tip(str: "")
    }

    init(verifyFidoTip: String?) {
        self.verifyFidoTip = verifyFidoTip
    }
}

class VerifyCodeState: VerifyTipProtocol {

    var timeout: Bool = false
    var hasApplyCode: Bool
    var code: String = ""
    let expire: BehaviorRelay<uint> = BehaviorRelay(value: 60)

    private var verifyCodeTip: String?

    init(verifyCodeTip: String?, hasApplyCode: Bool = false) {
        self.verifyCodeTip = verifyCodeTip
        self.hasApplyCode = hasApplyCode
    }

    var verifyTip: NSAttributedString {
        if let tip = self.verifyCodeTip {
            return tip.html2Attributed(font: UIFont.systemFont(ofSize: 14), forgroundColor: UIColor.ud.textTitle)
        } else {
            return NSAttributedString.tip(str: "")
        }
    }

    private func checkIsEmail(contact: String?) -> Bool {
        guard let contact = contact else {
            return false
        }
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let emailTest: NSPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        return emailTest.evaluate(with: contact)
    }

    func recoverAccountTip(pageInfo: VerifyPageInfo, linkTile: String) -> NSAttributedString {
        let isEmail = checkIsEmail(contact: pageInfo.contact)
        let tip = isEmail ? BundleI18n.suiteLogin.Lark_Login_RecoverAccountEmailUnable : pageInfo.retrieveButton?.text ?? BundleI18n.suiteLogin.Lark_Login_RecoverAccountNumberUnusable
        let attributedString = NSMutableAttributedString.tip(str: tip, color: UIColor.ud.textPlaceholder)
        let suffixLink = NSAttributedString.link(
            str: linkTile,
            url: Link.recoverAccountCarrierURL,
            font: UIFont.systemFont(ofSize: 14.0)
        )
        attributedString.append(suffixLink)
        return attributedString
    }
}
