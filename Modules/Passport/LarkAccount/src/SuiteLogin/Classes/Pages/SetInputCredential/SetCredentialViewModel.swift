//
//  V3SetInputCredentialViewModel.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/7/26.
//

import Foundation
import RxSwift
import LKCommonsLogging
import LarkContainer
import LarkEnv
import LarkAccountInterface

class SetCredentialViewModel: V3ViewModel {

    var enableChangeRegionCode: Bool {
        return setCredentialInfo.allowRegionList?.count != 1
    }
    
    var topCountryList: [String] {
        return service.configInfo.config().topCountryList(for: V3ConfigEnv.lark)
    }

    var blackCountryList: [String] {
        return service.configInfo.config().blackCountryList(for: V3ConfigEnv.lark)
    }

    let regionCodeChangeable: Bool
    let ncCountryChangeable: Bool
    
    var ncCountryList: [String] {
        guard let countryCode = setCredentialInfo.countryCode, !countryCode.isEmpty else {
            return []
        }
        return [countryCode, CommonConst.chinaRegionCode]
    }
        
    var bottomTip: NSAttributedString {
        return NSAttributedString(string: setCredentialInfo.tip ?? "")
    }

    var title: String {
        setCredentialInfo.title
    }
    
    var subTitle: NSAttributedString {
        self.attributedString(for: setCredentialInfo.subtitle)
    }

    var btnTitle: String {
        I18N.Lark_Login_V3_NextStep
    }

    var credentialType: LoginCredentialType {
        switch setCredentialInfo.credentialType {
        case .phone: return .phone
        case .email: return .email
        }
    }

    let setCredentialInfo: SetCredentialInfo

    @Provider var api: LoginAPI

    init(
        setCredentialInfo: SetCredentialInfo,
        context: UniContextProtocol
    ) {
        self.setCredentialInfo = setCredentialInfo
        var ncCountryChangeable = false
        // MultiGeo updated
        if (setCredentialInfo.tenantBrand ?? "") == TenantBrand.feishu.rawValue {
            if let code = setCredentialInfo.countryCode,
               !code.isEmpty,
               setCredentialInfo.countryCode != CommonConst.chinaRegionCode {
                ncCountryChangeable = true
                regionCodeChangeable = true
            } else {
                regionCodeChangeable = false
            }
        } else {
            regionCodeChangeable = true
        }
        self.ncCountryChangeable = ncCountryChangeable
        super.init(step: PassportStep.setCredential.rawValue, stepInfo: setCredentialInfo, context: context)
    }

    func verifyCredential(_ credential: String) -> Observable<Void> {
        return api
            .retrieveSetCred(
                serverInfo: setCredentialInfo,
                newCred: credential,
                type: credentialType.rawValue,
                context: context)
            .post(context: context)
    }
}

extension SetCredentialViewModel{
    
    var emailRegex: NSPredicate {
        return NSPredicate(format: "SELF MATCHES %@", ".+@.+")
    }

    func isNextBtnDisableForEmail(currentText: String, range: NSRange, string: String) -> Bool {
        var text = currentText
        if let range = Range(range, in: text) {
            text.replaceSubrange(range, with: string)
        }
        return !emailRegex.evaluate(with: text)
    }

    func isNextBtnDisableForMobile(currentLength: Int, formatLength: Int, rangeLength: Int, stringLength: Int) -> Bool {
        return currentLength + stringLength - rangeLength < formatLength
    }
}
