//
//  DemoApplicationDelegate.swift
//  LarkTourDev
//
//  Created by Meng on 2020/5/22.
//

import Foundation
import LarkContainer
import LarkRustClient
import AppContainer
import Logger
import EEImageService
import LarkAppConfig

class DemoApplicationDelegate: ApplicationDelegate {
    static let config = Config(name: "Demo", daemon: true)

    static var documentPath: URL {
        let URLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let URL = URLs[URLs.count - 1]
        return URL
    }

    static var globalLogPath: URL {
        return documentPath.appendingPathComponent(relativeLogPath, isDirectory: false)
    }

    static var relativeLogPath: String {
        switch ConfigurationManager.env.type {
        case .release:
            return "sdk_storage/log"
        case .preRelease:
            return "sdk_storage/pre_release/log"
        case .staging:
            return "sdk_storage/staging/log"
        }
    }

    @Injected
    private var rustClient: RustService

    required init(context: AppContext) {
        context.dispatcher.add(observer: self) { [weak self] (_, message: DidBecomeActive) in
            self?.didFinishLaunching(message: message)
        }
    }

    private func didFinishLaunching(message: DidBecomeActive) {
        let rustLogConfig = RustLogConfig(
            process: "larkdocs",
            logPath: Self.globalLogPath.path,
            monitorEnable: true
        )
        RustLogAppender.setupRustLogSDK(config: rustLogConfig)
    }
}
