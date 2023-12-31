//
//  RichTextJSSerivceManager.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/11.
//

import Foundation
import ThreadSafeDataStructure
import LarkWebViewContainer

final class JSSerivceManager: JSBaseManager {

    func registerServices(for richTextView: DocsRichTextView, larkWebViewBridge: LarkWebViewBridge?) {
        self.larkWebViewBridge = larkWebViewBridge

        register(handler: KeyboardService(dispatch: richTextView.eventDispatch,
                                            jsEngine: richTextView))
        register(handler: ToolbarService(uiResponder: richTextView,
                                           uiDisplayConfig: richTextView,
                                           jsEngine: richTextView))

        register(handler: NotifyService(jsEngine: richTextView))
        register(handler: LoggerService())
        register(handler: MonitorService())
        register(handler: ShowKeyboardService(richTextView))
        register(handler: NotifyHeightChangeService(richTextView))
        register(handler: ServiceWrapper(bridgeConfig: richTextView))
        register(handler: ClipBoardGetService())
        register(handler: ClipBoardSetService())
        register(handler: OpenUrlService(richTextView))
        register(handler: ClipBoardOnPasteDocsService(richTextView))
        register(handler: FGService(jsEngine: richTextView, richTextView))
    }
}

class JSBaseManager {
//    private(set) var handlers: [JSServiceHandler] = []
    private(set) var handlers: SafeArray<JSServiceHandler> = [] + .semaphore
    var larkWebViewBridge: LarkWebViewBridge?

    private let handerQueue = DispatchQueue(label: "com.bytedance.calendar.richTextEditor.handler.\(UUID().uuidString)")
    var isBusy: Bool = false

    @discardableResult
    // JS注册的handler实际上是通过LarkWebViewBridge触发
    func register(handler: JSServiceHandler) -> JSServiceHandler {
        handlers.append(handler)
        // JSService适配LarkWebViewBridge
        if let bridge = larkWebViewBridge {
            handler.handleServices.forEach {
                bridge.registerAPIHandler(handler, name: $0.rawValue)
            }
        }
        return handler
    }

}
