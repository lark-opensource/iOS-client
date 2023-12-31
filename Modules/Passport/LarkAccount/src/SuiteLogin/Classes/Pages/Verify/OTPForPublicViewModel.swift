//
//  OTPForPublicViewModel.swift
//  LarkAccount
//
//  Created by tangyunfei.tyf on 2020/12/22.
//

import Foundation
import LKCommonsLogging
import RxSwift
import RxCocoa
import LarkAccountInterface
import LarkContainer

enum OTPVerifyError: Error {
    case noVerifyToken
    case badServerCode(Error)
}

class OTPForPublicViewModel: OTPVerifyViewModel {

    private let logger = Logger.plog(OTPForPublicViewModel.self)
    private let disposeBag = DisposeBag()
    private let sourceType = 9

    let verifyScope: VerifyScope
    let contact: String
    var title: String {
        return titleIn ?? BundleI18n.suiteLogin.Lark_Passport_PrivacySettings_BeforeChanging_Verication_Title
    }
    let titleIn: String?
    var subtitle: NSAttributedString {
        if let tipString = subtitleIn {
            return V3LoginVerifyViewModel.attributedString(tipString, contact)
        } else {
            return .tip(str: BundleI18n.suiteLogin.Lark_Passport_PrivacySettings_BeforeChanging_Verification_VerificationCodeSent(contact))
        }
    }
    let subtitleIn: String?
    let complete: (Result<VerifyToken, Error>) -> Void
    let expire: BehaviorRelay<uint> = BehaviorRelay(value: 60)

    @Provider var api: LoginAPI

    init(
        verifyScope: VerifyScope,
        contact: String,
        titleIn: String?,
        subtitleIn: String?,
        context: UniContextProtocol,
        complete: @escaping (Result<VerifyToken, Error>
    ) -> Void) {
        self.verifyScope = verifyScope
        self.contact = contact
        self.titleIn = titleIn
        self.subtitleIn = subtitleIn
        self.complete = complete
        super.init(
            step: "",
            stepInfo: PlaceholderServerInfo(),
            context: context
        )
    }

    func sendCode() -> Observable<Void> {
        return Observable.create { (ob) -> Disposable in
            self.api.applyCodeForPublic(
                sourceType: self.sourceType,
                contact: self.contact,
                verifyScope: self.verifyScope,
                context: self.context
            ).subscribe(onNext: { _ in
                ob.onNext(())
                ob.onCompleted()
            }, onError: { (error) in
                if let err = error as? V3LoginError,
                    case .badServerCode(let info) = err,
                        info.type == .applyCodeTooOften,
                        let exp = info.detail[V3.Const.expire] as? uint {
                        self.expire.accept(exp)
                        ob.onNext(())
                        ob.onCompleted()
                    } else {
                        ob.onError(error)
                    }
            }).disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }

    func verify(code: String) -> Observable<Void> {
        return api
            .verifyForPublic(sourceType: self.sourceType, code: code, sceneInfo: nil, context: context)
            .map { _ -> Void in
                guard let verifyToken = self.service.apiHelper.tokenManager.verifyToken else {
                    self.complete(.failure(OTPVerifyError.noVerifyToken))
                    return
                }
                self.complete(.success(verifyToken))
            }
    }

    func recoverTypeAccountRecover() -> Observable<Void> {
        Self.logger.errorWithAssertion("no impl")
        return .just(())
    }

}
