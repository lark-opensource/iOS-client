//
//  Isolatable.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

public protocol Isolatable {
    /// isolation id
    var isolationId: String { get }
}

/// Top isolate level
public enum Space: Isolatable {
    case global
    case user(id: String)

    static let globalRepr = "Global"
    static let userPrefix = "User_"

    public var isolationId: String {
        switch self {
        case .global: return Self.globalRepr
        case .user(let id): return Self.userPrefix + id
        }
    }
}

extension Space: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.isolationId == rhs.isolationId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(isolationId)
    }
}

extension Space: CustomStringConvertible {
    public var description: String { isolationId }
}

extension Space {
    static func from(isolationId: String) -> Space? {
        if isolationId == Space.globalRepr {
            return Space.global
        } else if isolationId.hasPrefix(Space.userPrefix) {
            let userId = String(isolationId.dropFirst(Space.userPrefix.count))
            return Space.user(id: userId)
        }
        return nil
    }
}

extension Space {
    func invalidFixed() -> Space {
        var fixed = self
        if case .user(let uid) = fixed, uid.isEmpty {
            fixed = .global
        }
        return fixed
    }
}

// Second Isolate Level
public protocol DomainType: Isolatable, CustomStringConvertible {
    var parent: DomainType? { get }
}

extension DomainType {
    var hashable: DomainHash { .init(self) }

    func isolationChain(with separator: String = "") -> String {
        return asComponents().map(\.isolationId).joined(separator: separator)
    }
}

public extension DomainType {
    var isRoot: Bool { parent == nil }

    /// Return root of current Domain
    var root: DomainType {
        var ret: DomainType = self
        while let p = ret.parent {
            ret = p
        }
        return ret
    }

    func asComponents() -> [DomainType] {
        var ret = [DomainType]()
        var iter: DomainType? = self
        while let p = iter {
            ret.insert(p, at: 0)
            iter = p.parent
        }
        return ret
    }

    func isSame(as other: DomainType) -> Bool {
        let testComps = other.asComponents().map(\.isolationId)
        let selfComps = asComponents().map(\.isolationId)
        return testComps == selfComps
    }

    /// 判断 `self` 是否是 `other` 的 ancestor
    func isAncestor(of other: DomainType) -> Bool {
        let selfComps = asComponents().map(\.isolationId)
        let testComps = other.asComponents().map(\.isolationId)
        guard testComps.count > selfComps.count else { return false }
        for i in 0..<selfComps.count {
            guard testComps[i] == selfComps[i] else {
                return false
            }
        }
        return true
    }

    /// 判断 `self` 是否是 `other` 的 descestor
    func isDescendant(of other: DomainType) -> Bool {
        return other.isAncestor(of: self)
    }

}

extension DomainType {
    public var description: String {
        return isolationChain(with: ".")
    }
}

extension CharacterSet {
    /// Domain 中禁止使用的字符：`.`
    public static let domainForbiddens = CharacterSet(charactersIn: ".")
}

extension DomainType {
    func contains(characterSet: CharacterSet, includesAncestor: Bool) -> Bool {
        if isolationId.rangeOfCharacter(from: characterSet) != nil {
            return true
        }
        guard includesAncestor else { return false }

        var iter: DomainType? = parent
        while let p = iter {
            if p.isolationId.rangeOfCharacter(from: characterSet) != nil {
                return true
            }
            iter = p.parent
        }
        return false
    }

    func checkValid(includesAncestor: Bool) -> Bool {
        return !contains(characterSet: .domainForbiddens, includesAncestor: includesAncestor)
    }
}

public struct Domain: DomainType {
    public var isolationId: String

#if DEBUG
    static var disableCheckValid = false
#endif

    public internal(set) var parent: DomainType?

    init(_ isolationId: String) {
        self.isolationId = isolationId
#if DEBUG
        if Self.disableCheckValid { return }
#endif

#if DEBUG || ALPHA
        if !checkValid(includesAncestor: false) {
            fatalError("invalid isolationId: \(isolationId)")
        }
#endif
    }
}

extension Domain {
    public static func makeDomain(from list: [String]) -> Domain? {
        guard !list.isEmpty else { return nil }

        var domain = Domain(list[0])
        list[1...].forEach { str in
            domain = domain.child(str)
        }
        return domain
    }
}

/// Builtin Domains
extension Domain {
    public static let keyValue = Domain("KeyValue")
    public static let sandbox = Domain("Sandbox")
}

public protocol DomainConvertible: DomainType {
    func asDomain() -> Domain
}

extension DomainConvertible {
    public var isolationId: String { asDomain().isolationId }
    public var parent: DomainType? { asDomain().parent }

    public func child(_ isolationId: String) -> Domain {
        var child = Domain(isolationId)
        child.parent = self
        return child
    }
}

extension Domain: DomainConvertible {
    public func asDomain() -> Domain {
        return self
    }
}

internal struct DomainHash: Hashable {
    private var inner: DomainType

    init(_ inner: DomainType) {
        self.inner = inner
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.inner.isSame(as: rhs.inner)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(inner.asComponents().map(\.isolationId))
    }
}

extension DomainType {
    func assertInvalid() {
        let isDomainValid = Dependencies.domainChecker?(root) ?? true
        KVStores.assert(isDomainValid, event: .wrongDomain)
    }
}
