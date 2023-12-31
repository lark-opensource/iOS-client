//
//  CardPreviewRenderLifeCycle.swift
//  LarkOpenPlatform
//
//  Created by zhangjie.alonso on 2023/7/11.
//

import Foundation
import ECOProbe
import LarkMessageCard
import LarkModel
import UniversalCardInterface


public class CardPreviewRenderLifeCycle : MessageCardContainerLifeCycle {

    let trace = OPTraceService.default().generateTrace()
    var timing: MessageCardTiming = (
       initCard: nil, setupFinish: nil,
       renderStart: nil, loadStart: nil, loadFinish: nil, renderFinish: nil
   )
    var cardContent: CardContent
    var cardScene: CardScene
    var renderBusinessType: RenderBusinessType

    init(cardContent: CardContent, cardScene: CardScene,renderBusinessType: RenderBusinessType ) {
        self.cardContent = cardContent
        self.timing.initCard =  Date()
        self.cardScene = cardScene
        self.renderBusinessType = renderBusinessType
    }

    func createMonitor(
        code: OPMonitorCodeProtocol,
        startTime: Date?
    ) -> OPMonitor {
        let monitor = OPMonitor(name: MonitorField.EventName, code: code)
            .tracing(trace)
            .addCategoryValue(MonitorField.ContentLength, cardContent.jsonBody?.count)
        if let start = startTime {
            monitor.setDuration(Date().timeIntervalSince(start))
        }
        monitor.addCategoryValue(MonitorField.RenderBusinessType, renderBusinessType.rawValue)
        monitor.addCategoryValue(MonitorField.Scene, cardScene.rawValue)
        monitor.addCategoryValue(MonitorField.BotID, cardContent.appInfo?.botID)
        monitor.addCategoryValue(MonitorField.AppID, cardContent.appInfo?.appID)
        return monitor
    }

    // 容器开始初始化(准备数据)
    public func didStartSetup() {
        timing.initCard = Date()
    }

    // 容器初始化完毕(数据准备完毕)
    public func didFinishSetup() {
        timing.setupFinish = Date()
    }

    // 开始执行渲染流程(切入主线程, 准备 loadTemplate)
    public func didStartRender(context: MessageCardContainer.Context) {
        timing.renderStart = Date()
        let monitor = createMonitor(code: MessageCardMonitorCodeV2.messagecard_render_start,
                                    startTime: timing.setupFinish)
        monitor.addCategoryValue(MonitorField.TemplateVersion, context.cardSDKVersion)
        monitor.addCategoryValue(MonitorField.SceneAttribute, SceneAttribute().toDic())
        monitor.flush()
    }

    // 容器开始准备加载模板 (load_template开始时的回调)
    public func didStartLoading(context: MessageCardContainer.Context) {
        timing.loadStart = Date()
    }

    // 容器加载模板完毕 (load_template 结束后的回调，可认为完全加载完成)
    public func didLoadFinished(context: MessageCardContainer.Context) {
        timing.loadFinish = Date()
    }

    // 消息卡片首屏渲染完成 (Lynx 首屏渲染完成)
    public func didFinishRender(context: MessageCardContainer.Context, info: [AnyHashable : Any]?) {
        timing.renderFinish = Date()
        let monitor = createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_page_render_finish,
                                    startTime: timing.renderStart)
        monitor.addCategoryValue(MonitorField.TemplateVersion, context.cardSDKVersion)
        if let info = info {
            monitor.addCategoryValue(MonitorField.SetupTiming, info)
        }
        monitor.addCategoryValue(MonitorField.RenderType, MonitorField.RenderTypeValue.cardInit.rawValue)
        monitor.addCardTiming(timing: timing).flush()
    }

    // 消息卡片渲染错误(包含 lynx 错误)
    public func didReceiveError(context: MessageCardContainer.Context, error: MessageCardError) {
        let monitor = createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_lynx_error,
                                    startTime: timing.renderStart)
        monitor.addCategoryValue(MonitorField.TemplateVersion, context.cardSDKVersion)
        monitor.setCardError(error).flush()
    }

    // 收到更新 ContentSize 通知
    public func didUpdateContentSize(context: MessageCardContainer.Context, size: CGSize?) { }

    // 消息卡片渲染刷新
    public func didFinishUpdate(context: MessageCardContainer.Context, info: [AnyHashable : Any]?) { }
}


extension CardPreviewRenderLifeCycle: UniversalCardLifeCycleDelegate {
    public func didStartRender(context: UniversalCardInterface.UniversalCardContext?) {
        timing.renderStart = Date()
        let monitor = createMonitor(code: MessageCardMonitorCodeV2.messagecard_render_start,
                                    startTime: timing.setupFinish)
        monitor.addCategoryValue(MonitorField.TemplateVersion, context?.cardSDKVersion)
        monitor.addCategoryValue(MonitorField.SceneAttribute, SceneAttribute().toDic())
        monitor.flush()
    }

    public func didStartLoading(context: UniversalCardContext?) {
        timing.loadStart = Date()
    }

    public func didLoadFinished(context: UniversalCardContext?) {
        timing.loadFinish = Date()
    }

    public func didFinishRender(context: UniversalCardContext?, info: [AnyHashable : Any]?) {
        timing.renderFinish = Date()
        let monitor = createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_page_render_finish,
                                    startTime: timing.renderStart)
        monitor.addCategoryValue(MonitorField.TemplateVersion, context?.cardSDKVersion)
        if let info = info {
            monitor.addCategoryValue(MonitorField.SetupTiming, info)
        }
        monitor.addCategoryValue(MonitorField.RenderType, MonitorField.RenderTypeValue.cardInit.rawValue)
        monitor.addCardTiming(timing: timing).flush()
    }

    public func didReceiveError(context: UniversalCardContext?, error: UniversalCardError) {
        let monitor = createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_lynx_error,
                                    startTime: timing.renderStart)
        monitor.addCategoryValue(MonitorField.TemplateVersion, context?.cardSDKVersion)
        monitor.setCardError(error).flush()
    }

    public func didUpdateContentSize(context: UniversalCardContext?, size: CGSize?) {}

    public func didFinishUpdate(context: UniversalCardContext?, info: [AnyHashable : Any]?) {}


}
