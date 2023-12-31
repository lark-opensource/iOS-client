//
//  RingingRefuseWindow.swift
//  ByteView
//
//  Created by wangpeiran on 2023/3/17.
//

import Foundation

class RingingRefuseWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event),
            let rootVC = self.rootViewController else {
            return nil
        }

        if rootVC.isKind(of: RingingRefuseViewController.self),
           let vc = rootVC as? RingingRefuseViewController,
           !vc.touchInRefuseView(hitView: hitView) {
            return nil
        }
        return hitView
    }

    deinit {
        Logger.ringRefuse.info("window deinit")
    }

}
