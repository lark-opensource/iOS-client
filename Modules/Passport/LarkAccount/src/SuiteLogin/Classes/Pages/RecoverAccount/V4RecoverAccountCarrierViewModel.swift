//
//  V3RecoverAccountCarrierViewModel.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/7/21.
//

import Foundation
import RxSwift
import Homeric
import LKCommonsLogging

protocol RetrieveAPIProtocol {

    func retrieveOpThree(
        serverInfo: ServerInfo,
        name: String,
        idNumber: String,
        rsaInfo: RSAInfo,
        context: UniContextProtocol
    ) -> Observable<V3.Step>
    
    func retrieveChooseIdentity(
        serverInfo: ServerInfo,
        userID: Int,
        tenant: String,
        context: UniContextProtocol
    ) -> Observable<V3.Step>
    
    func retrieveSetCred(
        serverInfo: ServerInfo,
        newCred: String,
        type: Int,
        context: UniContextProtocol
    ) -> Observable<V3.Step>
    
    func retrieveAppealGuide(
        token: String,
        type: String?,
        context: UniContextProtocol
    ) -> Observable<V3.Step>
}


class V4RecoverAccountCarrierViewModel: V3ViewModel {
    private let logger = Logger.log(V3RecoverAccountCarrierViewModel.self, category: "SuiteLogin.V3RecoverAccountCarrierViewModel")

    private let api: RetrieveAPIProtocol
    private let serverInfo: V4RetrieveOpThreeInfo
    
    var name: String?
    var identityNumber: String?
    
    var title: String{
        serverInfo.title ?? ""
    }
    
    var nameInputPlaceHolder: String{
        serverInfo.nameInputDeco?.placeholder ?? BundleI18n.suiteLogin.Lark_Login_RecoverAccountNamePlaceholder
    }
    
    var idInputPlaceHolder: String{
        serverInfo.idInputDeco?.placeholder ?? BundleI18n.suiteLogin.Lark_Login_RecoverAccountIDPlaceholder
    }
    
    var appealUrl: String?{
        serverInfo.appealUrl
    }

    var subTitleInAttributedString: NSAttributedString {
        self.attributedString(for: serverInfo.subTitle)
    }
    
    var policyPrefix: String {
        serverInfo.policyPrefix ?? I18N.Lark_Login_V3_RegisterTip()
    }
    
    var policyName: String {
        serverInfo.policyName ?? I18N.Lark_Login_V3_PrivacyPolicy
    }

    var policyDomain: String {
        serverInfo.policyDomain
    }
    
    let switchUserSub: PublishSubject<SwitchUserStatus>?

    init(
        step: String,
        api: RetrieveAPIProtocol,
        recoverAccountCarrierInfo: V4RetrieveOpThreeInfo,
        context: UniContextProtocol,
        switchUserSub: PublishSubject<SwitchUserStatus>? = nil
    ) {
        self.api = api
        self.serverInfo = recoverAccountCarrierInfo
        self.switchUserSub = switchUserSub
        super.init(step: step, stepInfo: recoverAccountCarrierInfo, context: context)
    }

    func isNextButtonEnabled() -> Bool {
        return self.isNameValid() && self.isIdentityNumberValid()
    }

    private func isNameValid() -> Bool {
        if let name = self.name {
            return name.isEmpty ? false: true
        }
        return false
    }

    private func isIdentityNumberValid() -> Bool {
        if let identityNumber = self.identityNumber {
            return identityNumber.isEmpty ? false: true
        }
        return false
    }
    
    func onNextButtonClicked() -> Observable<Void> {
        self.logger.info("recover account on next")
        guard let name = self.name,
            let identityNumber = self.identityNumber else {
            return .error(V3LoginError.badLocalData("name or identifyNumber invalid"))
        }
        
        return api.retrieveOpThree(
            serverInfo: serverInfo,
            name: name,
            idNumber: identityNumber,
            rsaInfo: RSAInfo.init(publicKey: serverInfo.rsaKey ?? "", token: serverInfo.rsaToken ?? ""),
            context: context)
            .do(onNext: { [weak self] nextStep in
                guard self != nil else { return }
                SuiteLoginTracker.track(Homeric.PASSPORT_ACCOUNT_FINDBACK_REALNAME_VERIFY_CLICK,
                                        params: ["click": "next",
                                                 "target": "none",
                                                 "verify_result": "success"
                                                ]
                )
            }, onError: { [weak self] error in
                guard self != nil else { return }
                SuiteLoginTracker.track(Homeric.PASSPORT_ACCOUNT_FINDBACK_REALNAME_VERIFY_CLICK,
                                        params: ["click": "next",
                                                 "target": "none",
                                                 "verify_result": "failed"
                                                ]
                )
            })
            .post([
                "name": name,
                "identity_number": identityNumber,
                CommonConst.closeAllStartPointKey: "true"
            ], context: context)
    }

    func policyTip() -> NSAttributedString {
        let font: UIFont = UIFont.systemFont(ofSize: 14.0)
        let res = I18N.Lark_Login_V3_registerNextStepPolicyTip(I18N.Lark_Passport_IdentityVerifyPolicy, I18N.Lark_Passport_FaceInfoRulesPolicy)
        let attributedString = NSMutableAttributedString.tip(str: res, color: UIColor.ud.textPlaceholder, font: font, aligment: .left)
        let termAttributed: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.primaryContentDefault,
            .link: Link.identityURL
        ]
        let privacyAttributed: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.primaryContentDefault,
            .link: Link.faceIdURL
        ]
        do {
            let rng = (res as NSString).range(of: I18N.Lark_Passport_IdentityVerifyPolicy)
            if rng.location != NSNotFound {
                attributedString.addAttributes(termAttributed, range: rng)
            }
        }
        do {
            let rng = (res as NSString).range(of: I18N.Lark_Passport_FaceInfoRulesPolicy)
            if rng.location != NSNotFound {
                attributedString.addAttributes(privacyAttributed, range: rng)
            }
        }
        return attributedString
    }

    override func clickClose() {
        V3ViewModel.logger.info("send cancel")
        switchUserSub?.onNext(.cancel)
        switchUserSub?.onCompleted()
    }
}
