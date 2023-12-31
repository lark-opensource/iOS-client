//
//  VideoEngineApplicationDelegate.swift
//  Lark
//
//  Created by liuwanlin on 2018/12/4.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import AppContainer
import LarkContainer
import TTVideoEngine
import LarkTracker
import LarkAppLog
import LKCommonsLogging
import LarkFeatureGating
import LarkFoundation

public final class VideoEngineApplicationDelegate: ApplicationDelegate {
    public static let config = Config(name: "VideoEngine", daemon: true)
    static let logger = Logger.log(VideoEngineApplicationDelegate.self)

    required public init(context: AppContext) {
        // iOS 12 下系统处理方式
        context.dispatcher.add(observer: self) { (_, _: DidBecomeActive) in
            TTVideoEngine.startOpenGLESActivity()
        }

        context.dispatcher.add(observer: self) { (_, _: WillResignActive) in
            TTVideoEngine.stopOpenGLESActivity()
        }

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
