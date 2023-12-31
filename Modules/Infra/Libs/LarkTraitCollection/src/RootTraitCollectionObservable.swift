//
//  RootTraitCollectionObservable.swift
//  LarkUIKit
//
//  Created by Meng on 2019/8/23.
//

import Foundation
import RxSwift
import RxRelay

struct Observer {
    private struct WeakNode {
        weak var value: RootTraitCollectionNodeType?
    }

    var target: RootTraitCollectionNodeType? {
        return _target.value
    }

    let change: BehaviorRelay<TraitCollectionChange>

    private let _target: WeakNode

    init(target: RootTraitCollectionNodeType, change: BehaviorRelay<TraitCollectionChange>) {
        self._target = WeakNode(value: target)
        self.change = change
    }
}

/// RootTraitCollection observable store model
public final class RootTraitCollectionObservable {
    private var willObservers: [Observer] = []
    private var didObservers: [Observer] = []

    init() {}

    func appendWillObserver(_ observer: Observer) {
        willObservers.append(observer)
    }

    func appendDidObserver(_ observer: Observer) {
        didObservers.append(observer)
    }
}

// MARK: - public
extension RootTraitCollectionObservable {

    /// noti observable will change
    public func traitCollectionWillChange(
        _ rootNode: RootTraitCollectionNodeType,
        change: TraitCollectionChange
    ) {
        willObservers
            .filter({ $0.target != nil })
            .filter({ rootNode.checkNeedNotifyRootChange(of: $0.target!) })
            .forEach({ $0.change.accept(change) })
    }

    /// noti observable did change
    public func traitCollectionDidChange(
        _ rootNode: RootTraitCollectionNodeType,
        change: TraitCollectionChange
    ) {
        didObservers
            .filter({ $0.target != nil })
            .filter({ rootNode.checkNeedNotifyRootChange(of: $0.target!) })
            .forEach({ $0.change.accept(change) })
    }
}
