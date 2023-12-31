//
//  ReportService.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/8/17.
//
// JS 做各种上报的地方

import Foundation
import WebKit
import os
import SKCommon
import SKFoundation
import LarkSceneManager
import SKUIKit

class ReportService: BaseJSService {
    var isSSRWebView: Bool { false }
    var renderSSRType: RenderSSRWebviewType { .none }
}

extension ReportService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.reportSendEvent, .reportReportEvent]
    }

    func handle(params: [String: Any], serviceName: String) {
        guard let openSessionID = model?.browserInfo.openSessionID else { return }
        guard let editorIdentity = model?.jsEngine.editorIdentity else { return }
        guard URLValidator.isMainFrameTemplateURL(model?.requestAgent.currentUrl) == false else { return }

        switch serviceName {
        case DocsJSService.reportReportEvent.rawValue:
            reportToServer(params, openSessionID: openSessionID, editorIdentity: editorIdentity)
        case DocsJSService.reportSendEvent.rawValue:
            saveData(params, openSessionID: openSessionID, editorIdentity: editorIdentity)
        default:
            spaceAssertionFailure("event \(serviceName) not handled")
        }
    }
}

extension ReportService {
    enum EventType: Int {
        case reportFileInfo = 1
        case stageBegin = 2
        case stageEnd = 3
    }

    private func reportToServer(_ params: [String: Any], openSessionID: String, editorIdentity: String) {
        guard let eventName = params["event_name"] as? String,
        let data = params["data"] as? [String: Any] else {
            return
        }
        if eventName == DocsTracker.EventType.feedV2Stage.rawValue {
            DocsLogger.info("----<V2打开耗时\(data)")
            DocsTracker.log(enumEvent: .feedV2Stage, parameters: data)
        } else if eventName == DocsTracker.EventType.feedV2Error.rawValue {
            DocsLogger.info("----<V2打开耗时\(data)")
            DocsTracker.log(enumEvent: .feedV2Error, parameters: data)
        } else {
            spaceAssert(eventName.isEmpty == false, "eventName is empty!")
            OpenFileRecord.reportStatisticsToServerFor(sessionID: openSessionID, eventName: eventName, params: data)
            reportInfoToUserIfNeed(params)
        }

    }

    private func saveData(_ params: [String: Any], openSessionID: String, editorIdentity: String) {
        guard let eventTypeRaw = params["event_type"] as? Int,
            let eventType = EventType(rawValue: eventTypeRaw),
            let data = params["data"] as? [String: Any] else {
                spaceAssertionFailure()
            return
        }

        switch eventType {
        case .reportFileInfo:
            OpenFileRecord.updateFileinfo(data, for: openSessionID)
        case .stageBegin:
            guard let stage = data[OpenFileRecord.ReportKey.stage.rawValue] as? String else {
                return
            }
            DocsLogger.info("ReportService \(stage) stageBegin，ssrwebview:\(self.isSSRWebView)", extraInfo: ["editorId": editorIdentity, "params": data], component: LogComponents.fileOpen)
            tracingWhenStart(stage: stage)
            if stage == OpenFileRecord.Stage.pullData.rawValue {
                OpenFileRecord.endRecordTimeConsumingFor(sessionID: openSessionID, stage: OpenFileRecord.Stage.pullJS.rawValue, parameters: data)
            }
            OpenFileRecord.startRecordTimeConsumingFor(sessionID: openSessionID, stage: stage, parameters: data)
            reportStageBeginToUserIfNeed(stage)
        case .stageEnd:
            guard let stage = data[OpenFileRecord.ReportKey.stage.rawValue] as? String else {
                let info = ["browserView": editorIdentity, "params": "\(data)"]
                DocsLogger.info("no openRecord identifier", extraInfo: info, error: nil, component: LogComponents.fileOpen)
                return
            }
            var params = data
            params["isSSRWebView"] = self.isSSRWebView
            if stage == OpenFileRecord.Stage.renderDoc.rawValue {
                model?.vcFollowDelegate?.followDidRenderFinish()
                if SceneManager.shared.supportsMultipleScenes,
                   #available(iOS 13.0, *), SKDisplay.pad,
                   let sceneInfo = navigator?.currentBrowserVC?.currentScene()?.sceneInfo {
                    params["im_aux_window"] = !sceneInfo.isMainScene()
                }
            } else if stage == OpenFileRecord.Stage.renderCache.rawValue {
                OpenFileRecord.updateFileinfo(["isSSRWebView": self.isSSRWebView], for: openSessionID)
                OpenFileRecord.updateFileinfo(["doc_html_cache_from": self.renderSSRType.rawValue], for: openSessionID)
            }
            DocsLogger.info("ReportService \(stage) stageEnd，ssrwebview:\(self.isSSRWebView)", extraInfo: ["editorId": editorIdentity, "params": data], component: LogComponents.fileOpen)
            tracingWhenEnd(stage: stage, params: params)
            OpenFileRecord.endRecordTimeConsumingFor(sessionID: openSessionID, stage: stage, parameters: params)
            reportStageEndToUserIfNeed(stage)
        }
    }
    
    func tracingWhenStart(stage: String) {
        guard let traceRootId = (self.navigator?.currentBrowserVC as? SKTracableProtocol)?.traceRootId else {
            DocsLogger.info("tracingWhenStart get rootId fail", extraInfo: ["stage": stage], component: LogComponents.fileOpen)
            return
        }
        switch stage {
        case OpenFileRecord.Stage.pullData.rawValue:
            SKTracing.shared.endSpan(spanName: SKBrowserTrace.pullJS, rootSpanId: traceRootId, component: LogComponents.fileOpen)
            SKTracing.shared.startChild(spanName: SKBrowserTrace.pullData, rootSpanId: traceRootId, component: LogComponents.fileOpen)
        case OpenFileRecord.Stage.renderDoc.rawValue:
            SKTracing.shared.startChild(spanName: SKBrowserTrace.renderDoc, rootSpanId: traceRootId, component: LogComponents.fileOpen)
        default: break
        }
    }
    
    func tracingWhenEnd(stage: String, params: [String: Any]) {
        guard let traceRootId = (self.navigator?.currentBrowserVC as? SKTracableProtocol)?.traceRootId else {
            return
        }
        switch stage {
        case OpenFileRecord.Stage.renderDoc.rawValue:
            SKTracing.shared.endSpan(spanName: SKBrowserTrace.renderDoc, rootSpanId: traceRootId, params: params, component: LogComponents.fileOpen)
        case OpenFileRecord.Stage.pullData.rawValue:
            SKTracing.shared.endSpan(spanName: SKBrowserTrace.pullData, rootSpanId: traceRootId, params: params, component: LogComponents.fileOpen)
        default: break
        }
    }
}

// MARK: - 如果需要，把信息告展示在界面上
private extension ReportService {
    func reportInfoToUserIfNeed(_ params: [String: Any]) {
        guard let eventName = params["event_name"] as? String,
            let data = params["data"] as? [String: Any] else {
                return
        }
        if eventName == "scm" {
            model?.openRecorder.appendInfo("\(eventName): \(data)")
        }
    }

    func reportStageBeginToUserIfNeed(_ stage: String) {
        model?.openRecorder.appendInfo("stage begin: \(stage)")
    }

    func reportStageEndToUserIfNeed(_ stage: String) {
        model?.openRecorder.appendInfo("stage end: \(stage)")
    }
}
