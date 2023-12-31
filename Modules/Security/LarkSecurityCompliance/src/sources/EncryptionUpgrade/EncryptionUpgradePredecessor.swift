//
//  EncryptionUpgradePredecessor.swift
//  LarkSecurityCompliance
//
//  Created by AlbertSun on 2023/5/21.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa
import LarkTracker
import LarkSetting
import LarkAccountInterface
import LarkSecurityComplianceInfra

protocol EncryptionUpgradePredecessorProtocol {
    func process()
    func updateUserList()
}

final class EncryptionUpgradePredecessor: UserResolverWrapper {

    let userResolver: UserResolver
    private let disposeBag = DisposeBag()

    @Provider private var passportService: PassportService // Global
    @Provider private var encryptionUpgradeService: EncryptionUpgradeService // Global

    private let fgObserver: Observable<Void> // Global
    private let scFGservice: SCFGService
    private var shouldRekey: Bool {
        EncryptionUpgradeStorage.shared.shouldRekey
    }
    private var eta: Int = 0
    private var userList = Set<String>()

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        self.scFGservice = try userResolver.resolve(assert: SCFGService.self)
        fgObserver = Self.getEncryptionUpgradeObservre(userResolver: userResolver)
        Logger.info("predecessor init")
        self.bindSignals()
    }

    private static func getEncryptionUpgradeObservre(userResolver: UserResolver) -> Observable<Void> {
        guard let settings = try? userResolver.resolve(assert: Settings.self),
              settings.enableSecuritySettingsV2.isTrue else {
            SCLogger.info("getEncryptionUpgradeObservre", tag: SettingsImp.logTag)
            return FeatureGatingManager.realTimeManager.fgObservable // Global
        }
        do {
            let service = try userResolver.resolve(assert: SCFGService.self)
            SCLogger.info("getEncryptionUpgradeObservre", tag: SCSetting.logTag)
            return service.observe(.encryptionUpgrade).mapToVoid()
        } catch {
            SCLogger.error("SCSettingsService resolve error \(error)")
            return FeatureGatingManager.realTimeManager.fgObservable // Global
        }
    }

    private func bindSignals() {
        // observe setting
        fgObserver.subscribe(onNext: { [weak self] in
            guard let self else { return }
            Logger.info("fgObserver receive fg update")
            self.process()
        }).disposed(by: disposeBag)
    }

    private func updateRekeyNecessity() {
        // 是否已经升级
        let isUpgraded = EncryptionUpgradeStorage.shared.isUpgraded
        if isUpgraded {
            Logger.info("database is rekeyed, no need to upgrade")
            recordShouldRekey(false)
            return
        }
        do {
            // db是否已经使用新密钥
            let precheckResult = try encryptionUpgradeService.isRekeyNeeded()
            Logger.info("rust check needUpgrade:\(precheckResult)")
            if precheckResult.needUpgrade {
                // 使用旧密钥，记录需要升级
                recordShouldRekey(true)
                EncryptionUpgradeStorage.shared.updateEta(value: precheckResult.eta)
                // 更新本地侧边栏用户
                updateUserList()
            } else {
                recordShouldRekey(false)
            }
        } catch {
            Logger.error("rust check isRekeyNeeded error:\(error)")
            SCMonitor.error(business: .encryption_upgrade, eventName: "precheck", error: error)
            recordShouldRekey(false)
        }
    }

    private func recordShouldRekey(_ rekeyNeeded: Bool) {
        EncryptionUpgradeStorage.shared.updateShouldRekey(value: rekeyNeeded)
    }
}

extension EncryptionUpgradePredecessor: EncryptionUpgradePredecessorProtocol {
    func process() {
        Logger.info("predecessor process")
        let shouldRekeyOnNextLaunch = scFGservice.realtimeValue(SCFGKey.encryptionUpgrade)
        Logger.info("observe latest fg:\(shouldRekeyOnNextLaunch)")

        guard shouldRekeyOnNextLaunch != shouldRekey else { return }

        if shouldRekeyOnNextLaunch {
            updateRekeyNecessity()
        } else {
            recordShouldRekey(false)
        }
    }

    func updateUserList() {
        Logger.info("update user list count before:\(userList.count)")
        let currentUserList = Set(passportService.userList.map({ $0.userID }))
        userList = userList.union(currentUserList)
        Logger.info("update user list count after:\(userList.count)")
        EncryptionUpgradeStorage.shared.updateUserList(value: Array(userList))
    }
}
