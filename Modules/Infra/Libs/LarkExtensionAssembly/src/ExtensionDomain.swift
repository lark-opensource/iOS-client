//
//  ExtensionDomain.swift
//  LarkExtensionAssembly
//
//  Created by 王元洵 on 2021/4/13.
//

import Foundation
import LarkSetting
import LarkExtensionServices
import LarkRustClient
import RxSwift
import RustPB
import LarkStorageCore
import LarkContainer
import LKCommonsLogging

enum ExtensionDomain {
    private static let disposeBag = DisposeBag()
    private static let queue = DispatchQueue(label: "com.extension.domainUpadteQueue")
    private static let serialScheduler = SerialDispatchQueueScheduler(queue: Self.queue, internalSerialQueueName: "com.extension.domainUpadteQueue.scheduler")
    private static let logger = Logger.log(ExtensionDomain.self, category: "ExtensionDomain")

    static func writeDomain(with push: DomainSetting? = nil) {
        guard let apiDomain = push?[.api] ?? DomainSettingManager.shared.currentSetting[.api] else { return }

        let domainSettingMap = ["gateway": apiDomain.map { "https://" + $0 + "/im/gateway/" }]
        KVPublic.SharedAppConfig.domainMap.setValue(domainSettingMap)

        if let tea = DomainSettingManager.shared.currentSetting["tt_tea"]?.first {
            var teaURL = tea
            if !teaURL.hasPrefix("http") {
                teaURL = "https://" + teaURL
            }
            if teaURL.hasSuffix("/") {
                teaURL += "service/2/app_log/"
            } else {
                teaURL += "/service/2/app_log/"
            }
            KVPublic.SharedAppConfig.applogUrl.setValue(teaURL)
        }
    }

    // 写入用户Domain
    static func updateUserDomain(of userID: String, with domains: DomainSetting) {
        let currentUserDomains = Self.toExtensionDomainsType(domains: domains)
        let userDomainStorage = UserDomainStorage(userID: userID)
        userDomainStorage.saveUserDomain(domains: currentUserDomains)
        Self.logger.debug("update user domain success, userID: \(userID)")
    }

    static func observePush(resolver: UserResolver) {
        // 前台账号Domain
        DomainSettingManager.shared.domainObservable.subscribe(onNext: {
            writeDomain(with: DomainSettingManager.shared.currentSetting)
        }).disposed(by: disposeBag)
    }

    static func observeUserDomainUpdate(userID: String) {
        asyncUpdateUserDomainOnce(userID: userID)
        guard let resolver = try? Container.shared.getUserResolver(userID: userID, type: .both)
        else { return }
        // 监听多用户Domain变更, 更新Domain
        if let userDomainService = try? resolver.resolve(assert: UserDomainService.self) {
            let userID = resolver.userID
            userDomainService
                .observeDomainSettingUpdate()
                .observeOn(Self.serialScheduler)
                .subscribe(onNext: { _ in
                    let domains = userDomainService.getDomainSetting()
                    Self.updateUserDomain(of: userID, with: domains)
                }).disposed(by: disposeBag)
        }
    }

    static func asyncUpdateUserDomainOnce(userID: String) {
        queue.async {
            guard let resolver = try? Container.shared.getUserResolver(userID: userID, type: .both)
            else { return }
            if let userDomainService = try? resolver.resolve(assert: UserDomainService.self) {
                Self.updateUserDomain(of: userID, with: userDomainService.getDomainSetting())
            }
        }
    }

    static func toExtensionDomainsType(domains: DomainSetting) -> [String: [String]] {
        return Dictionary(uniqueKeysWithValues: domains.map{ (key, value) -> (String, [String]) in return (key.rawValue, value)})
    }
}
