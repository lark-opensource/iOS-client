//
//  V3RecoverAccountBankViewModel.swift
//  AnimatedTabBar
//
//  Created by tangyunfei.tyf on 2020/7/22.
//

import Foundation
import RxSwift
import LKCommonsLogging

class V3RecoverAccountBankViewModel: V3ViewModel {
    private let logger = Logger.plog(V3RecoverAccountBankViewModel.self, category: "SuiteLogin.V3RecoverAccountBankViewModel")

    private let api: RecoverAccountAPIProtocol
    var bankCardNumber: String?
    var vanillaMobileNumber: String?
    var mobileNumber: String? {
        get {
            if let vanillaMobileNumber = vanillaMobileNumber {
                return CommonConst.chinaRegionCode + vanillaMobileNumber
            } else {
                return nil
            }
        }

        set {
            vanillaMobileNumber = newValue
        }
    }

    let title: String
    let subTitle: String
    var subTitleInAttributedString: NSAttributedString {
        return AttributedStringUtil.attributedString(subTitle, value: self.name, placeholder: "{{user_name}}")
    }
    let name: String
    let rsaInfo: RSAInfo
    let from: RecoverAccountSourceType

    init(
        step: String,
        api: RecoverAccountAPIProtocol,
        recoverAccountBankInfo: V3RecoverAccountBankInfo,
        from: RecoverAccountSourceType,
        context: UniContextProtocol
    ) {
        self.api = api
        self.title = recoverAccountBankInfo.title ?? ""
        self.subTitle = recoverAccountBankInfo.subTitle ?? ""
        self.name = recoverAccountBankInfo.name ?? ""
        self.rsaInfo = recoverAccountBankInfo.rsaInfo
        self.from = from
        super.init(step: step, stepInfo: recoverAccountBankInfo, context: context)
    }

    func isNextButtonEnabled() -> Bool {
        return self.isBankCardNumberValid() && self.isMobileNumberValid()
    }

    private func isBankCardNumberValid() -> Bool {
        if let bankCardNumber = self.bankCardNumber {
            return bankCardNumber.isEmpty ? false: true
        }
        return false
    }

    private func isMobileNumberValid() -> Bool {
        if let vanillaMobileNumber = self.vanillaMobileNumber {
            return vanillaMobileNumber.isEmpty ? false: true
        }
        return false
    }

    func onNextButtonClicked() -> Observable<Void> {
        self.logger.info("recover account with bank info")
        guard let bankCardNumber = self.bankCardNumber,
            let mobileNumber = self.mobileNumber else {
            return .error(V3LoginError.badLocalData("bankCardNumber or mobileNumber invalid"))
        }
        return api
            .verifyBank(
                bankCardNumber: bankCardNumber,
                mobileNumber: mobileNumber,
                rsaInfo: self.rsaInfo,
                sceneInfo: nil,
                context: context
            )
            .post([
                "from": self.from.rawValue
            ], context: context)
    }
}
