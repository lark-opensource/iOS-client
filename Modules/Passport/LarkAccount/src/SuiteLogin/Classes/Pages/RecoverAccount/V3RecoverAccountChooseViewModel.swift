//
//  V3RecoverAccountChooseViewModel.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/7/26.
//

import Foundation
import RxSwift
import LKCommonsLogging

class V3RecoverAccountChooseViewModel: V3ViewModel {
    private let logger = Logger.plog(V3RecoverAccountChooseViewModel.self, category: "SuiteLogin.V3RecoverAccountChooseViewModel")
    let disposeBag: DisposeBag = DisposeBag()
    private let api: RecoverAccountAPIProtocol
    let recoverAccountChooseInfo: V3RecoverAccountChooseInfo
    let title: String
    let subTitle: String
    let name: String
    let from: RecoverAccountSourceType
    let switchUserSub: PublishSubject<SwitchUserStatus>?

    init(
        step: String,
        api: RecoverAccountAPIProtocol,
        recoverAccountChooseInfo: V3RecoverAccountChooseInfo,
        from: RecoverAccountSourceType,
        context: UniContextProtocol,
        switchUserSub: PublishSubject<SwitchUserStatus>? = nil
    ) {
        self.api = api
        self.recoverAccountChooseInfo = recoverAccountChooseInfo
        self.title = recoverAccountChooseInfo.title ?? ""
        self.subTitle = recoverAccountChooseInfo.subTitle ?? ""
        self.name = recoverAccountChooseInfo.name ?? ""
        self.from = from
        self.switchUserSub = switchUserSub
        super.init(step: step, stepInfo: recoverAccountChooseInfo, context: context)
    }

    func onVerifyFaceButtonClicked() -> Observable<Void> {
        return recoverAccountVerifyFace()
    }

    func recoverAccountVerifyFace() -> Observable<Void> {
        guard let faceInfo = self.recoverAccountChooseInfo.verifyFaceInfo else {
            return .error(V3LoginError.badLocalData("no verifyFaceInfo"))
        }
        return Observable.create({ [weak self] (ob) -> Disposable in
            guard let self = self else { return Disposables.create() }

            self.logger.info("recover account with verify type: face")

            self.refreshTicket().subscribe(onNext: {
                self.post(
                    event: PassportStep.verifyFace.rawValue,
                    serverInfo: faceInfo,
                    additionalInfo: ["from": self.from.rawValue],
                    success: {
                        ob.onNext(())
                        ob.onCompleted()
                    }, error: { (error) in
                        ob.onError(error)
                })
            }, onError: { (error) in
                ob.onError(error)
            }).disposed(by: self.disposeBag)
            return Disposables.create()
        }).trace(
            "verifyFace",
            params: [
                CommonConst.sourceType: String(describing: recoverAccountChooseInfo.sourceType)
            ])
    }

    func refreshTicket() -> Observable<Void> {
        return Observable.create({ [weak self] (ob) -> Disposable in
            guard let self = self else { return Disposables.create() }

            self.api.refreshVerifyFaceTicket(
                sceneInfo: nil,
                context: self.context,
                success: { (simpleResponse) in
                    if simpleResponse.code != 0 {
                        self.logger.info("recover account refresh ticket failed")
                    } else {
                        if let data = simpleResponse.data,
                           let ticket = data["ticket"] as? String {
                            self.recoverAccountChooseInfo.verifyFaceInfo?.ticket = ticket
                        }
                    }
                    ob.onNext(())
                    ob.onCompleted()
                }, failure: { (error) in
                    self.logger.info("recover account refresh ticket failed")
                    ob.onError(error)
                })
            return Disposables.create()
        })
    }

    var buttonTitle: String {
        if let buttonTitle = recoverAccountChooseInfo.buttonTitle {
            return buttonTitle
        } else {
            return BundleI18n.suiteLogin.Lark_Login_RecoverAccountFaceVerifyFaceButton
        }
    }

    var bottomTitle: NSAttributedString {
        let string = attributedString(for: recoverAccountChooseInfo.bottomTitle, UIColor.ud.textPlaceholder)
        let attributedString = NSMutableAttributedString(attributedString: string)
        return attributedString
    }

    override func clickClose() {
        V3ViewModel.logger.info("send cancel")
        switchUserSub?.onNext(.cancel)
        switchUserSub?.onCompleted()
    }
}
