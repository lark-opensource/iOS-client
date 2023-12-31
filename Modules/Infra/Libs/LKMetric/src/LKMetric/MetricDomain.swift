//
//  MetricDomain.swift
//  LKMetric
//
//  Created by Miaoqi Wang on 2019/11/6.
//

import Foundation

/// Domain all domain ref: https://bytedance.feishu.cn/wiki/wikcntj9w5HOMvmuzISzch4vTLd
public final class MetricDomain {

    /// actual value of this domain chain
    public internal(set) var value: [Int32]

    init(value: [Int32] = []) {
        self.value = value
    }

    /// return new domain chain with sub domain enum
    /// - Parameter domainEnum: sub domain enum
    public func s(_ subEnum: MetricDomainEnum) -> MetricDomain {
        value.append(contentsOf: subEnum.domain.value)
        return self
    }

    /// Get domain according rawValue, this is a dangerous api, be careful
    ///
    /// DO NOT use this unless you have to, and find existing use case to make sure
    /// - Parameter rawValue: domain rawValue
    public static func domain(rawValue: [Int32]) -> MetricDomain {
        return MetricDomain(value: rawValue)
    }
}

/// enum domain protocol
public protocol MetricDomainEnum {

    /// rawValue is Int32
    var rawValue: Int32 { get }

    /// corresponding domain of enum
    var domain: MetricDomain { get }

    /// return new domain chain with sub domain enum
    /// - Parameter subEnum: sub domain enum
    func s(_ subEnum: MetricDomainEnum) -> MetricDomain
}

extension MetricDomainEnum {

    /// corresponding domain of enum
    public var domain: MetricDomain {
        return MetricDomain(value: [rawValue])
    }

    /// return new domain chain with sub domain enum
    /// - Parameter subEnum: sub domain enum
    public func s(_ subEnum: MetricDomainEnum) -> MetricDomain {
        return domain.s(subEnum)
    }
}

// MARK: - Root Domain

public enum Root: Int32, MetricDomainEnum {
    case unknown = 0
    case passport = 1
    case push = 2
    case invite = 3
    case dynamic = 4
    case onboarding = 8
    case search = 11
    case translation = 12
}
