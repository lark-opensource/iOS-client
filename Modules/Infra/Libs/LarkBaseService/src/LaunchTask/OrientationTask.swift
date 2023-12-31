//
//  OrientationTask.swift
//  LarkBaseService
//
//  Created by KT on 2020/7/1.
//

import UIKit
import Foundation
import BootManager
import AppContainer
import LarkOrientation

final class OrientationTask: FlowBootTask, Identifiable { // Global
    static var identify = "OrientationTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        Orientation.swizzledIfNeeed()
        self.orientationAddPatch()
    }

    func orientationAddPatch() {
        let videoPatch = Orientation.Patch(
            identifier: "webVideo",
            description: "Fix audio full screen vc orientation",
            options: [
                .supportedInterfaceOrientations(.allButUpsideDown)
            ]
        ) { (vc) -> Bool in
            let className = { (vc: UIViewController) -> String in
                return String(NSStringFromClass(type(of: vc))
                    .split(separator: ".")
                    .last ?? "")
            }
            let avPlayerVCName = "AVFullScreenViewController"
            if className(vc) == avPlayerVCName {
                return true
            } else if let presented = vc.presentedViewController,
                className(presented) == avPlayerVCName {
                return true
            }
            return false
        }
        Orientation.add(patches: [videoPatch])
    }
}
