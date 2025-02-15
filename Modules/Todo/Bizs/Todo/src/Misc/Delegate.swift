//
//  Delegate.swift
//  Todo
//
//  Created by 张威 on 2021/5/12.
//
//  Included OSS: Kingfisher
//  Copyright (c) 2019 Wei Wang
//  spdx license identifier: MIT

import Foundation

/// Ref:
///  - [使用 protocol 和 callAsFunction 改进 Delegate](https://onevcat.com/2020/03/improve-delegate/)
///  - https://gist.github.com/onevcat/3c8f7c4e8c96f288854688cf34111636

/// A class that keeps a weakly reference for `self` when implementing `onXXX` behaviors.
/// Instead of remembering to keep `self` as weak in a stored closure:
///
/// ```swift
/// // MyClass.swift
/// var onDone: (() -> Void)?
/// func done() {
///     onDone?()
/// }
///
/// // ViewController.swift
/// var obj: MyClass?
///
/// func doSomething() {
///     obj = MyClass()
///     obj!.onDone = { [weak self] in
///         self?.reportDone()
///     }
/// }
/// ```
///
/// You can create a `Delegate` and observe on `self`. Now, there is no retain cycle inside:
///
/// ```swift
/// // MyClass.swift
/// let onDone = Delegate<(), Void>()
/// func done() {
///     onDone.call()
/// }
///
/// // ViewController.swift
/// var obj: MyClass?
///
/// func doSomething() {
///     obj = MyClass()
///     obj!.onDone.delegate(on: self) { (self, _)
///         // `self` here is shadowed and does not keep a strong ref.
///         // So you can release both `MyClass` instance and `ViewController` instance.
///         self.reportDone()
///     }
/// }
/// ```
///

public final class Delegate<Input, Output> {
    public init() {}

    private var block: ((Input) -> Output?)?
    public func delegate<T: AnyObject>(on target: T, block: ((T, Input) -> Output)?) {
        self.block = { [weak target] input in
            guard let target = target else { return nil }
            return block?(target, input)
        }
    }

    public func call(_ input: Input) -> Output? {
        return block?(input)
    }

    public func callAsFunction(_ input: Input) -> Output? {
        return call(input)
    }
}

extension Delegate where Input == Void {
    public func call() -> Output? {
        return call(())
    }

    public func callAsFunction() -> Output? {
        return call()
    }
}

extension Delegate where Input == Void, Output: OptionalProtocol {
    public func call() -> Output {
        return call(())
    }

    public func callAsFunction() -> Output {
        return call()
    }
}

extension Delegate where Output: OptionalProtocol {
    public func call(_ input: Input) -> Output {
        if let result = block?(input) {
            return result
        } else {
            return Output.createNil
        }
    }

    public func callAsFunction(_ input: Input) -> Output {
        return call(input)
    }
}

public protocol OptionalProtocol {
    static var createNil: Self { get }
}

extension Optional: OptionalProtocol {
    public static var createNil: Wrapped? {
         return nil
    }
}
