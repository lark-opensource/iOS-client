//
//  WaterMarkMonitor.swift
//  LarkWaterMark
//
//  Created by ByteDance on 2022/12/6.
//

import UIKit
import Foundation
import LarkSecurityComplianceInfra

struct WaterMarkMonitor {
    
    func monitorWaterMarkManagerOnInit(isSingleton: Bool, extra: [String: Any]? = nil) {
        SCMonitor.info(business: .watermark, eventName: isSingleton ? "water_mark_shared_manager_initialized" : "water_mark_manager_initialized", category: extra)
    }
    
    func monitorWaterMarkRemoval(extra: [String: Any]? = nil) {
        SCMonitor.info(business: .watermark, eventName: "view_on_removal", category: extra)
    }
    
    func monitorWaterMarkFetchResult(_ event: String, status: Int, extra: [String: Any?]? = nil) {
        var category: [String: Any] = ["status": status]
        if let extra = extra {
            category = category.merging(extra as [String: Any], uniquingKeysWith: { $1 })
        }
        SCMonitor.info(business: .watermark, eventName: event, category: category)

        if status == 1 {
            SCMonitor.error(business: .watermark, eventName: event)
        }
    }
    
    func monitorWaterMarkPush(extra: [String: Any]? = nil) {
        SCMonitor.info(business: .watermark, eventName: "receive_sdk_push", category: extra)
    }
    
    func monitorHiddenWaterMarkLoadImage(status: Int, extra: [String: Any?]? = nil) {
        var category: [String: Any] = ["status": status]
        if let extra = extra {
            category = category.merging(extra as [String: Any], uniquingKeysWith: { $1 })
        }
        
        SCMonitor.info(business: .watermark, eventName: "hidden_watermark_load_image", category: category)
        if status == 1 {
            SCMonitor.error(business: .watermark, eventName: "hidden_watermark_load_image")
        }
        
    }
    
    func monitorWaterMarkStatusOnSetup(extra: [String: Any?]? = nil) {
        if #available(iOS 13.0, *) {
            UIApplication.shared.connectedScenes.forEach { (scene) in
                guard let windowScene = scene as? UIWindowScene,
                      let rootWindow = self.rootWindowForScene(scene: windowScene) else { return }
                self.monitorWaterMarkShow(on: rootWindow, extra: extra)
            }
        } else {
            guard let delegate = UIApplication.shared.delegate,
                let weakWindow = delegate.window,
                let rootWindow = weakWindow else { return }
            self.monitorWaterMarkShow(on: rootWindow, extra: extra)
        }
    }
        
    private func monitorWaterMarkShow(on window: UIWindow, extra: [String: Any?]? = nil) {
        guard let waterMarkView = window.subviews.first(where: { $0.isKind(of: WaterMarkView.self) }) as? WaterMarkView else {
            SCMonitor.error(business: .watermark, eventName: "did_show")
            return
        }
        
        var waterMarkViewCount: Int = 0
        window.subviews.forEach { subView in
            if subView.isKind(of: WaterMarkView.self) {
                waterMarkViewCount += 1
            }
        }
        
        var category: [String: Any] = [
            "obviousEnabled": waterMarkView.obviousWaterMarkShow,
            "hiddenEnabled": waterMarkView.imageWaterMarkShow,
            "isHidden": waterMarkView.isHidden,
            "isFirstView": waterMarkView.isFirstView,
            "textLength": waterMarkView.obviousWaterMarkConfig.text.count,
            "waterMarkCount": waterMarkViewCount
        ]
        if let extra = extra {
            category = category.merging(extra as [String: Any], uniquingKeysWith: { $1 })
        }
        SCMonitor.info(business: .watermark, eventName: "did_show", category: category)
    }
    
    /// find UIScene rootWindow
    @available(iOS 13.0, *)
    private func rootWindowForScene(scene: UIScene) -> UIWindow? {
        guard let scene = scene as? UIWindowScene else {
            return nil
        }
        if let delegate = scene.delegate as? UIWindowSceneDelegate,
            let rootWindow = delegate.window.flatMap({ $0 }) {
            return rootWindow
        }
        return scene.windows.first
    }
}
