//
//  MessageCardViewModel+LifeCycle.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/10/24.
//

import Foundation
import LarkMessageCard
import ECOProbe
import UniversalCardInterface

extension MessageCardViewModel: MessageCardContainerLifeCycle {

    public func didStartRender(context cardContext: MessageCardContainer.Context) {
        timing.renderStart = Date()
        let sceneAttr = SceneAttribute(
            isEphemeral: message.isEphemeral,
            isForward: self.content?.jsonAttachment?.isForward ?? false,
            translateState: getRenderType(message, scene: self.context.scene).rawValue,
            isConfigCardLink: content?.jsonBody?.contains("cardLinkUrl") ?? false,
            isMergeForward: self.context.scene == .mergeForwardDetail)

        createMonitor(
            code: MessageCardMonitorCodeV2.messagecard_render_start,
            context: cardContext,
            trace: cardContext.renderTrace,
            startTime: timing.setupFinish,
            renderBusinessType: .message
        )
        .addCategoryValue(MonitorField.SceneAttribute, sceneAttr.toDic())
        .addCategoryValue(MonitorField.CreateTraceID, cardContext.trace.traceId)
            .flush()
    }

    public func didStartLoading(context cardContext: MessageCardContainer.Context) {
        timing.loadStart = Date()
        createMonitor(
            code: EPMClientOpenPlatformCardCode.messagecard_template_load_start,
            context: cardContext,
            trace: cardContext.renderTrace,
            startTime: timing.renderStart)
            .flush()
    }

    public func didLoadFinished(context cardContext: MessageCardContainer.Context) {
        timing.loadFinish = Date()
        createMonitor(
            code: EPMClientOpenPlatformCardCode.messagecard_template_load_finish,
            context: cardContext,
            trace: cardContext.renderTrace,
            startTime: timing.loadStart)
            .flush()
    }

    public func didFinishRender(context cardContext: MessageCardContainer.Context, info: [AnyHashable : Any]?) {
        timing.renderFinish = Date()
        if !didSetupBizsEnv {
            setupBizsEnv(message: self.message)
            didSetupBizsEnv = true
        }
        let monitor = createMonitor(
            code: EPMClientOpenPlatformCardCode.messagecard_page_render_finish,
            context: cardContext,
            trace: cardContext.renderTrace,
            startTime: timing.renderStart
        )
        if let info = info {
            monitor.addCategoryValue(MonitorField.SetupTiming, info)
        }
        monitor.addCategoryValue(MonitorField.RenderType, MonitorField.RenderTypeValue.cardInit.rawValue)
        monitor.addCardTiming(timing: timing).flush()
    }

    public func didReceiveError(context cardContext: MessageCardContainer.Context, error: LarkMessageCard.MessageCardError) {
        createMonitor(
            code: EPMClientOpenPlatformCardCode.messagecard_lynx_error,
            context: cardContext,
            trace: cardContext.renderTrace,
            startTime: timing.renderStart
        ).setCardError(error).flush()
    }

    public func didUpdateContentSize(context: MessageCardContainer.Context, size: CGSize?) {
        logger.info("didUpdateContentSize \(message.id) : new:  \(size) old: \(self.currentSize)")
        if let width = size?.width, let height = size?.height {
            if let currentSize = currentSize,
               abs(currentSize.width - width) > 0.1 || abs(currentSize.height - height) > 0.1 {
                logger.info("didUpdateContentSize \(message.id) \(size ?? .zero)")
                self.currentSize = size
                self.syncToBinder()
                if enableForceUpdateCell {
                    self.updateForced(component: binder.component, animation: .none)
                } else {
                    self.update(component: binder.component, animation: .none)
                }
            }
            self.currentSize = size
        }
    }

    public func didFinishUpdate(context cardContext: MessageCardContainer.Context, info: [AnyHashable : Any]?) {
        timing.renderFinish = Date()
        let monitor = createMonitor(
            code: EPMClientOpenPlatformCardCode.messagecard_page_render_finish,
            context: cardContext,
            trace: cardContext.renderTrace,
            startTime: timing.renderStart
        )
        if let info = info {
            monitor.addCategoryValue(MonitorField.SetupTiming, info)
        }
        monitor.addCategoryValue(MonitorField.RenderType, MonitorField.RenderTypeValue.cardUpdate.rawValue)
        monitor.addCardTiming(timing: timing).flush()
    }

    public func didUpdate(context: MessageCardContainer.Context) {
    }
}

extension MessageCardViewModel: UniversalCardLifeCycleDelegate {
    func didStartSetup() {
        timing.initCard = Date()
    }

    func didFinishSetup() {
        timing.setupFinish = Date()
        createMonitor(
            code: MessageCardMonitorCodeV2.messagecard_create_view_finish,
            context: nil,
            trace: self.trace,
            startTime: timing.initCard)
            .flush()
    }

    func didStartRender(context: UniversalCardContext?) {
        context?.timing.initCard = timing.initCard
        context?.timing.setupFinish = timing.setupFinish
        context?.timing.renderStart = Date()
        let sceneAttr = SceneAttribute(
            isEphemeral: message.isEphemeral,
            isForward: self.content?.jsonAttachment?.isForward ?? false,
            translateState: getRenderType(message, scene: self.context.scene).rawValue,
            isConfigCardLink: content?.jsonBody?.contains("cardLinkUrl") ?? false,
            isMergeForward: self.context.scene == .mergeForwardDetail
        )

        createRenderMonitor(
            code: MessageCardMonitorCodeV2.messagecard_render_start,
            context: context,
            startTime: context?.timing.setupFinish
        )
        .addCategoryValue(MonitorField.SceneAttribute, sceneAttr.toDic())
        .addCategoryValue(MonitorField.CreateTraceID, context?.trace.traceId)
        .flush()
        
        trackUniversalCardRender(context: context)
    }

    func didStartLoading(context: UniversalCardContext?) {
        context?.timing.loadStart = Date()
        createRenderMonitor(
            code: EPMClientOpenPlatformCardCode.messagecard_template_load_start,
            context: context,
            startTime: context?.timing.renderStart
        ).flush()
    }

    func didLoadFinished(context: UniversalCardContext?) {
        context?.timing.loadFinish = Date()
        createRenderMonitor(
            code: EPMClientOpenPlatformCardCode.messagecard_template_load_finish,
            context: context,
            startTime: context?.timing.loadStart
        ).flush()
    }

    func didFinishRender(context: UniversalCardContext?, info: [AnyHashable : Any]?) {
        context?.timing.renderFinish = Date()
        if !didSetupBizsEnv {
            setupBizsEnv(message: self.message)
            didSetupBizsEnv = true
        }
        let monitor = createRenderMonitor(
            code: EPMClientOpenPlatformCardCode.messagecard_page_render_finish,
            context: context,
            startTime: context?.timing.renderStart
        )
        if let info = info { monitor.addCategoryValue(MonitorField.SetupTiming, info) }
        monitor.addCategoryValue(MonitorField.RenderType, MonitorField.RenderTypeValue.cardInit.rawValue)
        monitor.addCardTiming(timing: context?.timing).flush()
    }

    func didReceiveError(context: UniversalCardContext?, error: UniversalCardInterface.UniversalCardError) {
        createRenderMonitor(
            code: EPMClientOpenPlatformCardCode.messagecard_lynx_error,
            context: context,
            startTime: context?.timing.renderStart
        ).setCardError(error).flush()
    }

    func didUpdateContentSize(context: UniversalCardContext?, size: CGSize?) {
        guard let size = size else {
            logger.info("didUpdateContentSize: \(size ?? .zero)", additionalData: [
                "traceID": context?.trace.traceId ?? "",
                "cardID": message.id
            ])
            return
        }
        if let currentSize = currentSize, currentSize.isDifferentSize(size) {
            logger.info("didUpdateContentSize update currentSize: \(size )", additionalData: [
                "traceID": context?.trace.traceId ?? "",
                "cardID": message.id
            ])
            self.currentSize = size
            self.syncToBinder()
            if enableForceUpdateCell {
                self.updateForced(component: binder.component, animation: .none)
            } else {
                self.update(component: binder.component, animation: .none)
            }
        }
        self.currentSize = size
    }

    func didFinishUpdate(context: UniversalCardContext?, info: [AnyHashable : Any]?) {
        context?.timing.renderFinish = Date()
        let monitor = createRenderMonitor(
            code: EPMClientOpenPlatformCardCode.messagecard_page_render_finish,
            context: context,
            startTime: context?.timing.renderStart
        )
        if let info = info {
            monitor.addCategoryValue(MonitorField.SetupTiming, info)
        }
        monitor.addCategoryValue(MonitorField.RenderType, MonitorField.RenderTypeValue.cardUpdate.rawValue)
        monitor.addCardTiming(timing: context?.timing).flush()
    }
}
