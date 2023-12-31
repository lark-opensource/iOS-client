//
//  RingingRefuseManager.swift
//  ByteView
//
//  Created by wangpeiran on 2023/3/19.
//

import Foundation
import ByteViewNetwork
import ByteViewUI

class RingingRefuseManager {
    static let shared = RingingRefuseManager()

    static let ringRefuseWindowlevel = UIWindow.Level.alert + 100

    init() { }

    var window: UIWindow?

    func openRingRefuse(with body: RingRefuseBody, httpClient: HttpClient) {
        Util.runInMainThread {
            guard self.window == nil else { return }
            Logger.ringRefuse.info("openRingRefuse, body: \(body)")
            self.window = VCScene.createWindow(RingingRefuseWindow.self, tag: .ringrefuse)  // RingingRefuseWindow(frame: UIScreen.main.bounds)
            if #available(iOS 13.0, *), let ws = VCScene.windowScene, self.window?.windowScene != ws {
                self.window?.windowScene = ws
            }
            self.window?.backgroundColor = UIColor.clear
            self.window?.windowLevel = RingingRefuseManager.ringRefuseWindowlevel
            self.window?.rootViewController = RingingRefuseViewController(body: body, httpClient: httpClient)
            self.window?.isHidden = false
        }
    }

    func hideRingRefuse() {
        Util.runInMainThread {
            self.window?.rootViewController = nil
            self.window?.isHidden = true
            self.window = nil
            Logger.ringRefuse.info("hideRingRefuse")
        }
    }
}
