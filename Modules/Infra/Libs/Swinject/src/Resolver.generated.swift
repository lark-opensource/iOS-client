//
//  Resolver.swift
//  Swinject
//
//  Created by CharlieSu on 4/29/20.
//  Copyright © 2020 Lark. All rights reserved.
//
// swiftlint:disable all
//
// NOTICE:
//
// Resolver.swift is generated from Resolver.erb by ERB.
// Do NOT modify Container.Arguments.swift directly.
// Instead, modify Resolver.erb and run `gencode` at the project root directory to generate the code.
//


import Foundation
public extension Resolver {
    // 不提供推断serviceType的API，这样强制确认，避免出错。另外也可以通过主动写的type搜索到对应的调用

    /// 相当于resolve(type:), 但未注册，在测试阶段会崩溃, 方便提前发现集成问题
    func resolve<Service>(assert serviceType: Service.Type, name: String? = nil) throws -> Service {
        #if DEBUG || ALPHA
        do {
            let context: ResolverContext<Service, Resolver> = ResolverContext(name: name, resolver: self, arguments: {$0})
            return try _resolve(context: context)
        } catch let error as SwinjectError {
            fatalError("\(serviceType) \(name ?? "") resolve with error: \(error)")
        }
        #else
            let context: ResolverContext<Service, Resolver> = ResolverContext(name: name, resolver: self, arguments: {$0})
            return try _resolve(context: context)
        #endif
    }

// MARK: - failable API
    func resolve<Service>(type serviceType: Service.Type, name: String? = nil) throws -> Service {
        let context: ResolverContext<Service, Resolver> = ResolverContext(name: name, resolver: self, arguments: {$0})
        return try _resolve(context: context)
    }

    func resolve<Service, Arg1>(
        assert serviceType: Service.Type,
        name: String? = nil,
        argument arg1: Arg1
    ) throws -> Service {
        #if DEBUG || ALPHA
        do {
            let context: ResolverContext<Service, (Resolver, Arg1)> = ResolverContext(
                name: name, resolver: self, arguments: {($0, arg1)})
            return try _resolve(context: context)
        } catch let error as SwinjectError {
            fatalError("\(serviceType) \(name ?? "") resolve with error: \(error)")
        }
        #else
            let context: ResolverContext<Service, (Resolver, Arg1)> = ResolverContext(
                name: name, resolver: self, arguments: {($0, arg1)})
            return try _resolve(context: context)
        #endif
    }
    func resolve<Service, Arg1>(
        type serviceType: Service.Type,
        name: String? = nil,
        argument arg1: Arg1
    ) throws -> Service {
        let context: ResolverContext<Service, (Resolver, Arg1)> = ResolverContext(
            name: name, resolver: self, arguments: {($0, arg1)})
        return try _resolve(context: context)
    }
    func resolve<Service, Arg1, Arg2>(
        assert serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2
    ) throws -> Service {
        #if DEBUG || ALPHA
        do {
            let context: ResolverContext<Service, (Resolver, Arg1, Arg2)> = ResolverContext(
                name: name, resolver: self, arguments: {($0, arg1, arg2)})
            return try _resolve(context: context)
        } catch let error as SwinjectError {
            fatalError("\(serviceType) \(name ?? "") resolve with error: \(error)")
        }
        #else
            let context: ResolverContext<Service, (Resolver, Arg1, Arg2)> = ResolverContext(
                name: name, resolver: self, arguments: {($0, arg1, arg2)})
            return try _resolve(context: context)
        #endif
    }
    func resolve<Service, Arg1, Arg2>(
        type serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2
    ) throws -> Service {
        let context: ResolverContext<Service, (Resolver, Arg1, Arg2)> = ResolverContext(
            name: name, resolver: self, arguments: {($0, arg1, arg2)})
        return try _resolve(context: context)
    }
    func resolve<Service, Arg1, Arg2, Arg3>(
        assert serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3
    ) throws -> Service {
        #if DEBUG || ALPHA
        do {
            let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3)> = ResolverContext(
                name: name, resolver: self, arguments: {($0, arg1, arg2, arg3)})
            return try _resolve(context: context)
        } catch let error as SwinjectError {
            fatalError("\(serviceType) \(name ?? "") resolve with error: \(error)")
        }
        #else
            let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3)> = ResolverContext(
                name: name, resolver: self, arguments: {($0, arg1, arg2, arg3)})
            return try _resolve(context: context)
        #endif
    }
    func resolve<Service, Arg1, Arg2, Arg3>(
        type serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3
    ) throws -> Service {
        let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3)> = ResolverContext(
            name: name, resolver: self, arguments: {($0, arg1, arg2, arg3)})
        return try _resolve(context: context)
    }
    func resolve<Service, Arg1, Arg2, Arg3, Arg4>(
        assert serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4
    ) throws -> Service {
        #if DEBUG || ALPHA
        do {
            let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4)> = ResolverContext(
                name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4)})
            return try _resolve(context: context)
        } catch let error as SwinjectError {
            fatalError("\(serviceType) \(name ?? "") resolve with error: \(error)")
        }
        #else
            let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4)> = ResolverContext(
                name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4)})
            return try _resolve(context: context)
        #endif
    }
    func resolve<Service, Arg1, Arg2, Arg3, Arg4>(
        type serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4
    ) throws -> Service {
        let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4)> = ResolverContext(
            name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4)})
        return try _resolve(context: context)
    }
    func resolve<Service, Arg1, Arg2, Arg3, Arg4, Arg5>(
        assert serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5
    ) throws -> Service {
        #if DEBUG || ALPHA
        do {
            let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5)> = ResolverContext(
                name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5)})
            return try _resolve(context: context)
        } catch let error as SwinjectError {
            fatalError("\(serviceType) \(name ?? "") resolve with error: \(error)")
        }
        #else
            let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5)> = ResolverContext(
                name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5)})
            return try _resolve(context: context)
        #endif
    }
    func resolve<Service, Arg1, Arg2, Arg3, Arg4, Arg5>(
        type serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5
    ) throws -> Service {
        let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5)> = ResolverContext(
            name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5)})
        return try _resolve(context: context)
    }
    func resolve<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(
        assert serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6
    ) throws -> Service {
        #if DEBUG || ALPHA
        do {
            let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6)> = ResolverContext(
                name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5, arg6)})
            return try _resolve(context: context)
        } catch let error as SwinjectError {
            fatalError("\(serviceType) \(name ?? "") resolve with error: \(error)")
        }
        #else
            let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6)> = ResolverContext(
                name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5, arg6)})
            return try _resolve(context: context)
        #endif
    }
    func resolve<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(
        type serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6
    ) throws -> Service {
        let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6)> = ResolverContext(
            name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5, arg6)})
        return try _resolve(context: context)
    }
    func resolve<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7>(
        assert serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6, _ arg7: Arg7
    ) throws -> Service {
        #if DEBUG || ALPHA
        do {
            let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7)> = ResolverContext(
                name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)})
            return try _resolve(context: context)
        } catch let error as SwinjectError {
            fatalError("\(serviceType) \(name ?? "") resolve with error: \(error)")
        }
        #else
            let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7)> = ResolverContext(
                name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)})
            return try _resolve(context: context)
        #endif
    }
    func resolve<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7>(
        type serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6, _ arg7: Arg7
    ) throws -> Service {
        let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7)> = ResolverContext(
            name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)})
        return try _resolve(context: context)
    }
    func resolve<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8>(
        assert serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6, _ arg7: Arg7, _ arg8: Arg8
    ) throws -> Service {
        #if DEBUG || ALPHA
        do {
            let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8)> = ResolverContext(
                name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)})
            return try _resolve(context: context)
        } catch let error as SwinjectError {
            fatalError("\(serviceType) \(name ?? "") resolve with error: \(error)")
        }
        #else
            let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8)> = ResolverContext(
                name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)})
            return try _resolve(context: context)
        #endif
    }
    func resolve<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8>(
        type serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6, _ arg7: Arg7, _ arg8: Arg8
    ) throws -> Service {
        let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8)> = ResolverContext(
            name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)})
        return try _resolve(context: context)
    }
    func resolve<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9>(
        assert serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6, _ arg7: Arg7, _ arg8: Arg8, _ arg9: Arg9
    ) throws -> Service {
        #if DEBUG || ALPHA
        do {
            let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9)> = ResolverContext(
                name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)})
            return try _resolve(context: context)
        } catch let error as SwinjectError {
            fatalError("\(serviceType) \(name ?? "") resolve with error: \(error)")
        }
        #else
            let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9)> = ResolverContext(
                name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)})
            return try _resolve(context: context)
        #endif
    }
    func resolve<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9>(
        type serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6, _ arg7: Arg7, _ arg8: Arg8, _ arg9: Arg9
    ) throws -> Service {
        let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9)> = ResolverContext(
            name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)})
        return try _resolve(context: context)
    }


// MARK: - Old API, return optional Service
    @available(*, deprecated, message: "resolve is deprecated. Use `resolve(type:) or resolve(assert:)` and avoid force unwrap instead.")
    func resolve<Service>(_ serviceType: Service.Type, name: String? = nil) -> Service? {
        let context: ResolverContext<Service, Resolver> = ResolverContext(name: name, resolver: self, arguments: {$0})
        context[.oldAPI] = true
        return try? _resolve(context: context)
    }
    @available(*, deprecated, message: "resolve is deprecated. Use `resolve(type:) or resolve(assert:)` and avoid force unwrap instead.")
    func resolve<Service, Arg1>(
        _ serviceType: Service.Type,
        name: String? = nil,
        argument arg1: Arg1
    ) -> Service? {
        let context: ResolverContext<Service, (Resolver, Arg1)> = ResolverContext(
            name: name, resolver: self, arguments: {($0, arg1)})
        context[.oldAPI] = true
        return try? _resolve(context: context)
    }
    @available(*, deprecated, message: "resolve is deprecated. Use `resolve(type:) or resolve(assert:)` and avoid force unwrap instead.")
    func resolve<Service, Arg1, Arg2>(
        _ serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2
    ) -> Service? {
        let context: ResolverContext<Service, (Resolver, Arg1, Arg2)> = ResolverContext(
            name: name, resolver: self, arguments: {($0, arg1, arg2)})
        context[.oldAPI] = true
        return try? _resolve(context: context)
    }
    @available(*, deprecated, message: "resolve is deprecated. Use `resolve(type:) or resolve(assert:)` and avoid force unwrap instead.")
    func resolve<Service, Arg1, Arg2, Arg3>(
        _ serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3
    ) -> Service? {
        let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3)> = ResolverContext(
            name: name, resolver: self, arguments: {($0, arg1, arg2, arg3)})
        context[.oldAPI] = true
        return try? _resolve(context: context)
    }
    @available(*, deprecated, message: "resolve is deprecated. Use `resolve(type:) or resolve(assert:)` and avoid force unwrap instead.")
    func resolve<Service, Arg1, Arg2, Arg3, Arg4>(
        _ serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4
    ) -> Service? {
        let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4)> = ResolverContext(
            name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4)})
        context[.oldAPI] = true
        return try? _resolve(context: context)
    }
    @available(*, deprecated, message: "resolve is deprecated. Use `resolve(type:) or resolve(assert:)` and avoid force unwrap instead.")
    func resolve<Service, Arg1, Arg2, Arg3, Arg4, Arg5>(
        _ serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5
    ) -> Service? {
        let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5)> = ResolverContext(
            name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5)})
        context[.oldAPI] = true
        return try? _resolve(context: context)
    }
    @available(*, deprecated, message: "resolve is deprecated. Use `resolve(type:) or resolve(assert:)` and avoid force unwrap instead.")
    func resolve<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(
        _ serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6
    ) -> Service? {
        let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6)> = ResolverContext(
            name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5, arg6)})
        context[.oldAPI] = true
        return try? _resolve(context: context)
    }
    @available(*, deprecated, message: "resolve is deprecated. Use `resolve(type:) or resolve(assert:)` and avoid force unwrap instead.")
    func resolve<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7>(
        _ serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6, _ arg7: Arg7
    ) -> Service? {
        let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7)> = ResolverContext(
            name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)})
        context[.oldAPI] = true
        return try? _resolve(context: context)
    }
    @available(*, deprecated, message: "resolve is deprecated. Use `resolve(type:) or resolve(assert:)` and avoid force unwrap instead.")
    func resolve<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8>(
        _ serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6, _ arg7: Arg7, _ arg8: Arg8
    ) -> Service? {
        let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8)> = ResolverContext(
            name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)})
        context[.oldAPI] = true
        return try? _resolve(context: context)
    }
    @available(*, deprecated, message: "resolve is deprecated. Use `resolve(type:) or resolve(assert:)` and avoid force unwrap instead.")
    func resolve<Service, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9>(
        _ serviceType: Service.Type,
        name: String? = nil,
        arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5, _ arg6: Arg6, _ arg7: Arg7, _ arg8: Arg8, _ arg9: Arg9
    ) -> Service? {
        let context: ResolverContext<Service, (Resolver, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Arg9)> = ResolverContext(
            name: name, resolver: self, arguments: {($0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)})
        context[.oldAPI] = true
        return try? _resolve(context: context)
    }
}

// swiftlint:enable all
