//
//  Pattern.swift
//  EENavigator
//
//  Created by zhangwei on 2023/8/23.
//

import Foundation

/// Pattern.
///
/// 背景：
///     Lark 路由中的 pattern string 很多并不符合 RFC-3986 规范，然而大量的逻辑处理都依赖了 Foundaiton
///     中的 URL/URLComponents （遵循 RFC-3986 规范）；逻辑健壮性较差，经常在版本更替时出现非预期的异常，
///     Pattern 旨在封装相关功能，逐渐解除对 URL/URLComponents 接口的依赖；
///     后续可能发展成为 public 的类型
struct Pattern {
    static let star = Pattern(rawValue: "*")

    var rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    private typealias ComponentRange = Range<String.Index>

    // TODO: 去掉对 URL/URLComponents 的依赖
    /// 借助 `URLComponents` 的能力，寻找 scheme/host 的 range
    private func getRange(with keyPath: KeyPath<URLComponents, ComponentRange?>) -> ComponentRange? {
        let components: URLComponents?
        #if swift(>=5.9)    // >= Xcode 15
        if #available(iOS 17.0, *) {
            components = URLComponents(string: rawValue, encodingInvalidCharacters: true)
        } else {
            components = URLComponents(string: rawValue)
        }
        #else
            components = URLComponents(string: rawValue)
        #endif
        guard
            let components,
            let refValue = components.string,
            let refRange = components[keyPath: keyPath],
            refRange.lowerBound >= rawValue.startIndex,
            refRange.upperBound <= rawValue.endIndex
        else {
            return nil
        }
        let refScheme = refValue[refRange]
        let slfScheme = rawValue[refRange]
        if refScheme == slfScheme {
            return refRange
        } else {
            return nil
        }
    }

    /// 返回 rawValue 中 scheme 对应的 range
    private var rangeOfScheme: ComponentRange? {
        getRange(with: \.rangeOfScheme)
    }

    /// 返回 rawValue 中 host 对应的 range
    private var rangeOfHost: ComponentRange? {
        getRange(with: \.rangeOfHost)
    }

    static var enableNewStandardized: Bool {
        guard let fgProvider = Navigator.shared.featureGatingProvider else {
            #if DEBUG || ALPHA
            return true
            #else
            return false
            #endif
        }
        return fgProvider("ios.lark_navigator.pattern_standardized_optimize")
    }

    /// 标准化处理
    ///   - ** 异常处理 **
    ///     eg: "" -> "*"
    ///   - ** Scheme, Host 进行 lowercased 处理**
    ///     eg: "Lark://FeiShu.com/a/b/c" -> "lark://feishu.com/a/b/c"
    func standardized() -> Pattern {
        if rawValue.isEmpty {
            return .star
        }
        if rawValue.lowercased() == rawValue {
            return self
        }
        guard Self.enableNewStandardized else {
            return oldLowercased().asPattern()
        }
        var newStr = rawValue
        if let rangeOfScheme {
            let lowercased = rawValue[rangeOfScheme].lowercased()
            newStr.replaceSubrange(rangeOfScheme, with: lowercased)
        }
        if let rangeOfHost {
            let lowercased = rawValue[rangeOfHost].lowercased()
            newStr.replaceSubrange(rangeOfHost, with: lowercased)
        }
        return .init(rawValue: newStr)
    }
}

protocol PatternConvertible {
    func asPattern() -> Pattern
}

extension Pattern: PatternConvertible {
    func asPattern() -> Pattern {
        return self
    }
}

extension String: PatternConvertible {
    func asPattern() -> Pattern {
        return .init(rawValue: self)
    }
}

extension Pattern {
    func oldLowercased() -> String {
        #if swift(>=5.9)
        if #available(iOS 17.0, *) {
            return URL(
                string: rawValue,
                encodingInvalidCharacters: false
            )?.schemeAndHostLowercased.absoluteString ?? rawValue
        }
        #endif

        return URL(string: rawValue)?.schemeAndHostLowercased.absoluteString ?? rawValue
    }
}
