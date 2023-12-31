//
//  LarkPushDataManager.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/4/7.
//

import Foundation
import RxSwift
import RxRelay

class LarkPushDataManager {
    static let shared = LarkPushDataManager()
    private let disposeBag = DisposeBag()

    let dynamicNetStatus = BehaviorRelay<DynamicNetStatus>(value: .excellent)

    init() {
        PushDispatcher
            .shared
            .larkEventChange
            .subscribe(onNext: { [weak self] change in
                switch change {
                case .dynamicNetStatusChange(let value):
                    self?.handleDynamicNetStatusChange(change: value)
                }
        }).disposed(by: disposeBag)
    }
}

extension LarkPushDataManager {
    private func handleDynamicNetStatusChange(change: DynamicNetTypeChange) {
        self.dynamicNetStatus.accept(change.netStatus)
    }
}
