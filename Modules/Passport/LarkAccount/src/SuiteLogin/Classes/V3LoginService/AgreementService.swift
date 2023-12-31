//
//  AgreementService.swift
//  LarkAccount
//
//  Created by bytedance on 2022/4/19.
//

import Foundation
import LarkAppConfig
import LKCommonsLogging
import LarkAccountInterface

class AgreementService: AccountServiceAgreement { // user:checked

    private let domainProvider = ServerInfoProvider()

    static let logger = Logger.plog(AgreementService.self, category: "SuiteLogin.AgreementService")

    func getAgreementURLWithPackageDomain(type: AgreementType) -> URL? {

        let domainValue = domainProvider.getDomain(.privacyUsingPackageDomain)

        let urlString: String
        let urlPath: String

        switch type {
        case .privacy:
            urlPath = PrivacyConfig.privacySuffix
        case .term:
            urlPath = PrivacyConfig.termsSuffix
        }

        guard let domain = domainValue.value, !urlPath.isEmpty else {
            Self.logger.error("n_action_agreement", body: "domain \(domainValue.value), suffix \(urlPath)")
            return nil
        }

        urlString = "\(CommonConst.prefixHTTPS)\(domain)\(urlPath)"

        //logger
        Self.logger.info("n_action_agreement", body: "urlString \(urlString)")

        return URL(string: urlString)
    }
}
