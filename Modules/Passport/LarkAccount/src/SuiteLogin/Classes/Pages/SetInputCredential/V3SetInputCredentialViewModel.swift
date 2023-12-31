//
//  V3SetInputCredentialViewModel.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/7/26.
//

import Foundation
import RxSwift
import LKCommonsLogging

class V3SetInputCredentialViewModel: V3ViewModel {
    private let logger = Logger.plog(V3SetInputCredentialViewModel.self, category: "SuiteLogin.V3SetInputCredentialViewModel")

    private let api: RecoverAccountAPIProtocol
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
        self.attributedString(for: subTitle)
    }
    var sourceType: Int?
    let from: RecoverAccountSourceType

    init(
        step: String,
        api: RecoverAccountAPIProtocol,
        setInputCredentialInfo: V3SetInputCredentialInfo,
        from: RecoverAccountSourceType,
        context: UniContextProtocol
    ) {
        self.api = api
        self.title = setInputCredentialInfo.title ?? ""
        self.subTitle = setInputCredentialInfo.subTitle ?? ""
        self.sourceType = setInputCredentialInfo.sourceType ?? 0
        self.from = from
        super.init(step: step, stepInfo: setInputCredentialInfo, context: context)
    }

    func isNextButtonEnabled() -> Bool {
        return self.isMobileNumberValid()
    }

    private func isMobileNumberValid() -> Bool {
        if let mobileNumber = self.mobileNumber {
            return mobileNumber.isEmpty ? false: true
        }
        return false
    }

    func onNextButtonClicked() -> Observable<Void> {
        self.logger.info("recover account with bank info")
        guard let mobileNumber = self.mobileNumber else {
            return .error(V3LoginError.badLocalData("bankCardNumber or mobileNumber invalid"))
        }
        return api
            .verifyNewCredential(
                mobileNumber: mobileNumber,
                sceneInfo: nil,
                context: context
            )
            .post(context: context)
    }
}
