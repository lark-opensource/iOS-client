//
//  V3EnterpriseLoginViewModel.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2020/2/10.
//

import Foundation
import RxSwift
import Homeric
import LarkLocalizations
import LarkContainer
import ECOProbeMeta

class V3EnterpriseLoginViewModel: V3ViewModel {

    let ssoDomains: [String]
    
    let supportedSSODomains: [String]

    var defaultDomain: String

    let ssoHelpUrl: [String: String]?

    let disposeBag: DisposeBag = DisposeBag()

    let enterpriseInfo: V3EnterpriseInfo

    @Provider var idpService: IDPServiceProtocol

    init(
        step: String,
        enterpriseInfo: V3EnterpriseInfo,
        defaultDomain: String,
        ssoDomains: [String],
        supportedSSODomains: [String],
        ssoHelpUrl: [String: String]?,
        context: UniContextProtocol
    ) {
        self.defaultDomain = defaultDomain
        self.ssoDomains = ssoDomains
        self.supportedSSODomains = supportedSSODomains
        self.ssoHelpUrl = ssoHelpUrl
        self.enterpriseInfo = enterpriseInfo
        super.init(
            step: step,
            stepInfo: enterpriseInfo,
            context: context
        )
    }

    /// alias for enterpise
    var prefixAlias: String = ""
    /// suffix domain e.g.,  ".feishu.cn", ".larksuite.com"
    var suffixDomain: String = ""
    /// full domain,  format:  "${aliasPrefix}${suffixDomain}"
    var enterpiseSSODomain: String = ""

    func idp(sceneInfo: [String: String]) -> Observable<Void> {
        if enterpriseInfo.isAddCredential {
            return service.credentialAPI
                .addNewIdpCredential(channel: nil, domain: self.enterpiseSSODomain, sceneInfo: sceneInfo)
                .post(false, context: self.context)
        } else {
            let prefixAliasMD5 = prefixAlias.isEmpty ? CommonConst.empty : genMD5(prefixAlias, salt: nil)
            let suffix = suffixDomain.isEmpty ? CommonConst.empty : suffixDomain
            V3ViewModel.logger.info("idp login start prefixAliasMD5: \(prefixAliasMD5) suffixDomain: \(suffix)")
            guard SuiteLoginUtil.isNetworkEnable() else {
                return .error(V3LoginError.networkNotReachable(true))
            }
            PassportMonitor.flush(PassportMonitorMetaLogin.startIdpLoginPrepare,
                                    eventName: ProbeConst.monitorEventName,
                                    categoryValueMap: [ProbeConst.channel: ProbeConst.idpEnterprise],
                                    context: self.context)
            ProbeDurationHelper.startDuration(ProbeDurationHelper.loginIdpPrepareFlow)
            let body = SSOUrlReqBody(
                idpName: self.enterpiseSSODomain,
                sceneInfo: sceneInfo,
                context: context
            )
            return idpService
                .fetchConfigForIDP(body)
                .do(onNext: { [weak self] step in
                    guard let self = self else { return }
                    let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.loginIdpPrepareFlow)
                    PassportMonitor.monitor(PassportMonitorMetaLogin.idpLoginPrepareResult,
                                            eventName: ProbeConst.monitorEventName,
                                            categoryValueMap: [ProbeConst.duration: duration, ProbeConst.channel: ProbeConst.idpEnterprise],
                                            context: self.context)
                    .setResultTypeSuccess()
                    .flush()
                    PassportMonitor.flush(EPMClientPassportMonitorLoginCode.idp_b_login_auth_url_request_succ,
                                          categoryValueMap: ["next_step" : step.stepData.nextStep],
                                          context: self.context)
                }, onError: { error in
                    let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.loginIdpPrepareFlow)
                    PassportMonitor.monitor(PassportMonitorMetaLogin.idpLoginPrepareResult,
                                            eventName: ProbeConst.monitorEventName,
                                            categoryValueMap: [ProbeConst.duration: duration, ProbeConst.channel: ProbeConst.idpEnterprise],
                                            context: self.context)
                    .setResultTypeFail()
                    .setPassportErrorParams(error: error)
                    .flush()
                })
                .post(false, context: context)
                .do(onNext: { [weak self] in
                    guard let self = self else { return }
                    V3ViewModel.logger.info("idp login save prefixAliasMD5: \(prefixAliasMD5) suffixDomain: \(suffix)")
                    self.service.store.ssoPrefix = self.prefixAlias
                    self.service.store.ssoSuffix = self.suffixDomain
                })
        }
    }
}

extension V3EnterpriseLoginViewModel {

    var title: String {
        if enterpriseInfo.isAddCredential {
            return I18N.Lark_Login_V3_SSO_Intro_Title
        } else {
            return I18N.Lark_Login_IdP_title
        }
    }

    var subtitle: NSAttributedString {
        if enterpriseInfo.isAddCredential {
            return V3LoginVerifyViewModel.defaultAttributedString(I18N.Lark_Login_V3_SSO_Intro_Detail)
        } else {
            return V3LoginVerifyViewModel.defaultAttributedString(I18N.Lark_Login_IdP_subtitle)
        }
    }

    var pageName: String {
        return Homeric.IDP_LOGIN_PAGEVIEW
    }

    var multipleSelection: Bool { false }

    var needTipButton: Bool { helpUrl != nil }

    var helpUrl: URL? {
        var urlStr: String?

        SuiteLoginUtil.currentLanguage(action: { (current) -> Bool in
            urlStr = ssoHelpUrl?[current.localeIdentifier]
            return urlStr != nil
        }) { (fallback) in
            urlStr = ssoHelpUrl?[fallback.localeIdentifier]
        }

        guard let urlString = urlStr else {
            V3ViewModel.logger.info("not found url for lan: \(LanguageManager.currentLanguage.localeIdentifier) ssoHelpUrl: \(String(describing: ssoHelpUrl))")
            return nil
        }
        guard let url = URL(string: urlString) else {
            V3ViewModel.logger.info("invalid sso urlString: \(urlString)")
            return nil
        }
        return url
    }
}
