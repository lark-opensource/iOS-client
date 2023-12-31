//
//  RenderCardCard+Lifecycle.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/8/24.
//

import Foundation
import UniversalCardInterface
import ECOProbeMeta

extension CGSize {
    // 用于判断是否两个不同的尺寸, 用于卡片尺寸更新, 不大于 1 像素的忽略, 避免浮点数引入的区别
    func isDifferentSize(_ size: CGSize) -> Bool {
        return abs(size.width - width) > 1 || abs(size.height - height) > 1
    }
}
extension RenderRouterCardContentComponent: UniversalCardLifeCycleDelegate {
    
    func didStartRender(context: UniversalCardContext?) {
        context?.timing.renderStart = Date()
        createMonitor(code: MessageCardMonitorCodeV2.messagecard_render_start, context: context, startTime: context?.timing.setupFinish).addCategoryValue(MonitorField.CreateTraceID, context?.trace.traceId).flush()
        trackUniversalCardRender(context: context)
    }

    func didStartLoading(context: UniversalCardContext?) {
        context?.timing.loadStart = Date()
        createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_template_load_start, context: context, startTime: context?.timing.renderStart).flush()
    }

    func didLoadFinished(context: UniversalCardContext?) {
        context?.timing.loadFinish = Date()
        createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_template_load_finish, context: context, startTime: context?.timing.loadStart).flush()
    }

    func didFinishRender(context: UniversalCardContext?, info: [AnyHashable : Any]?) {
        context?.timing.renderFinish = Date()
        let monitor = createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_page_render_finish, context: context, startTime: context?.timing.renderStart)
        if let info = info {
            monitor.addCategoryValue(MonitorField.SetupTiming, info)
        }
        monitor.addCategoryValue(MonitorField.RenderType, MonitorField.RenderTypeValue.cardInit.rawValue)
        monitor.addCardTiming(timing: context?.timing).flush()
    }

    func didReceiveError(context: UniversalCardContext?, error: UniversalCardInterface.UniversalCardError) {
        createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_lynx_error, context: context, startTime: context?.timing.renderStart).setCardError(error).flush()
    }

    func didUpdateContentSize(context: UniversalCardContext?, size: CGSize?) {
        Self.logger.info("didUpdateContentSize: \(size)")
        guard let size = size, let preferSize = preferSize, preferSize.isDifferentSize(size) else {
            return
        }
        Self.logger.info("didUpdateContentSize update preferSize: \(size)")
        self.preferSize = size
        self.context?.ability.updatePreview(component: self)
    }

    func didFinishUpdate(context: UniversalCardContext?, info: [AnyHashable : Any]?) {
        context?.timing.renderFinish = Date()
        let monitor = createMonitor(code: EPMClientOpenPlatformCardCode.messagecard_page_render_finish, context: context, startTime: context?.timing.renderStart)
        if let info = info {
            monitor.addCategoryValue(MonitorField.SetupTiming, info)
        }
        monitor.addCategoryValue(MonitorField.RenderType, MonitorField.RenderTypeValue.cardUpdate.rawValue)
        monitor.addCardTiming(timing: context?.timing).flush()
    }
}
