//
//  ProviderEntry.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/6/24.
//

import Foundation

internal typealias FunctionType = Any

internal protocol ProviderEntryProtocol: AnyObject {
    var factory: FunctionType { get }
    var serviceType: Any.Type { get }
}

public final class ProviderEntry<Service>: ProviderEntryProtocol {

    internal let serviceType: Any.Type
    internal let factory: FunctionType

    internal init(serviceType: Service.Type, factory: FunctionType) {
        self.serviceType = serviceType
        self.factory = factory
    }
}
