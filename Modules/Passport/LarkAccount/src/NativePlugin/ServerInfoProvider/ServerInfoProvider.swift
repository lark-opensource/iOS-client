//
//  ServerInfoProvider.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/4.
//

import Foundation
import LKCommonsLogging
import LarkAccountInterface
import RxSwift
import LarkEnv
import LarkSetting

class ServerInfoProvider: DomainProviderProtocol, URLProviderProtocol {

    static let logger = Logger.plog(ServerInfoProvider.self, category: "SuiteLogin.ServerInfoProvider")

    var domainProviders: [DomainProviderProtocol] {
        DomainProviderRegistry.providers
    }
    var urlProviders: [URLProviderProtocol] {
        URLProviderRegistry.providers
    }

    private let disposeBag = DisposeBag()

    func getDomain(_ key: DomainAliasKey) -> DomainValue {
        for provider in domainProviders {
            let domainVal = provider.getDomain(key)
            if domainVal.value != nil {
                Self.logger.info("n_action_domain_found_from_DOMAIN_provider",
                                 additionalData: ["value": domainVal.description],
                                 method: .local)
                return domainVal
            }
        }
        Self.logger.error("n_action_domain_not_found_from_DOMAIN_provider", additionalData: ["key": "\(key)"])
        return .init(value: nil, provider: .notFound)
    }

    func getUrl(_ key: URLKey) -> URLValue {
        for provider in urlProviders {
            let urlVal = provider.getUrl(key)
            if urlVal.value != nil {
                Self.logger.info("n_action_domain_found_from_URL_provider",
                                 additionalData: ["value": urlVal.description],
                                 method: .local)
                return urlVal
            }
        }
        Self.logger.error("n_action_domain_not_found_from_URL_provider", additionalData: ["key": "\(key)"])
        return .init(value: nil, provider: .notFound)
    }

    func asyncGetDomain(_ env: Env, brand: String, key: DomainAliasKey, completionHandler: @escaping (DomainValue) -> Void) {

        //concatMap 顺序执行数组里面的元素
        //timeout 30s超时
        //take(1) 只取第一个（数组已经按优先级排序过）
        //asSingle 有一个元素的情况下触发onSuccess，没有或是多个会触发onError
        Observable.from(domainProviders)
            .concatMap { provider -> Observable<DomainValue> in
                Observable<DomainValue>.create { (ob) -> Disposable in
                    provider.asyncGetDomain(env, brand: brand, key: key) { domainValue in
                        ob.onNext(domainValue)
                        ob.onCompleted()
                    }
                    return Disposables.create()
                }
            }.filter({ domainValue in
                domainValue.value != nil
            })
            .timeout(.seconds(30), scheduler: MainScheduler.instance)
            .take(1)
            .asSingle()
            .subscribe(onSuccess: { domainValue in
                completionHandler(domainValue)
            }, onError: { error in
                completionHandler(.init(value: nil, provider: .notFound))
            }).disposed(by: disposeBag)
    }

}

extension ServerInfoProvider {
    static func transformToLarkSettingKey(_ key: DomainAliasKey) -> LarkSetting.DomainKey? {
        switch  key {
        case .api:
            return .api
        case .apiUsingPackageDomain:
            return nil
        case .passportAccounts:
            return .passportAccounts
        case .passportAccountsUsingPackageDomain:
            return nil
        case .ttGraylog:
            return .ttGraylog
        case .privacy:
            return .privacy
        case .device:
            return .device
        case .ttApplog:
            return .ttApplog
        case .passportTuring:
            return .passportTuring
        case .passportTuringUsingPackageDomain:
            return nil
        case .privacyUsingPackageDomain:
            return nil
        case .ttApplogUsingPackageDomain:
            return nil
        case .open:
            return .openMG
        }
    }
}
