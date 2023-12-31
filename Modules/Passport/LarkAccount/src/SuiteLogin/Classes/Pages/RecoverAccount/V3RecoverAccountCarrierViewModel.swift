//
//  V3RecoverAccountCarrierViewModel.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/7/21.
//

import Foundation
import RxSwift
import LKCommonsLogging

protocol RecoverAccountAPIProtocol {

    func verifyCarrier(
        name: String,
        identityNumber: String,
        sourceType: Int,
        rsaInfo: RSAInfo,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step>

    func verifyBank(
        bankCardNumber: String,
        mobileNumber: String,
        rsaInfo: RSAInfo,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step>

    func verifyNewCredential(
        mobileNumber: String,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step>

    func notifyFaceVerifySuccsss(
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step>

    func refreshVerifyFaceTicket(
        sceneInfo: [String: String]?,
        context: UniContextProtocol,
        success: @escaping OnSimpleResponseSuccessV3,
        failure: @escaping OnFailureV3
    )
}

class V3RecoverAccountCarrierViewModel: V3ViewModel {
    private let logger = Logger.plog(V3RecoverAccountCarrierViewModel.self, category: "SuiteLogin.V3RecoverAccountCarrierViewModel")

    private let api: RecoverAccountAPIProtocol
    var name: String?
    var identityNumber: String?
    let title: String
    let subTitle: String
    var subTitleInAttributedString: NSAttributedString {
        self.attributedString(for: subTitle)
    }
    let sourceType: Int
    let from: RecoverAccountSourceType
    let rsaInfo: RSAInfo
    let appealUrl: String?
    let switchUserSub: PublishSubject<SwitchUserStatus>?

    init(
        step: String,
        api: RecoverAccountAPIProtocol,
        recoverAccountCarrierInfo: V3RecoverAccountCarrierInfo,
        from: RecoverAccountSourceType,
        context: UniContextProtocol,
        switchUserSub: PublishSubject<SwitchUserStatus>? = nil
    ) {
        self.api = api
        self.title = recoverAccountCarrierInfo.title ?? ""
        self.subTitle = recoverAccountCarrierInfo.subTitle ?? ""
        self.sourceType = recoverAccountCarrierInfo.sourceType ?? 0
        self.appealUrl = recoverAccountCarrierInfo.appealUrl
        self.from = from
        self.rsaInfo = recoverAccountCarrierInfo.rsaInfo
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
        self.logger.info("recover account on next button")
        guard let name = self.name,
            let identityNumber = self.identityNumber else {
            return .error(V3LoginError.badLocalData("name or identifyNumber invalid"))
        }

        return api.verifyCarrier(
                name: name,
                identityNumber: identityNumber,
                sourceType: self.sourceType,
                rsaInfo: self.rsaInfo,
                sceneInfo: nil,
                context: context
            )
            .post([
                "name": name,
                "identity_number": identityNumber,
                "from": from.rawValue
            ], context: context)
    }

    override func clickClose() {
        V3ViewModel.logger.info("send cancel")
        switchUserSub?.onNext(.cancel)
        switchUserSub?.onCompleted()
    }
}
