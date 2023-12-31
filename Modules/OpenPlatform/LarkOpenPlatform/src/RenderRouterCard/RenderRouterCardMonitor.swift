//
//  RenderRouterCardMonitor.swift
//  LarkOpenPlatform
//
//  Created by zhujingcheng on 10/9/23.
//

import Foundation
import ECOProbe
import UniversalCardInterface

enum UniversalCardTrackActionType: String {
    case openLink = "open_link"
    case interaction = "interaction"
}

enum UniversalCardTrackScene: String {
    case message = "message"
    case url = "url"
}

protocol UniversalCardActionServiceMonitor: AnyObject {
    func createMonitor(
        code: OPMonitorCodeProtocol,
        trace: OPTrace,
        cardID: String?,
        startTime: Date?,
        componentTag: String?
    ) -> OPMonitor
    
    func trackUniversalCardClick(
        actionType: UniversalCardTrackActionType,
        elementTag: String?,
        cardID: String?,
        url: String?
    )
}

extension RenderRouterCardContentComponent {
    func createMonitor(code: OPMonitorCodeProtocol, context: UniversalCardContext?, startTime: Date?) -> OPMonitor {
        return _createMonitor(
            code: code,
            trace: context?.renderingTrace,
            data: context?.sourceData,
            startTime: startTime,
            renderBusinessType: .urlPreview
        )
    }
    
    func trackUniversalCardRender(context: UniversalCardContext?) {
        let teaEventName = "openplatform_universal_card_view"
        let monitor = OPMonitor(teaEventName)
            .addCategoryValue(MonitorField.BizID, context?.sourceData?.bizID)
            .addCategoryValue(MonitorField.Scene, UniversalCardTrackScene.url.rawValue)
            .addCategoryValue(MonitorField.ApplicationID, context?.sourceData?.appInfo?.appID)
            .setPlatform(.tea)
        if let cardID = context?.sourceData?.cardID, let version = context?.sourceData?.version {
            monitor.addCategoryValue(MonitorField.CardID, "\(cardID)#\(version)")
        }
        monitor.flush()
    }
}

extension UniversalCardActionService: UniversalCardActionServiceMonitor {
    func createMonitor(
        code: OPMonitorCodeProtocol,
        trace: OPTrace,
        cardID: String?,
        startTime: Date? = nil,
        componentTag: String? = nil
    ) -> OPMonitor {
        return _createMonitor(
            code: code,
            trace: trace,
            startTime: startTime,
            renderBusinessType: .urlPreview,
            componentTag: componentTag
        ).addCategoryValue(MonitorField.CardID, cardID)
    }
    
    func trackUniversalCardClick(
        actionType: UniversalCardTrackActionType,
        elementTag: String?,
        cardID: String?,
        url: String? = nil
    ) {
        let teaEventName = "openplatform_universal_card_click"
        let monitor = OPMonitor(teaEventName)
            .addCategoryValue(MonitorField.ActionType, actionType.rawValue)
            .addCategoryValue(MonitorField.ElementType, elementTag)
            .addCategoryValue(MonitorField.Scene, UniversalCardTrackScene.url.rawValue)
            .addCategoryValue(MonitorField.BizID, bizID)
            .setPlatform(.tea)
        
        if let cardID = cardID {
            monitor.addCategoryValue(MonitorField.CardID, "\(cardID)#\(version)")
        }
        if let url = url {
            url.setUrlMonitorCategoryValue(monitor: monitor)
        }
        monitor.flush()
    }
}

extension OPMonitor {
    func setCardError(_ error: UniversalCardError) -> OPMonitor {
        return setErrorCode(String(error.errorCode))
            .setErrorMessage(error.errorMessage)
            .addCategoryValue(MonitorField.ErrorType, error.errorType)
            .addCategoryValue(MonitorField.ErrorDomain, error.domain)
    }
    
    func addCardTiming(timing: UniversalCardTiming?) -> OPMonitor {
        // 渲染完整耗时, 从 loadTemplate 开始算
        if let finish = timing?.renderFinish, let start = timing?.loadStart {
            addCategoryValue(MonitorField.RenderDuration, finish.timeIntervalSince(start) * 1000)
        }
        // lynx 渲染耗费的时间, 不算 loadtemplate
        if let finish = timing?.renderFinish, let start = timing?.loadFinish {
            addCategoryValue(MonitorField.LynxDuration, finish.timeIntervalSince(start) * 1000)
        }
        // 卡片完整耗时, 从创建 LynxView 开始算
        if let finish = timing?.renderFinish, let start = timing?.renderStart {
            addCategoryValue(MonitorField.CardDuraton, finish.timeIntervalSince(start) * 1000)
        }
        return self
    }
}

fileprivate func _createMonitor(
    code: OPMonitorCodeProtocol,
    trace: OPTrace?,
    data: UniversalCardData? = nil,
    startTime: Date?,
    renderBusinessType: RenderBusinessType? = nil,
    componentTag: String? = nil
) -> OPMonitor {
    let monitor = OPMonitor(name: MonitorField.EventName, code: code)
        .tracing(trace)
        .addCategoryValue(MonitorField.ContentLength, data?.cardContent.card.count)
        .addCategoryValue(MonitorField.Version, data?.version)
        .addCategoryValue(MonitorField.CardID, data?.cardID)
        .addCategoryValue(MonitorField.RenderBusinessType, renderBusinessType?.rawValue)
        .addCategoryValue(MonitorField.ActionComponentTag, componentTag)
        .addCategoryValue(MonitorField.IsUniversalCard, true)
    if trace == nil {
        monitor.addCategoryValue(OPMonitorEventKey.trace_id, "unknown")
    }
    if let start = startTime {
        monitor.setDuration(Date().timeIntervalSince(start))
    }
    

    return monitor
}
