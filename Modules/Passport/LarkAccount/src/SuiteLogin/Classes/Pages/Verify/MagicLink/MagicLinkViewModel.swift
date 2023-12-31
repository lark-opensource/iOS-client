//
//  MagicLinkViewModel.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/8/3.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer

struct MailApp {

    let name: String
    let url: URL

    // swiftlint:disable ForceUnwrapping
    static let apple: MailApp = MailApp(
        name: I18N.Lark_Login_MagicLinkOpenMailListMail,
        url: URL(string: "message://")!)

    static let google: MailApp = MailApp(
        name: I18N.Lark_Login_MagicLinkOpenMailListGmail,
        url: URL(string: "googlegmail://")!)

    static let yahoo: MailApp = MailApp(
        name: I18N.Lark_Login_MagicLinkOpenMailListYahoo,
        url: URL(string: "ymail://")!)

    static let microsoft: MailApp = MailApp(
        name: I18N.Lark_Login_MagicLinkOpenMailListOutlook,
        url: URL(string: "ms-outlook://")!)
    // swiftlint:enable ForceUnwrapping
}

class MagicLinkViewModel: V3ViewModel {

    let magicLinkInfo: V3MagicLinkInfo
    let expire: BehaviorRelay<uint> = BehaviorRelay(value: 60)

    @Provider var api: LoginAPI

    init(
        stepInfo: V3MagicLinkInfo,
        context: UniContextProtocol
    ) {
        self.magicLinkInfo = stepInfo
        super.init(
            step: PassportStep.magicLink.rawValue,
            stepInfo: stepInfo,
            context: context
        )
    }

    var titleString: String { magicLinkInfo.title }

    var subTitleString: NSAttributedString {
        let para = NSMutableParagraphStyle()
        para.lineSpacing = 2
        para.alignment = .center
        return V3LoginVerifyViewModel.attributedString(
            magicLinkInfo.subtitle,
            magicLinkInfo.contact,
            paraStyle: para
        )
    }

    var remindTip: String { magicLinkInfo.tip ?? "" }

    lazy var avaliableMailApps: [MailApp] = {
        generateAvalialbeMailApp()
    }()

    lazy var mailWebURL: URL? = {
        if let url = makeMailWebURL(magicLinkInfo.contact),
            UIApplication.shared.canOpenURL(url) {
            return url
        } else {
            return nil
        }
    }()

    private var runningRequest: LoginRequest<V3.Step>?

    func verifyPolling(apiSuccess: @escaping () -> Void) -> Observable<Void> {
        return Observable.create { (observer) -> Disposable in
            func pollingWork() {
                self.runningRequest?.cancelTask()
                self.runningRequest = self.api.verifyPolling(success: { (step, info) in
                    apiSuccess()
                    self.post(
                        event: step,
                        stepInfo: info,
                        success: {
                            observer.onNext(())
                            observer.onCompleted()
                        }) { (error) in
                            observer.onError(error)
                    }
                }) { (error) in
                    if case .badServerCode(let info) = error, info.type == .linkIsWaitingForClick {
                        MagicLinkViewModel.logger.info("verify polling timeout retry")
                        pollingWork()
                    } else {
                        observer.onError(error)
                    }
                }
            }
            pollingWork()
            return Disposables.create()
        }
    }

    func sendMagicLink() -> Observable<Void> {
        return api.applyCode(
                codeType: .link,
                sourceType: magicLinkInfo.sourceType,
                context: context
            )
            .map({ _ in })
            .catchError { (error) -> Observable<()> in
                if let err = error as? V3LoginError, case .badServerCode(let info) = err,
                    info.type == .applyCodeTooOften,
                    let exp = info.detail[V3.Const.expire] as? uint {
                    self.expire.accept(exp)
                    return .just(())
                } else {
                    return .error(error)
                }
            }
    }

    private func makeMailWebURL(_ email: String) -> URL? {
        if let domain = email.split(separator: "@").last {
            if let urlString = service.config.suffixEmailMap?[String(domain)] {
                return URL(string: urlString)
            } else {
                MagicLinkViewModel.logger.error("not found domain: \(domain) in suffix email map")
            }
        } else {
            MagicLinkViewModel.logger.error("email address format error: \(email)")
        }
        return nil
    }

    private func generateAvalialbeMailApp() -> [MailApp] {
        var apps: [MailApp] = []
        let allApp: [MailApp] = [.apple, .google, .yahoo, .microsoft]
        allApp.forEach { (app) in
            if UIApplication.shared.canOpenURL(app.url) {
                apps.append(app)
            } else {
                Self.logger.info("email link can not open: \(app.url)")
            }
        }
        return apps
    }

    func stopPolling() {
        runningRequest?.cancelTask()
    }
}
