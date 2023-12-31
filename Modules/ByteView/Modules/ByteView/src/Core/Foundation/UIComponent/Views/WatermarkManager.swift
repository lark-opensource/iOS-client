//
//  WatermarkManager.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/9/26.
//

import Foundation
import UIKit

private final class WatermarkManager {
    private(set) weak var currentWatermark: UIView?

    func setupWatermark(on window: UIWindow, provider: LarkDependency) {
        provider.getWatermarkView(completion: { [weak self, weak window] watermarkView in
            guard let self = self, let window = window else { return }
            self.currentWatermark = watermarkView
            watermarkView.frame = window.bounds
            watermarkView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            window.addSubview(watermarkView)
        })
    }
}

private var watermarkManagerAssociationKey: UInt8 = 0
extension UIWindow {
    private var watermarkManager: WatermarkManager? {
        get {
            objc_getAssociatedObject(self, &watermarkManagerAssociationKey) as? WatermarkManager
        }
        set {
            objc_setAssociatedObject(self, &watermarkManagerAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func setupWatermark(provider: LarkDependency) {
        let manager = WatermarkManager()
        manager.setupWatermark(on: self, provider: provider)
        self.watermarkManager = manager
    }

    func bringWatermarkToFront() {
        if let watermarkView = watermarkManager?.currentWatermark, self.subviews.contains(watermarkView) {
            self.bringSubviewToFront(watermarkView)
        }
    }
}
