//
//  SKMoreItemChecker.swift
//  SKFoundation
//
//  Created by majie.7 on 2022/9/21.
//

import Foundation
import RxSwift
import RxCocoa
import SKResource

public protocol HiddenChecker: HiddenCheckerType {
    var isHidden: Bool { get }
}

public protocol HiddenCheckerType {
    var hiddenCheckers: [HiddenChecker] { get }
}

extension HiddenChecker {
    public var hiddenCheckers: [HiddenChecker] { [self] }
}

extension Array: HiddenCheckerType where Element == HiddenChecker {
    public var hiddenCheckers: [HiddenChecker] { self }
}

public protocol EnableChecker: EnableCheckerType {
    var isEnabled: Bool { get }
    /// disable 时仍展示 enable 的 UI 样式
    var forceEnableStyle: Bool { get }
    var disableReason: String { get }
    /// 自定义的错误处理逻辑，返回 true 会继续执行后续的 Toast 逻辑
    var customHandler: ((UIViewController?) -> Bool)? { get }
}

public protocol EnableCheckerType {
    var enableCheckers: [EnableChecker] { get }
}

extension EnableChecker {
    public var forceEnableStyle: Bool { false }
    public var enableCheckers: [EnableChecker] { [self] }
    public var customHandler: ((UIViewController?) -> Bool)? { return nil }
}

extension Array: EnableCheckerType where Element == EnableChecker {
    public var enableCheckers: [EnableChecker] { self }
}

@resultBuilder
public struct HiddenCheckerBuilder {
    public static func buildBlock() -> [HiddenChecker] { [] }
    public static func buildBlock(_ checkers: HiddenCheckerType...) -> [HiddenChecker] { checkers.flatMap(\.hiddenCheckers) }
    public static func buildIf(_ value: [HiddenChecker]?) -> [HiddenChecker] { value ?? [] }
    public static func buildEither(first: [HiddenChecker]) -> [HiddenChecker] { first }
    public static func buildEither(second: [HiddenChecker]) -> [HiddenChecker] { second }
}
@resultBuilder
public struct EnableCheckerBuilder {
    public static func buildBlock() -> [EnableChecker] { [] }
    public static func buildBlock(_ checkers: EnableCheckerType...) -> [EnableChecker] { checkers.flatMap(\.enableCheckers) }
    public static func buildIf(_ value: [EnableChecker]?) -> [EnableChecker] { value ?? [] }
    public static func buildEither(first: [EnableChecker]) -> [EnableChecker] { first }
    public static func buildEither(second: [EnableChecker]) -> [EnableChecker] { second }
}

public protocol RxChecker: HiddenChecker, EnableChecker {
    associatedtype InputType
    associatedtype CheckedValueType
    var inputRelay: BehaviorRelay<InputType> { get }
    var checkedValue: CheckedValueType { get }
    func verify(input: InputType, checkedValue: CheckedValueType) -> Bool
}

extension RxChecker {
    public var isHidden: Bool {
        !verify(input: inputRelay.value, checkedValue: checkedValue)
    }

    public var isEnabled: Bool {
        verify(input: inputRelay.value, checkedValue: checkedValue)
    }
}

// 自定 disable 提示
public final class CustomReasonEnableChecker: EnableChecker {
    public let subChecker: EnableChecker
    public let customDisableReason: String

    public var isEnabled: Bool { subChecker.isEnabled }
    public var forceEnableStyle: Bool { subChecker.forceEnableStyle }
    public var disableReason: String { customDisableReason }

    public init(checker: EnableChecker, reason: String) {
        subChecker = checker
        customDisableReason = reason
    }
}

public final class EnableInvertChecker: EnableChecker {
    public let subChecker: EnableChecker
    public var isEnabled: Bool { !subChecker.isEnabled }
    public var forceEnableStyle: Bool { subChecker.forceEnableStyle }
    public var disableReason: String { subChecker.disableReason }

    public init(checker: EnableChecker) {
        subChecker = checker
    }
}

public final class HiddenInvertChecker: HiddenChecker {
    public let subChecker: HiddenChecker
    public var isHidden: Bool { !subChecker.isHidden }

    public init(checker: HiddenChecker) {
        subChecker = checker
    }
}

extension EnableChecker {
    public func custom(reason: String) -> EnableChecker {
        CustomReasonEnableChecker(checker: self, reason: reason)
    }

    public func invert() -> EnableChecker {
        EnableInvertChecker(checker: self)
    }
}

extension HiddenChecker {
    public func invert() -> HiddenChecker {
        HiddenInvertChecker(checker: self)
    }
}


public final class NetworkChecker: RxChecker {

    let disposeBag = DisposeBag()
    public let inputRelay = BehaviorRelay<Bool>(value: false)
    public var checkedValue: Bool { true }

    public var disableReason: String {
        BundleI18n.SKResource.Doc_List_OperateFailedNoNet
    }

    public init(input: Observable<Bool>) {
        input.bind(to: inputRelay).disposed(by: disposeBag)
    }

    public func verify(input: Bool, checkedValue: Bool) -> Bool {
        // 直接检查当前是否有网
        input
    }
}
