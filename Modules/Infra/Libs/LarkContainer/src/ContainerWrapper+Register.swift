//
//  ContainerWrapper+Register.swift
//  Swinject
//
//  Created by SolaWing on 2022/7/13.
//
// NOTICE:
//
// Do NOT modify the generate swift file directly.
// Instead, modify erb file and run `script/gencode` at the project root directory to generate the code.
//


import Foundation
import Swinject

// swiftlint:disable all
public extension ContainerWithScope where ResolverType == UserResolver {

    @discardableResult
    func register<Service>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: {(r: Resolver) throws -> Service in
            return try factory(r.asUserResolver())
        })
    }

    @discardableResult
    func register<Service, Arg1>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType, Arg1) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: {(a: (Resolver, Arg1)) throws -> Service in
            return try factory(a.0.asUserResolver(), a.1)
        })
    }

    @discardableResult
    func register<Service, Arg1, Arg2>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType, Arg1, Arg2) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: {(a: (Resolver, Arg1, Arg2)) throws -> Service in
            return try factory(a.0.asUserResolver(), a.1, a.2)
        })
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType, Arg1, Arg2, Arg3) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: {(a: (Resolver, Arg1, Arg2, Arg3)) throws -> Service in
            return try factory(a.0.asUserResolver(), a.1, a.2, a.3)
        })
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType, Arg1, Arg2, Arg3, Arg4) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: {(a: (Resolver, Arg1, Arg2, Arg3, Arg4)) throws -> Service in
            return try factory(a.0.asUserResolver(), a.1, a.2, a.3, a.4)
        })
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4, Arg5>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType, Arg1, Arg2, Arg3, Arg4, Arg5) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: {(a: (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5)) throws -> Service in
            return try factory(a.0.asUserResolver(), a.1, a.2, a.3, a.4, a.5)
        })
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: {(a: (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6)) throws -> Service in
            return try factory(a.0.asUserResolver(), a.1, a.2, a.3, a.4, a.5, a.6)
        })
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: {(a: (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7)) throws -> Service in
            return try factory(a.0.asUserResolver(), a.1, a.2, a.3, a.4, a.5, a.6, a.7)
        })
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: {(a: (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8)) throws -> Service in
            return try factory(a.0.asUserResolver(), a.1, a.2, a.3, a.4, a.5, a.6, a.7, a.8)
        })
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: {(a: (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9)) throws -> Service in
            return try factory(a.0.asUserResolver(), a.1, a.2, a.3, a.4, a.5, a.6, a.7, a.8, a.9)
        })
    }

}

public extension ContainerWithScope where ResolverType == Resolver {

    @discardableResult
    func register<Service>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: factory)
    }

    @discardableResult
    func register<Service, Arg1>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType, Arg1) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: factory)
    }

    @discardableResult
    func register<Service, Arg1, Arg2>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType, Arg1, Arg2) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: factory)
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType, Arg1, Arg2, Arg3) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: factory)
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType, Arg1, Arg2, Arg3, Arg4) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: factory)
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4, Arg5>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType, Arg1, Arg2, Arg3, Arg4, Arg5) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: factory)
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: factory)
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: factory)
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: factory)
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (ResolverType, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9) throws -> Service
    ) -> ServiceEntry<Service> {
        return container._register(serviceType, name: name, inObjectScope: scope, factory: factory)
    }

}
// swiftlint:enable all
