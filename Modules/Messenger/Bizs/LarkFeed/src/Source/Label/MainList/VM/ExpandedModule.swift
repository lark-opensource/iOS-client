//
//  ExpandedModule.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/21.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkAccountInterface

final class ExpandedModule {
    private let disposeBag = DisposeBag()
    private var expandMap: [Int: Bool] = [:]  // 展开收起状态
    let userId: String

    init(userID: String) {
        self.userId = userID
        if let expandMap = getLastLabelsExpandedState() {
            self.expandMap = expandMap
        }
        observeApplicationNotification()
    }
}

// MARK: 设置展开收起状态
extension ExpandedModule {
    func updateExpandState(id: Int, isExpand: Bool) {
        assert(Thread.isMainThread, "dataSource is only available on main thread")
        self.expandMap[id] = isExpand
    }

    func getExpandState(id: Int) -> Bool? {
        assert(Thread.isMainThread, "dataSource is only available on main thread")
        return self.expandMap[id]
    }

    func toggleExpandState(id: Int) {
        if let expand = getExpandState(id: id), expand {
            updateExpandState(id: id, isExpand: false)
        } else {
            updateExpandState(id: id, isExpand: true)
        }
    }
}

// MARK: 磁盘存储展开收起状态
extension ExpandedModule {
    private func observeApplicationNotification() {
        NotificationCenter.default.rx
            .notification(UIApplication.didEnterBackgroundNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.saveLabelsExpandedState()
            }).disposed(by: disposeBag)
    }

    private func saveLabelsExpandedState() {
        FeedKVStorage(userId: userId).saveLabelsExpandedState(expandMap)
    }

    private func getLastLabelsExpandedState() -> [Int: Bool]? {
        return FeedKVStorage(userId: userId).getLastLabelsExpandedState()
    }
}
