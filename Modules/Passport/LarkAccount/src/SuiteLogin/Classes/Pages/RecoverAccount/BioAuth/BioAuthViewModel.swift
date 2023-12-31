//
//  BioAuthViewModel.swift
//  LarkAccount
//
//  Created by bytedance on 2021/7/28.
//

import Foundation
import RxSwift
import LKCommonsLogging
import LarkContainer

class BioAuthViewModel: V3ViewModel {
    private let logger = Logger.log(BioAuthViewModel.self, category: "SuiteLogin.BioAuthViewModel")

    @Provider var bioAuthApi: BioAuthAPI // user:checked (global-resolve)
    @Provider private var realNameVerifyAPI: RealnameVerifyAPI // user:checked (global-resolve)

    let disposeBag: DisposeBag = DisposeBag()
    private let api: RecoverAccountAPIProtocol
    let bioAuthInfo: V4BioAuthInfo
    let title: String
    let subTitle: String
    let from: RecoverAccountSourceType
    let switchUserSub: PublishSubject<SwitchUserStatus>?
    let qrRealNameFlowType = "qr_real_name"

    init(
        step: String,
        additionalInfo: Codable?,
        api: RecoverAccountAPIProtocol,
        bioAuthInfo: V4BioAuthInfo,
        from: RecoverAccountSourceType,
        context: UniContextProtocol,
        switchUserSub: PublishSubject<SwitchUserStatus>? = nil
    ) {
        self.api = api
        self.bioAuthInfo = bioAuthInfo
        self.title = bioAuthInfo.title ?? ""
        self.subTitle = bioAuthInfo.subtitle ?? ""
        self.from = from
        self.switchUserSub = switchUserSub
        super.init(step: step, stepInfo: bioAuthInfo, context: context)
        self.additionalInfo = additionalInfo
    }

    func onVerifyFaceButtonClicked(completion: @escaping (_ error: Error?) -> Void) -> Observable<Void> {
        guard let flowType = self.bioAuthInfo.flowType else {
            Self.logger.error("bioAuthGetTicket failed: no flowType.")
            completion(V3LoginError.clientError("No flow type"))
            return .just(())
        }
        
        return bioAuthApi.bioAuthGetTicket(serverInfo: bioAuthInfo, context: context)
            .do(onNext: { _ in
                completion(nil)
            }, onError: { error in
                completion(error)
            })
            .post(additionalInfo ,context: context)
    }

    func cancelRealNameQRCodeVerificationIfNeeded() {
        if bioAuthInfo.flowType == qrRealNameFlowType {
            realNameVerifyAPI.cancelQRCodeVerification(serverInfo: bioAuthInfo)
        }
    }

    var buttonTitle: String {
        if let buttonTitle = bioAuthInfo.nextButton?.text {
            return buttonTitle
        } else {
            return BundleI18n.suiteLogin.Lark_Login_RecoverAccountFaceVerifyFaceButton
        }
    }
    
    var switchButtonTitle: NSAttributedString? {
        guard let str = bioAuthInfo.switchButton?.text else {
            return nil
        }
        let string = attributedString(for: str, UIColor.ud.primaryContentDefault)
        return string
    }

    var bottomTitle: NSAttributedString {
        let string = attributedString(for: bioAuthInfo.agreeDoc, UIColor.ud.textPlaceholder)
        let attributedString = NSMutableAttributedString(attributedString: string)
        return attributedString
    }

    var policyShouldShow: Bool {
        return bioAuthInfo.policyVisible
    }

    var policyDomain: String? {
        return bioAuthInfo.policyDomain
    }

    func policyAttributedString(forAlertOrNot flag: Bool) -> NSAttributedString? {
        guard policyShouldShow else { return nil }

        let font: UIFont = UIFont.systemFont(ofSize: 14.0)
        let policyStr = I18N.Lark_Passport_IdentityVerifyPolicy
        let str: String
        if flag {
            str = I18N.Lark_IdentityVerification_IHaveReadAgreedTheTerm_Option(policyStr)
        } else {
            str = I18N.Lark_IdentityVerification_ReadAgreeTheTerm_Description(policyStr)
        }
        let attributedStr = NSMutableAttributedString.tip(str: str, color: UIColor.ud.textPlaceholder, font: font, aligment: .left)
        let policyAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.primaryContentDefault,
            .link: Link.identityURL
        ]
        let policyRange = (str as NSString).range(of: policyStr)
        if policyRange.location != NSNotFound {
            attributedStr.addAttributes(policyAttributes, range: policyRange)
        }
        return attributedStr
    }

    override func clickClose() {
        V3ViewModel.logger.info("send cancel")
        switchUserSub?.onNext(.cancel)
        switchUserSub?.onCompleted()
    }
}

