//
//  VideoEngineApplicationDelegate.swift
//  Lark
//
//  Created by liuwanlin on 2018/12/4.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import AppContainer
import LarkContainer
import TTVideoEngine
import LarkAppLog
import LKCommonsLogging

public class VideoEngineApplicationDelegate: ApplicationDelegate {
    public static let config = Config(name: "VideoEngine", daemon: true)
    static let logger = Logger.log(VideoEngineApplicationDelegate.self)

    lazy var traceDelegate = VideoEngineTraceDelegate()

    required public init(context: AppContext) {
        // iOS 12 下系统处理方式
        context.dispatcher.add(observer: self) { (_, _: DidBecomeActive) in
            TTVideoEngine.startOpenGLESActivity()
        }

        context.dispatcher.add(observer: self) { (_, _: WillResignActive) in
            TTVideoEngine.stopOpenGLESActivity()
        }

        let eventManager = TTVideoEngineEventManager.shared()
        if eventManager.delegate == nil {
            eventManager.delegate = traceDelegate
        }
        eventManager.setLogVersion(TTEVENT_LOG_VERSION_NEW)

        // iOS 13 下系统处理方式
        // 由于这两类事件(DidBecomeActive/WillResignActive 和 SceneDidBecomeActive/SceneWillResignActive)是互斥的，
        // 因此即使全部 add 也不会有问题
        #if canImport(CryptoKit)

        if #available(iOS 13.0, *) {
            context.dispatcher.add(observer: self) { (_, _: SceneDidBecomeActive) in
                // 跟 Video 的同学确认过，可以多次调用
                TTVideoEngine.startOpenGLESActivity()
            }

            // 只有所有的 Scene 都到后台时，才停止 GLES Activity
            context.dispatcher.add(observer: self) { (_, context: SceneWillResignActive) in
                let hasForegroundScene = UIApplication.shared.connectedScenes.contains { (scene) -> Bool in
                    return scene.activationState == .foregroundActive && scene != context.scene
                }

                if !hasForegroundScene {
                    TTVideoEngine.stopOpenGLESActivity()
                }
            }
        }
        #endif
    }
}

class VideoEngineTraceDelegate: NSObject, TTVideoEngineEventManagerProtocol {

    var eventHasPosted: Bool = false

    func eventManagerDidUpdate(_ eventManager: TTVideoEngineEventManager) {
        let events = eventManager.popAllEvents()
        LarkAppLog.shared.serialQueue.async {
            for event in events {
                let result = LarkAppLog.shared.tracker.customEvent("log_data", params: event)
                VideoEngineApplicationDelegate.logger.debug("log_data (\(result)): \(event)")
            }
        }
    }

    func eventManagerDidUpdateV2(_ eventManager: TTVideoEngineEventManager, eventName: String, params: [AnyHashable : Any]) {
        if !eventHasPosted {
            eventHasPosted = true
            VideoEngineApplicationDelegate.logger.info("start track")
        }
        guard var event = params as? [String: Any] else {
            VideoEngineApplicationDelegate.logger.error("event format error")
            return
        }
        let uniqueKey = Int64(CFAbsoluteTimeGetCurrent() * 1000)
        event["log_id"] = uniqueKey

        LarkAppLog.shared.serialQueue.async {
            let result = LarkAppLog.shared.tracker.eventV3(eventName, params: params)
            VideoEngineApplicationDelegate.logger.debug("(\(eventName)) \(result): \(event)")
        }

    }
}
