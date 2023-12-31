//
//  ProviderManager.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/6/6.
//

import Foundation
import LarkContainer

var Provider: ProviderManager {
    return ProviderManager.default
}

public final class ProviderManager {

    public static let `default` = ProviderManager()

    private var providerFactories = ThreadSafeDictionary<ProviderKey, ProviderEntryProtocol>()

    @MailProvider var badgeProvider: BadgeProxy?

    @MailProvider var imageProvider: ImageProxy?

    @MailProvider var trackProvider: TrackProxy?

    @MailProvider var commonSettingProvider: CommonSettingProxy?

    @MailProvider var timeFormatProvider: TimeFormatProxy?
}

// 用于注册工厂方法。实现懒加载
extension ProviderManager {
    public func hasRegister<Proxy>(type: Proxy.Type) -> Bool {
        let key = ProviderKey(serviceType: Proxy.self)
        if let _ = providerFactories[key] {
            return true
        }
        return false
    }

    @discardableResult
    public func register<Proxy>(
        _ serviceType: Proxy.Type,
        factory: @escaping () -> Proxy?
        ) -> ProviderEntry<Proxy> {
        return _register(serviceType, factory: factory)
    }

    @discardableResult
    private func _register<Proxy>(
        _ serviceType: Proxy.Type,
        factory: @escaping () -> Any?
        ) -> ProviderEntry<Proxy> {
        let key = ProviderKey(serviceType: Proxy.self)
        let entry = ProviderEntry<Proxy>(
            serviceType: serviceType,
            factory: factory
        )
        providerFactories[key] = entry
        return entry
    }

    @discardableResult
    func lazyLoadProvider<Proxy> (type: Proxy.Type) -> Proxy? {
        let key = ProviderKey(serviceType: Proxy.self)
        if let entry = providerFactories[key] {
            let factory = entry.factory as! () -> Any?
            return factory() as? Proxy
        } else {
            return nil
        }
    }
}
