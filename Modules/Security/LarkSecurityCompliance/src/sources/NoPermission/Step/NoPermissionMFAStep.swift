//
//  NoPermissionMFAStep.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/20.
//

import Foundation
import LarkContainer
import LarkAccountInterface
import RxSwift
import RxCocoa
import LarkSecurityComplianceInfra
import LarkUIKit

private let mfaScope = "scs-mfa-verify"

final class NoPermissionMFAStep: NoPermissionBaseStep {

    let padDismissCallback = PublishRelay<Void>()

    required init(resolver: UserResolver, context: NoPermissionStepContext) throws {
        try super.init(resolver: resolver, context: context)

        var mfaService = try resolver.resolve(assert: AccountServiceMFA.self) // Global
        mfaService.dismissCallback = { [weak self] in
            self?.padDismissCallback.accept(())
        }

        let mfaStatusChecker = Observable.merge([viewDidAppear.skip(1),
                                                 padDismissCallback.filter { !Display.phone },
                                                 retryButtonClicked])
            .flatMapLatest { [weak self] () -> Observable<Bool> in
                guard let stepCheck = self?.check() else { return .just(false) }
                self?.nextButtonLoading.onNext(true)
                return stepCheck
                    .debug()
                    .catchErrorJustReturn(false)
                    .do { [weak self] _ in
                        self?.nextButtonLoading.onNext(false)
                    }
            }
        mfaStatusChecker
            .debug()
            .filter { $0 }
            .mapToVoid()
            .bind(to: refreshWithAnimationFromStep)
            .disposed(by: bag)
    }

    override func next() {
        guard let from = context.from?.fromViewController else { return }
        let token = context.model.model?.params?["mfa-token"]?.stringValue ?? ""
        let unit = context.model.model?.params?["unit"]?.stringValue
        let mfaService = try? resolver.resolve(assert: AccountServiceMFA.self) // Global
        mfaService?.startMFA(token: token, scope: mfaScope, unit: unit, from: from) {
            Logger.info("start MFA success")
        } onError: { aErr in
            Logger.error("MFA faild with error: \(aErr)")
            SCMonitor.error(business: .no_permission,
                            eventName: "start_mfa",
                            error: aErr,
                            extra: ["token": token,
                                    "scope": mfaScope,
                                    "unit": unit ?? ""])
        }

    }

    func check() -> Observable<Bool>? {
        let token = context.model.model?.params?["mfa-token"]?.stringValue
        let unit = context.model.model?.params?["unit"]?.stringValue
        let mfaService = try? resolver.resolve(assert: AccountServiceMFA.self) // Global
        return Observable.create { observer in
            guard let aToken = token  else {
                Logger.info("MFA completed")
                observer.onCompleted()
                return Disposables.create()
            }
            mfaService?.checkMFAStatus(token: aToken, scope: mfaScope, unit: unit) { status in
                observer.onNext(status == .authed)
                Logger.info("check MFA success, status: \(status)")
                observer.onCompleted()
            } onError: { err in
                Logger.error("MFA error: \(err)")
                SCMonitor.error(business: .no_permission,
                                eventName: "mfa_check_status",
                                error: err,
                                extra: ["token": aToken,
                                        "scope": mfaScope,
                                        "unit": unit ?? ""])
                observer.onError(err)
            }

            return Disposables.create()
        }
    }

    // MARK: - UI

    override var nextTitle: String { I18N.Lark_Conditions_GoVerifyNow }
    override var detailTitle: String { "" }
    override var detailSubtitle: String { "" }
    override var emptyDetail: String { I18N.Lark_Conditions_ThisWay }

    override var nextHidden: Bool { return false }
    override var reasonDetailHidden: Bool { return true }
    override var refreshTop: NoPermissionLayout.Refresh { .init(top: 16, align: .next) }
    override var nextTop: NoPermissionLayout.Next { .init(top: 24, align: .empty) }
}
