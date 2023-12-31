//
//  SettingAppDelegate.swift
//  LarkSetting
//
//  Created by 王元洵 on 2022/11/21.
//

import Foundation
import AppContainer

final class SettingAppDelegate: ApplicationDelegate {
    static let config = Config(name: "Setting", daemon: true)
    
    init(context: AppContext) {
        context.dispatcher.add(observer: self) { (_, message: DidEnterBackground) in FeatureGatingTracker.syncCache()  }
    }
}
