//
//  ExtensionAppDelegate.swift
//  Lark
//
//  Created by 王元洵 on 2020/10/19.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import AppContainer
import BootManager

final class ExtensionAppDelegate: ApplicationDelegate {
    static let config = Config(name: "Extension", daemon: true)

    required init(context: AppContext) {
        context.dispatcher.add(observer: self) { [weak self] (_, message: WillEnterForeground) in
            self?.willEnterForeground(message)
        }
    }

    private func willEnterForeground(_ message: WillEnterForeground) {
        DispatchQueue.global().async {
            ExtensionLogCleaner.moveAndClean()
            ExtensionTrackPoster.post()
        }
    }
}
