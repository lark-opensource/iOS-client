//
//  Container+Register.generated.swift
//  Swinject
//
//  Created by CharlieSu on 4/30/20.
//
// swiftlint:disable all
//
// NOTICE:
//
// Container+Register.generated.swift is generated from Container.Arguments.erb by ERB.
// Do NOT modify Container+Register.generated.swift directly.
// Instead, modify Container+Register.generated.swift.erb and run `script/gencode` at the project root directory to generate the code.
//


import Foundation

public extension Container {

    @discardableResult
    func register<Service>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (Resolver) throws -> Service
    ) -> ServiceEntry<Service> {
        return _register(serviceType, name: name, factory: factory)
    }

    @discardableResult
    func register<Service, Arg1>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (Resolver, Arg1) throws -> Service
    ) -> ServiceEntry<Service> {
        return _register(serviceType, name: name, factory: factory)
    }

    @discardableResult
    func register<Service, Arg1, Arg2>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (Resolver, Arg1, Arg2) throws -> Service
    ) -> ServiceEntry<Service> {
        return _register(serviceType, name: name, factory: factory)
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (Resolver, Arg1, Arg2, Arg3) throws -> Service
    ) -> ServiceEntry<Service> {
        return _register(serviceType, name: name, factory: factory)
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (Resolver, Arg1, Arg2, Arg3, Arg4) throws -> Service
    ) -> ServiceEntry<Service> {
        return _register(serviceType, name: name, factory: factory)
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4, Arg5>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5) throws -> Service
    ) -> ServiceEntry<Service> {
        return _register(serviceType, name: name, factory: factory)
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) throws -> Service
    ) -> ServiceEntry<Service> {
        return _register(serviceType, name: name, factory: factory)
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7) throws -> Service
    ) -> ServiceEntry<Service> {
        return _register(serviceType, name: name, factory: factory)
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8) throws -> Service
    ) -> ServiceEntry<Service> {
        return _register(serviceType, name: name, factory: factory)
    }

    @discardableResult
    func register<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9>(
        _ serviceType: Service.Type, name: String? = nil,
        factory: @escaping (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9) throws -> Service
    ) -> ServiceEntry<Service> {
        return _register(serviceType, name: name, factory: factory)
    }

}
// swiftlint:enable all
