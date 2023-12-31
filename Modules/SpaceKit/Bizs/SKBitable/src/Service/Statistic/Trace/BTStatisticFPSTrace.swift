//
//  BTStatisticServiceFPSProtocol.swift
//  SKFoundation
//
//  Created by 刘焱龙 on 2023/8/31.
//

import Foundation
import SKFoundation
import Heimdallr
import RxCocoa
import RxSwift
import ThreadSafeDataStructure

protocol BTStatisticFPSCallback: AnyObject {
    func fpsTrace(trace: BTStatisticTrace, dropFrame: [AnyHashable : Any])
}

final class BTStatisticFPSTrace: BTStatisticBaseTrace {
    private static let tag = "FpsTracer"

    private var refCount = 0

    public weak var fpsCallback: BTStatisticFPSCallback?

    private var dropCounts: [AnyHashable: Int] {
        get { _dropCounts.getImmutableCopy() }
        set { _dropCounts.replaceInnerData(by: newValue) }
    }
    private var _dropCounts: SafeDictionary<AnyHashable, Int> = [:] + .semaphore

    private var dropDurations: [AnyHashable: Double] {
        get { _dropDurations.getImmutableCopy() }
        set { _dropDurations.replaceInnerData(by: newValue) }
    }
    private var _dropDurations: SafeDictionary<AnyHashable, Double> = [:] + .semaphore
    private var totalDuration: Double = 0
    private var hitchDuration: Double = 0

    private var delayStopItem: DispatchWorkItem?

    private var disposeBag = DisposeBag()

    private lazy var fpsMonitor = DocsFPSMonitor(mode: .accumulate)
    private var lastFpsResumeTimestamp = 0

    private var fpsDropCallbackOject: HMDMonitorCallbackObject?

    private var isBindScrollView = false
    private var isScrolling = false

    private static var currentTimestamp: Int {
        return Int(Date().timeIntervalSince1970 * 1000)
    }

    init(parentTraceId: String?, traceProvider: BTStatisticTraceInnerProvider?) {
        super.init(type: .fps, parentTraceId: parentTraceId, traceProvider: traceProvider)
    }

    func start() {
        if refCount == 0 {
            clear()
            lastFpsResumeTimestamp = Self.currentTimestamp
            fpsMonitor.resume()
            fpsDropCallbackOject = HMDFrameDropMonitor.shared().addCallbackObject { [weak self] record in
                self?.handleFPSDrop(record: record)
            }
        }
        refCount += 1
    }

    func start(autoStopMills: Int) {
        cancelStopDelay()
        start()
        stop(delayMills: autoStopMills)
    }

    override func stop() {
        refCount -= 1
        if refCount <= 0 {
            refCount = 0
            let averageFPS = fpsMonitor.stop()
            HMDFrameDropMonitor.shared().remove(fpsDropCallbackOject)
            report(averageFPS: averageFPS)
            clear()
        }
    }

    func forceStopAndReportAll() {
        refCount = 0
        stop()
    }

    func bind(scrollView: UIScrollView) {
        isBindScrollView = true

        // 移除之前的订阅
        disposeBag = DisposeBag()

        scrollView.rx.willBeginDragging.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.isScrolling = true
            self.cancelStopDelay()
            self.start()
        }).disposed(by: disposeBag)
        scrollView.rx.didEndDragging.subscribe(onNext: { [weak self] decelerate in
            guard let self = self else { return }
            if !decelerate {
                // slardar handleFPSDrop 是滚动结束回调，所有这里 delay 1s 等待 handleFPSDrop 回调
                self.stop(delayMills: 1000)
                self.isScrolling = false
            }
        }).disposed(by: disposeBag)
        scrollView.rx.didEndDecelerating.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.stop(delayMills: 1000)
            self.isScrolling = false
        }).disposed(by: disposeBag)
    }

    private func cancelStopDelay() {
        refCount = 0
        delayStopItem?.cancel()
    }

    private func stop(delayMills: Int) {
        let item = DispatchWorkItem { [weak self] in
            self?.forceStopAndReportAll()
        }
        delayStopItem = item

        let seconds: Double = Double(delayMills) / 1000.0
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: item)
    }

    private func report(averageFPS: Double) {
        let currentLastFpsDuration = Self.currentTimestamp - lastFpsResumeTimestamp
        let currentDropCounts = dropCounts
        let currentDropDurations = dropDurations
        let currentDuration = totalDuration
        let currentHitchDuration = hitchDuration
        BTStatisticManager.serialQueue.async { [weak self] in
            guard let self = self else { return }
            self.consumers.forEach { consumer in
                guard let consumer = consumer as? BTStatisticFPSConsumer, let traceProvider = self.traceProvider else {
                    return
                }
                consumer.consume(
                    trace: self,
                    logger: traceProvider.getLogger(),
                    fpsInfo: BTStatisticFPSInfo(averageFPS: Float(averageFPS), duration: Double(currentLastFpsDuration))
                )
                if let dropFrameRatio = BTStatisticFPSHelper.dropStateRatio(dropCountInfo: currentDropCounts),
                   let dropDurRatio = BTStatisticFPSHelper.dropDurationRatio(
                    dropDurationInfo: currentDropDurations,
                    hitchDuration: currentHitchDuration,
                    duration: currentDuration
                   ) {
                    consumer.consume(
                        trace: self,
                        logger: traceProvider.getLogger(),
                        dropFrameInfo: BTStatisticDropFrameInfo(
                            dropCounts: currentDropCounts,
                            dropDurations: currentDropDurations,
                            dropFrameRatio: dropFrameRatio,
                            dropDurationRatio: dropDurRatio,
                            duration: currentDuration,
                            hitchDuration: currentHitchDuration
                        )
                    )
                }
            }
        }
    }

    private func clear() {
        fpsMonitor.stop()
        HMDFrameDropMonitor.shared().remove(fpsDropCallbackOject)
        cancelStopDelay()
        dropCounts.removeAll()
        dropDurations.removeAll()
        refCount = 0
        totalDuration = 0
        hitchDuration = 0
        lastFpsResumeTimestamp = 0
    }

    private func handleFPSDrop(record: HMDMonitorRecord?) {
        guard let record = record as? HMDFrameDropRecord else {
            DocsLogger.error("[BTStatisticFPSTrace] handleFPS is not HMDFrameDropRecord")
            return
        }
        guard let dropInfo = record.frameDropInfo else {
            DocsLogger.error("[BTStatisticFPSTrace] HMDFrameDropRecord not frameDropInfo")
            return
        }
        guard let hitchDurDic = record.hitchDurDic else {
            DocsLogger.error("[BTStatisticFPSTrace] HMDFrameDropRecord not hitchDurDic")
            return
        }

        // 限制数据量
        if dropCounts.count > BTStatisticConstant.dropMaxCount {
            dropCounts.removeAll()
        }

        Self.merge(newMap: dropInfo, originMap: &dropCounts)

        totalDuration += record.duration
        hitchDuration += record.hitchDuration
        Self.merge(newMap: hitchDurDic, originMap: &dropDurations)

        fpsCallback?.fpsTrace(trace: self, dropFrame: dropInfo)

        if isBindScrollView, !isScrolling {
            forceStopAndReportAll()
        }
    }

    static func merge(newMap: [AnyHashable: Any], originMap: inout [AnyHashable: Int]) {
        for (key, value) in newMap {
            let originV = originMap[key] ?? 0
            let newV = (value as? Int) ?? 0
            originMap[key] = newV + originV
        }
    }

    static func merge(newMap: [AnyHashable: Any], originMap: inout [AnyHashable: Double]) {
        for (key, value) in newMap {
            let originV = originMap[key] ?? 0
            let newV = (value as? Double) ?? 0
            originMap[key] = newV + originV
        }
    }
}
