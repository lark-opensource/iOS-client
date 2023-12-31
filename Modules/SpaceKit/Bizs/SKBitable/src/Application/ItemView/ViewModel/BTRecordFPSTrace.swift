//
// Created by liuyanlong.beijing on 2023/9/14.
// Affiliated with SKBitable.
//
// Description:

import SKFoundation

class BTRecordFPSTrace {
    private static let openRecordAutoStopMills = 60_000
    private static let recordListScrollToAutoStopMills = 5_000

    private lazy var openRecordFPSTrace: BTStatisticFPSTrace? = {
        let trace = BTStatisticManager.shared?.createFPSTrace(parentTrace: nil)
        addOpenType(trace: trace)
        trace?.add(consumer: BTRecordFPSConsumer(scene: .native_open_record_1_min))
        return trace
    }()

    private lazy var singleRecordFPSTrace: BTStatisticFPSTrace? = {
        let trace = BTStatisticManager.shared?.createFPSTrace(parentTrace: nil)
        addOpenType(trace: trace)
        trace?.add(consumer: BTRecordFPSConsumer(scene: .native_stage_cell_list_scroll))
        return trace
    }()

    private lazy var recordListFPSTrace: BTStatisticFPSTrace? = {
        let trace = BTStatisticManager.shared?.createFPSTrace(parentTrace: nil)
        addOpenType(trace: trace)
        trace?.add(consumer: BTRecordFPSConsumer(scene: .native_cell_list_scroll))
        return trace
    }()

    private var hasOpenRecordFPSTrace = false
    private var hasSingleRecordFPSTrace = false
    private var hasRecordListFPSTrace = false

    private let openType: String

    init(openType: String) {
        self.openType = openType
    }

    private func addOpenType(trace: BTStatisticFPSTrace?) {
        guard let trace = trace else { return }
        BTStatisticManager.shared?.addTraceExtra(traceId: trace.traceId, extra: [BTStatisticConstant.openType: openType])
    }

    func startOpenRecordTraceAndAutoStop() {
        hasOpenRecordFPSTrace = true
        openRecordFPSTrace?.start(autoStopMills: Self.openRecordAutoStopMills)
    }

    func bindSingleRecord(scrollView: UIScrollView) {
        hasSingleRecordFPSTrace = true
        singleRecordFPSTrace?.bind(scrollView: scrollView)
    }

    func startRecordListScrollToAndAutoStop() {
        hasRecordListFPSTrace = true
        recordListFPSTrace?.start(autoStopMills: Self.recordListScrollToAutoStopMills)
    }

    func forceStopAndReportAll() {
        if hasOpenRecordFPSTrace {
            openRecordFPSTrace?.forceStopAndReportAll()
        }
        if hasSingleRecordFPSTrace {
            singleRecordFPSTrace?.forceStopAndReportAll()
        }
        if hasRecordListFPSTrace {
            recordListFPSTrace?.forceStopAndReportAll()
        }
        if let traceId = openRecordFPSTrace?.traceId {
            BTStatisticManager.shared?.stopTrace(traceId: traceId)
        }
        if let traceId = singleRecordFPSTrace?.traceId {
            BTStatisticManager.shared?.stopTrace(traceId: traceId)
        }
        if let traceId = recordListFPSTrace?.traceId {
            BTStatisticManager.shared?.stopTrace(traceId: traceId)
        }
    }
}
