//
//  SceneApplicationDelegate.swift
//  LarkSplitViewController
//
//  Created by 郭怡然 on 2022/11/28.
//

import Foundation
import AppContainer

fileprivate let SceneDidBecomeActiveNotificationKey = "SceneDidBecomeActiveNotificationKey"


public final class SceneApplicationDelegate: ApplicationDelegate {
  public static var config: AppContainer.Config = Config(name: "SceneActive", daemon: true)


    required public init(context: AppContext) {
        if #available(iOS 13.0, *) {
            context.dispatcher.add(observer: self) { (_, _: SceneDidBecomeActive) in
                NotificationCenter.default.post(name: NSNotification.Name(SceneDidBecomeActiveNotificationKey), object: nil)
            }
        }
  }
}
