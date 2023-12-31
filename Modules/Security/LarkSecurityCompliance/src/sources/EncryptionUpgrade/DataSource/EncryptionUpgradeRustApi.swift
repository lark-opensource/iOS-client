//
//  EncryptionUpgradeRustApi.swift
//  LarkSecurityCompliance
//
//  Created by AlbertSun on 2023/5/15.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import RxSwift
import RxCocoa
import LarkSecurityComplianceInfra

typealias EncryptionUpgradePushResponse = Basic_V1_DatabaseUpgradePushResponse

final class EncryptionUpgradeRustApi {

    @Provider private var rustService: GlobalRustService

    func databaseRekeyExecuteSession() -> Observable<Void> {
        return Observable.create { [weak self] (observer) -> Disposable in
            // 等待rust sdk 初始化完成后进行升级command调用
            self?.rustService.wait { [weak self] in
                guard self != nil else {
                    observer.onError(LSCError.selfIsNil)
                    return
                }
#if DEBUG || ALPHA
                if EncryptionUpgradeStorage.shared.forceFailure {
                    Logger.info("mock rekey error")
                    observer.onError(NSError(domain: "scs_rekey_mock_fail", code: 0))
                    return
                }
#endif
                Logger.info("sdk init success")
                observer.onNext(())
                observer.onCompleted()
            }
            return Disposables.create()
        }
        .flatMap { [weak self] () -> Observable<Void> in
            guard let self else { return .just(()) }
            var request = Basic_V1_DatabaseUpgradeRequest()
            request.judgeOnly = false
            request.rekey = true
            request.userIds = EncryptionUpgradeStorage.shared.userList
            Logger.info("send async request on database upgrade with request:\(String(describing: request.description))")
            return self.rustService.sendAsyncRequest(request)
        }
    }

    func databaseRekeyPrecheck() throws -> PrecheckResult {
        var request = Basic_V1_DatabaseUpgradeRequest()
        request.judgeOnly = true
        request.rekey = true
        request.userIds = EncryptionUpgradeStorage.shared.userList
        Logger.info("send sync request on rekey precheck with request:\(request.description)")
        let response: Basic_V1_DatabaseUpgradeResponse = try rustService.sendSyncRequest(request)
        Logger.info("receive rekey precheck resp:\(response)")
        return PrecheckResult(needUpgrade: response.needUpgrade,
                              eta: max(Int(response.eta / 1000), 0))
    }

    func databaseRekeyProgressSession() -> Driver<EncryptionUpgrade.Progress> {
        let response: Observable<EncryptionUpgradePushResponse> = SimpleRustClient.global.register(pushCmd: .databaseUpgradePush)
        Logger.info("observe rust push")
        return response.map {
            EncryptionUpgrade.Progress(percentage: Int($0.progress),
                                       eta: max(Int($0.eta / 1000), 0))
        }.asDriverOnErrorJustComplete()
    }
}

extension Basic_V1_DatabaseUpgradeRequest: CustomStringConvertible {
    public var description: String {
        "judgeOnly:\(judgeOnly), rekey:\(rekey), userListLength:\(userIds.count)"
    }
}
