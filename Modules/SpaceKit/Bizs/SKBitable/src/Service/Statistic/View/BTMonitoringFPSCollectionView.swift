//
//  BTMonitoringFPSCollectionView.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/11/28.
//

import Foundation

class BTMonitoringFPSCollectionView: UICollectionView {
    private lazy var fpsConsumer: BTRecordFPSConsumer = {
        let consumer = BTRecordFPSConsumer(scene: scene)
        return consumer
    }()

    private lazy var fpsTrace: BTStatisticFPSTrace? = {
        if BTStatisticManager.shared?.enable(key: "disable_home_fps_monitoring") == true {
            return nil
        }
        guard let trace = BTStatisticManager.shared?.createFPSTrace(parentTrace: nil) else {
            return nil
        }
        return trace
    }()

    private let scene: BTStatisticFPSScene

    required init(
        frame: CGRect,
        collectionViewLayout layout: UICollectionViewLayout,
        scene: BTStatisticFPSScene
    ) {
        self.scene = scene
        super.init(frame: frame, collectionViewLayout: layout)

        setupFPSMonitoring()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupFPSMonitoring() {
        guard let trace = fpsTrace else { return }
        BTStatisticManager.shared?.addFPSConsumer(traceId: trace.traceId, consumer: fpsConsumer)
        trace.bind(scrollView: self)
    }

    deinit {
        if let trace = fpsTrace {
            BTStatisticManager.shared?.removeTrace(traceId: trace.traceId, includeChild: false)
        }
    }
}
