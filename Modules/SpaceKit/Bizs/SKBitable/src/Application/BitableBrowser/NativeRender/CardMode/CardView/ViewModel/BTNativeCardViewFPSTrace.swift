//
//  BTNativeCardViewFPSTrace.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/13.
//

import Foundation

class BTNativeRenderFPSTrace {
    
    private var hasNativeGridCardListFPSTrace = false
    
    private lazy var nativeGridViewFPSTrace: BTStatisticFPSTrace? = {
        let trace = BTStatisticManager.shared?.createFPSTrace(parentTrace: nil)
        trace?.add(consumer: BTRecordFPSConsumer(scene: .native_grid_card_scroll))
        return trace
    }()
    
    func bindGridCardScrollView(_ scrollView: UIScrollView) {
        hasNativeGridCardListFPSTrace = true
        nativeGridViewFPSTrace?.bind(scrollView: scrollView)
    }
    
    func forceStopAndReportAll() {
        if hasNativeGridCardListFPSTrace {
            nativeGridViewFPSTrace?.forceStopAndReportAll()
        }
    }
    
    func addNativeViewLifecycleComsumer(consumer: BTStatisticConsumer) {
        nativeGridViewFPSTrace?.add(consumer: consumer)
    }
    
    func removeNativeViewLifecycleComsumer(consumer: BTStatisticConsumer) {
        nativeGridViewFPSTrace?.remove(consumer: consumer)
    }
}
