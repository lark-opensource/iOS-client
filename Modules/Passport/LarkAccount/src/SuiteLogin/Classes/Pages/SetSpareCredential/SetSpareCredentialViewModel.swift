//
//  SetSpareCredentialViewModel.swift
//  LarkAccount
//
//  Created by au on 2022/6/2.
//

import Foundation
import LarkContainer
import LKCommonsLogging
import RxRelay
import RxSwift

protocol SetSpareCredentialAPIProtocol {
    func setSpareCredential(
        serverInfo: ServerInfo,
        credential: String,
        credentialType: Int,
        context: UniContextProtocol
    ) -> Observable<V3.Step>
}

class SetSpareCredentialViewModel: V3ViewModel {
    
    let setSpareCredentialInfo: SetSpareCredentialInfo
    
    @Provider var api: LoginAPI
    
    init(step: String,
         setSpareCredentialInfo: SetSpareCredentialInfo,
         context: UniContextProtocol) {
        self.setSpareCredentialInfo = setSpareCredentialInfo
        self.method = BehaviorRelay(value: .phoneNumber)
        if let item = setSpareCredentialInfo.credentialInputList.first {
            // 输入时的默认方式，以服务端返回的类型为准
            self.method.accept(item.credentialType.method)
        }
        
        super.init(step: step, stepInfo: setSpareCredentialInfo, context: context)
        
        self.credentialRegionCode = BehaviorRelay(value: service.configInfo.config().registerRegionCode(for: service.store.configEnv))
    }
    
    func clickNextButton() -> Observable<()> {
        Self.logger.info("n_action_set_spare_credential_click_next_button")
        return api
            .setSpareCredential(serverInfo: setSpareCredentialInfo,
                                credential: credential,
                                credentialType: method.value.toCredentialType(),
                                context: context)
            .post(context: context)
            .do(onNext: { [weak self] _ in
                guard let self = self else { return }
                Self.logger.info("n_action_set_spare_credential_post_apply_code")
            })
    }
    
    var flowType: String { setSpareCredentialInfo.flowType ?? "" }

    var title: String { setSpareCredentialInfo.title ?? "" }

    var subtitle: String { setSpareCredentialInfo.subtitle ?? "" }

    var nextButtonTitle: String? { setSpareCredentialInfo.nextButton?.text }

    var canChangeMethod: Bool { setSpareCredentialInfo.credentialInputList.count > 1 }
    
    var topCountryList: [String] { service.topCountryList }

    var blackCountryList: [String] { service.blackCountryList }
    
    var allowRegionList: [String] { [] }
    
    var blockRegionList: [String] { blackCountryList }
    
    var emailRegex: NSPredicate { NSPredicate(format: "SELF MATCHES %@", service.config.emailRegex) }
    
    var credentialInputList: [V4CredentialInputInfo] { setSpareCredentialInfo.credentialInputList }
    
    /// 手机区号
    var credentialRegionCode: BehaviorRelay<String> = BehaviorRelay(value: "")
    /// 手机号（不带区号） 155 5555 5555
    var credentialPhone: BehaviorRelay<String> = BehaviorRelay(value: "")
    /// 邮箱
    var credentialEmail: BehaviorRelay<String> = BehaviorRelay(value: "")
    
    var method: BehaviorRelay<SuiteLoginMethod>
    
    private var credential: String {
        switch method.value {
        case .email:
            return credentialEmail.value
        case .phoneNumber:
            return credentialRegionCode.value + credentialPhoneNoWhiteSpace
        }
    }
    
    private var credentialPhoneNoWhiteSpace: String {
        credentialPhone.value.replacingOccurrences(of: " ", with: "")
    }
}
