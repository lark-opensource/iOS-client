//
//  PushCardCenter.swift
//  ByteViewUI
//
//  Created by kiri on 2023/6/28.
//

import Foundation

public final class PushCardCenter {
    public static let shared = PushCardCenter()

    private var dependency: PushCardDependency? {
        UIDependencyManager.dependency?.pushCard
    }

    public func postCard(id: String, isHighPriority: Bool, extraParams: [String: Any]?, view: UIView, tap: ((String) -> Void)?) {
        dependency?.postCard(id: id, isHighPriority: isHighPriority, extraParams: extraParams, view: view, tap: tap)
    }

    public func remove(with id: String, changeToStack: Bool) {
        dependency?.remove(with: id, changeToStack: changeToStack)
    }

    public func findPushCard(id: String, isBusy: Bool?) -> String? {
        dependency?.findPushCard(id: id, isBusy: isBusy)
    }

    public func update(with id: String) {
        dependency?.update(with: id)
    }
}
