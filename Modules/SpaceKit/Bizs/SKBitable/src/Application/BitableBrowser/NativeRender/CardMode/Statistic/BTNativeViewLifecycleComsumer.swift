//
//  BTNativeViewLifecycleComsumer.swift
//  SKBitable
//
//  Created by zoujie on 2023/12/1.
//

import Foundation
import SKInfra
import SKFoundation

struct BTNativeViewLifecycleBridgeInfo: Hashable {
    var strategy: String
    var processDuration: CGFloat // 前端数据处理时长
    var bridgeDuration: CGFloat // native数据解析时长
    var size: Int // 数据长度
}

final class BTNativeViewLifecycleComsumer: BTStatisticConsumer, BTStatisticNormalConsumer, BTStatisticFPSConsumer {
    
    var clickGroup: Int = 0
    var visitRow: Int = 0
    var longPress: Int = 0
    var hasVisibleLimit: Bool = false
    private var bridgeInfos: [BTNativeViewLifecycleBridgeInfo] = []
    private var _fps: [BTStatisticFPSInfo] = []
    private var _dropFrame: [BTStatisticDropFrameInfo] = []
    
    func consume(
        trace: BTStatisticBaseTrace,
        logger: BTStatisticLoggerProvider,
        currentPoint: BTStatisticNormalPoint,
        allPoint: [BTStatisticNormalPoint]
    ) -> [BTStatisticNormalPoint] {
        let fpsCount = _fps.count
        var duration: Double = 0
        var averageFPS: Float = 0
        if fpsCount > 0 {
            duration = _fps.reduce(0, { $0 + $1.duration }) / Double(fpsCount)
            averageFPS = Float(_fps.reduce(0, { $0 + Int($1.averageFPS) })) / Float(fpsCount)
        }
        
        var reportDropFrame: [BTStatisticDropFrameInfo] = []
        let dropFrameEnd = _dropFrame.count
        if dropFrameEnd > 0 {
            // 只上报100条数据
            let dropFrameStart = max(0, dropFrameEnd - 100)
            reportDropFrame = Array(_dropFrame[dropFrameStart...dropFrameEnd - 1])
        }
        
        var params: [String: Any] = currentPoint.extra
        params["clickGroup"] = clickGroup
        params["longPress"] = longPress
        params["visitRow"] = visitRow
        params["bridge"] = bridgeInfos
        params["fps"] = ["duration": duration,
                         "averageFPS": averageFPS]
        params["dropFrame"] = reportDropFrame
    
        if let schemaVersion = params["schemaVersion"], hasVisibleLimit {
            var traceParams = trace.getExtra(includeParent: false)
            traceParams["schema_version"] = schemaVersion
            logger.send(trace: trace, eventName: DocsTracker.EventType.bitableRowExpandRecordLimitView.rawValue, params: traceParams)
        }
        
        logger.send(trace: trace, eventName: currentPoint.name, params: params)
        reset()
        // 在这里最终report
        return allPoint
    }

    func consumeTempPoint(
        trace: BTStatisticBaseTrace,
        currentPoint: BTStatisticNormalPoint,
        allPoint: [BTStatisticNormalPoint]
    ) -> [BTStatisticNormalPoint] {
        return allPoint
    }
    
    func consume(trace: BTStatisticFPSTrace, logger: BTStatisticLoggerProvider, fpsInfo: BTStatisticFPSInfo) {
        guard fpsInfo.duration != 0 && fpsInfo.averageFPS != 0 else { return }
        _fps.append(fpsInfo)
    }
    
    func consume(trace: BTStatisticTrace, logger: BTStatisticLoggerProvider, dropFrameInfo: BTStatisticDropFrameInfo) {
        _dropFrame.append(dropFrameInfo)
    }
    
    func updateBridgeInfo(model: CardPageModel) {
        let bridgeDuration = Date().timeIntervalSince1970 * 1000 - (model.updateStrategy?.bridgeStart ?? 0)
        let modelSize = String(describing: model).count
        let newBridgeInfo = BTNativeViewLifecycleBridgeInfo(strategy: model.updateStrategy?.strategy.rawValue ?? "",
                                                            processDuration: model.updateStrategy?.processDuration ?? 0,
                                                            bridgeDuration: bridgeDuration,
                                                            size: modelSize)
        
        bridgeInfos.append(newBridgeInfo)
    }
    
    func reset() {
        bridgeInfos.removeAll()
        _fps.removeAll()
        _dropFrame.removeAll()
        clickGroup = 0
        visitRow = 0
        longPress = 0
    }
}
