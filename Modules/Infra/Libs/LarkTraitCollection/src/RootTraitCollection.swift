//
//  RootTraitCollection.swift
//  LarkUIKit
//
//  Created by Meng on 2019/8/23.
//

import UIKit
import Foundation
import RxSwift
import RxRelay

/// TraitCollection change Model
public struct TraitCollectionChange: Equatable {
    /// origin trait collection
    public let old: UITraitCollection
    /// new trait collection
    public let new: UITraitCollection

    /// init function
    public init(old: UITraitCollection, new: UITraitCollection) {
        self.old = old
        self.new = new
    }
}

/// 观察UI所在根节点的TraitCollection变化通知的管理、分发、监听、及过滤。默认提供多窗口假设。
///
/// RootTraitCollection提供宽松的通知能力:
/// 在满足多窗口的前提假设下，尽可能的将RootUI的traitCollection变化通知到观察者
public final class RootTraitCollection: NSObject {

    /// 单例
    public static let shared = RootTraitCollection()

    /// 使用自定义的 sizeClass
    public var useCustomSizeClass: Bool = false

    private static var hadSwizzledResponderMethod: Bool = false

    private let observable = RootTraitCollectionObservable()

    /// return default RootTraitCollection observable
    public class var observable: RootTraitCollectionObservable {
        return shared.observable
    }

    /// return default RootTraitCollection observer
    public class var observer: RootTraitCollectionObserver {
        return shared
    }

    @objc
    public static func swizzledIfNeeed() {
        if !RootTraitCollection.hadSwizzledResponderMethod {
            UIViewController.ltc_swizzleMethod()
            RootTraitCollection.hadSwizzledResponderMethod = true
        }
    }
}

// MARK: - RootTraitCollectionObserver
extension RootTraitCollection: RootTraitCollectionObserver {

    /// get TraitCollection willChange signal
    public func observeRootTraitCollectionWillChange(
        for node: RootTraitCollectionNodeType
    ) -> Observable<TraitCollectionChange> {
        let change = BehaviorRelay<TraitCollectionChange>(value: node.defaultTraitCollectionChange)
        let observer = Observer(target: node, change: change)
        observable.appendWillObserver(observer)
        return observer.change.distinctUntilChanged().skip(1)
    }

    /// get TraitCollection DidChange signal
    public func observeRootTraitCollectionDidChange(
        for node: RootTraitCollectionNodeType
    ) -> Observable<TraitCollectionChange> {
        let change = BehaviorRelay<TraitCollectionChange>(value: node.defaultTraitCollectionChange)
        let observer = Observer(target: node, change: change)
        observable.appendDidObserver(observer)
        return observer.change.distinctUntilChanged().skip(1)
    }
}

extension UITraitEnvironment {
    var defaultTraitCollectionChange: TraitCollectionChange {
        return TraitCollectionChange(
            old: customTraitCollection,
            new: customTraitCollection
        )
    }
}
