//
//  ThermalStateMonitor.swift
//  ByteView
//
//  Created by liujianlong on 2021/6/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxRelay
import RxSwift

final class ThermalStateMonitor {
    static let shared = ThermalStateMonitor()
    private let thermalStateRelay: BehaviorRelay<ProcessInfo.ThermalState>
    var thermalStateObservable: Observable<ProcessInfo.ThermalState> {
        return thermalStateRelay.asObservable()
    }

    var thermalState: ProcessInfo.ThermalState {
        thermalStateRelay.value
    }

    private init() {
        self.thermalStateRelay = BehaviorRelay(value: ProcessInfo.processInfo.thermalState)
        _ = NotificationCenter.default.rx.notification(ProcessInfo.thermalStateDidChangeNotification)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { notification in
                guard let processInfo = notification.object as? ProcessInfo else {
                    assertionFailure()
                    return
                }
                self.thermalStateRelay.accept(processInfo.thermalState)
            })
    }

}
