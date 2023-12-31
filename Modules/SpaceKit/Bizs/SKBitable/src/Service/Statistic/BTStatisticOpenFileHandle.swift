//
//  BTBaseReportService.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/8/28.
//

import Foundation
import SKBrowser
import SKCommon
import SKFoundation
import SKInfra

final class BTStatisticOpenFileHandle {
    private weak var delegate: BTStatisticReportHandleDelegate?

    private var startRenderTimestamp: Int?
    private var delayReportWillRenderItem: DispatchWorkItem?
    private var delayReportFailItem: DispatchWorkItem?
    private var startPreloadTimestamp: Int?

    init(delegate: BTStatisticReportHandleDelegate) {
        self.delegate = delegate
        delegate.addObserver(self)
    }
}

extension BTStatisticOpenFileHandle: BrowserViewLifeCycleEvent {
    func browserBeforeCallRender() {
        startRenderTimestamp = Int(Date().timeIntervalSince1970 * 1000)
    }

    func browserReceiveRenderCallBack(success: Bool, error: Error?) {
        if let traceId = traceId {
            BTOpenFileReportMonitor.reportStopRender(traceId: traceId)
        }
        if !success {
            delayReportRenderFail(error: error)
        }
    }

    func browserStartPreload() {
        startPreloadTimestamp = Int(Date().timeIntervalSince1970 * 1000)
    }

    func browserEndPreload() {
        guard let traceId = traceId else {
            return
        }
        BTOpenFileReportMonitor.reportStopPreload(traceId: traceId)
    }

    func browserViewControllerDidLoad() {
        guard let traceId = traceId else {
            return
        }

        // 模版预加载和 render 的开始时机太早，需要延迟到 vc didLoad 的时候上报 start

        if let timestamp = startPreloadTimestamp {
            BTOpenFileReportMonitor.reportStartPreload(traceId: traceId, timestamp: timestamp)
        }
        if let startRenderTimestamp = startRenderTimestamp {
            BTOpenFileReportMonitor.reportStartRender(traceId: traceId, timestamp: startRenderTimestamp)
        }
    }

    private func delayReportRenderFail(error: Error?) {
        guard let traceId = traceId else {
            return
        }
        cancelReportRenderFail()
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let item = DispatchWorkItem(block: {
            BTOpenFileReportMonitor.reportOpenFail(
                traceId: traceId,
                timestamp: timestamp,
                extra: ["failReason": error?.localizedDescription ?? ""]
            )
        })
        delayReportFailItem = item
        // 兜底上报 fail，延迟上报。优先上报 web 回调的 render fail
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: item)
    }

    private func cancelReportRenderFail() {
        delayReportFailItem?.cancel()
        delayReportFailItem = nil
    }
}

extension BTStatisticOpenFileHandle: BTStatisticReportHandle {
    private static let EVENT_DOCS_RENDER_END = "docs_render_end"
    private static let EVENT_DOCS_EDIT_DOC = "docs_edit_doc"
    private static let EVENT_BITABLE_SDK_FIRST_SCREEN_SUCCESS = "BITABLE_SDK_FIRST_SCREEN_SUCCESS"
    private static let EVENT_BITABLE_SDK_BITABLE_IS_READY = "BITABLE_SDK_BITABLE_IS_READY"
    private static let EVENT_MOBILE_DASHBOARD_TTU = "mobile_dashboard-ttu"
    private static let EVENT_VIEW_OR_BLOCK_SWITCH = "bitable_view_or_block_switch"
    private static let EVENT_BITABLE_SDK_LOAD_COST = "BITABLE_SDK_LOAD_COST"

    private var traceId: String? {
        return delegate?.traceId
    }

    private var isBitable: Bool {
        return delegate?.isBitable ?? false
    }

    private var token: String? {
        return delegate?.token
    }

    private var baseToken: String? {
        return delegate?.baseToken
    }

    private var objTokenInLog: String? {
        return delegate?.objTokenInLog
    }

    func handle(reportItem: BTBaseStatisticReportItem) {
        guard let traceId = traceId else {
            return
        }
        var item = reportItem
        guard let eventName = item.event else {
            return
        }

        if let extra = item.extra, var sdkCost = extra[BTStatisticConstant.sdkCost] as? [String: Any] {
            sdkCost = sdkCost.filter { $0.value is Int }
            item.extra?[BTStatisticConstant.sdkCost] = sdkCost
        }

        checkToken(traceId: traceId, item: item)

        switch eventName {
        case Self.EVENT_DOCS_RENDER_END:
            handleDocsRenderEnd(traceId: traceId, item: item)
        case Self.EVENT_DOCS_EDIT_DOC:
            handleEditDoc(traceId: traceId, item: item)
        case Self.EVENT_BITABLE_SDK_LOAD_COST:
            handleLoadCost(traceId: traceId, item: item)
        default:
            break
        }

        guard isBitable else {
            return
        }

        switch eventName {
        case Self.EVENT_BITABLE_SDK_FIRST_SCREEN_SUCCESS:
            handleFirstScreen(traceId: traceId, item: item)
        case Self.EVENT_BITABLE_SDK_BITABLE_IS_READY:
            handleBitableIsReady(traceId: traceId, item: item)
        case Self.EVENT_MOBILE_DASHBOARD_TTU:
            handleDashBoardTTU(traceId: traceId, item: item)
            break
        case Self.EVENT_VIEW_OR_BLOCK_SWITCH:
            handleViewSwitch(traceId: traceId, item: item)
        default:
            break
        }
    }

    private func checkToken(traceId: String, item: BTBaseStatisticReportItem) {
        let report = { [weak self] in
            guard let self = self else { return }
            DocsLogger.btError("[BTBaseReportService] token is invald \(objTokenInLog ?? ""),,,\(item.event ?? "")")
            BTReportErrorHelper.reportError(
                traceId: traceId,
                reason: BTStatisticErrorType.token_not_match.rawValue,
                extra: ["token": objTokenInLog ?? "", "event": item.event ?? ""]
            )
        }
        if item.event == Self.EVENT_MOBILE_DASHBOARD_TTU {
            if item.token != baseToken {
                report()
            }
        } else if item.token != token {
            report()
        }
    }

    private func handleDashBoardTTU(traceId: String, item: BTBaseStatisticReportItem) {
        BTOpenFileReportMonitor.reportDashBoardTTU(traceId: traceId, timestamp: item.time, extra: item.extra)
    }

    private func handleViewSwitch(traceId: String, item: BTBaseStatisticReportItem) {
        BTOpenFileReportMonitor.reportSwitchViewOrBlock(traceId: traceId, extra: item.extra)
    }

    private func handleDocsRenderEnd(traceId: String, item: BTBaseStatisticReportItem) {
        let time = item.time ?? Int(Date().timeIntervalSince1970 * 1000)
        BTOpenFileReportMonitor.reportEvent(event: item.event, traceId: traceId, timestamp: time, extra: item.extra)

        handleLoadCost(traceId: traceId, item: item)

        let key = item.extra?["docs_result_key"] as? String
        let code = item.extra?["docs_result_code"] as? Int
        let clientVarFrom = (item.extra?["clientvar_from"] as? String) ?? ""
        let success = (key == "other" && code == 0)
        cancelReportRenderFail()
        if success {
            if isBitable {
                BTStatisticManager.shared?.addTraceExtra(traceId: traceId, extra: ["clientvar_from": clientVarFrom])
            } else {
                BTStatisticManager.shared?.addTraceExtra(traceId: traceId, extra: ["docx_clientvar_from": clientVarFrom])
                BTOpenFileReportMonitor.reportOpenDocInBaseTTV(traceId: traceId, timestamp: time)
            }
        } else {
            BTOpenFileReportMonitor.reportOpenFail(traceId: traceId, timestamp: time, extra: item.extra)
        }
    }

    private func handleFirstScreen(traceId: String, item: BTBaseStatisticReportItem) {
        let time = item.time ?? Int(Date().timeIntervalSince1970 * 1000)
        let viewType = item.extra?["viewType"] as? String
        let blockType = item.extra?["blockType"] as? String
        let subViewType = item.extra?["subViewType"] as? String
        let isFormV2 = (item.extra?["isFormV2"] as? Bool) ?? false
        let isFasterRender = (item.extra?["isFasterRender"] as? Bool) ?? false

        handleLoadCost(traceId: traceId, item: item)
        BTStatisticManager.shared?.addTraceExtra(traceId: traceId, extra: [
            BTStatisticConstant.viewType: viewType ?? "",
            BTStatisticConstant.blockType: blockType ?? "",
            BTStatisticConstant.subViewType: subViewType ?? "",
            BTStatisticConstant.isFormV2: isFormV2,
            BTStatisticConstant.isFasterRender: isFasterRender
        ])
        BTOpenFileReportMonitor.reportSdkFirstPaint(
            traceId: traceId,
            timestamp: time,
            extra: [BTStatisticConstant.isFasterRender: isFasterRender, BTStatisticConstant.subViewType: subViewType ?? ""]
        )
        if isFasterRender {
            BTOpenFileReportMonitor.reportOpenFasterTTV(traceId: traceId, timestamp: time)
        }
    }

    private func handleBitableIsReady(traceId: String, item: BTBaseStatisticReportItem) {
        let time = item.time ?? Int(Date().timeIntervalSince1970 * 1000)
        BTOpenFileReportMonitor.reportEvent(event: item.event, traceId: traceId, timestamp: time, extra: item.extra)

        handleLoadCost(traceId: traceId, item: item)

        let isReportTTU = item.extra?["isReportTTU"] as? Bool
        if isReportTTU == true {
            BTOpenFileReportMonitor.reportOpenFasterTTU(traceId: traceId, timestamp: time)
        }
    }

    private func handleEditDoc(traceId: String, item: BTBaseStatisticReportItem) {
        let time = item.time ?? Int(Date().timeIntervalSince1970 * 1000)
        BTOpenFileReportMonitor.reportEvent(event: item.event, traceId: traceId, timestamp: time, extra: item.extra)
        if !isBitable {
            BTOpenFileReportMonitor.reportOpenDocInBaseTTU(traceId: traceId, timestamp: time)
        }
    }

    private func handleLoadCost(traceId: String, item: BTBaseStatisticReportItem) {
        guard let sdkCost = item.extra?[BTStatisticConstant.sdkCost] as? [String: Any] else {
            return
        }
        let source = item.extra?["source"] ?? ""
        BTOpenFileReportMonitor.reportSDKLoadCost(traceId: traceId, extra: [BTStatisticConstant.sdkCost: sdkCost, "sdk_cost_source": source])
    }
}
