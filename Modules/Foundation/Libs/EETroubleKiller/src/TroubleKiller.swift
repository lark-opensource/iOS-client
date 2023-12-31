//
//  TroubleKiller.swift
//  EETroubleKiller
//
//  Created by lixiaorui on 2019/5/13.
//

import Foundation
import UIKit
import LKCommonsLogging

// MARK: - public
extension TroubleKiller {
    public class var capture: CaptureService {
        return shared.capture
    }

    public class var pet: PETService {
        return shared.pet
    }

    public class var config: Config {
        return shared.config
    }

    public class var hook: Hook {
        return shared.hook
    }

    public class func start() {
        guard !shared.started else {
            assert(!shared.started, "TroubleKiller only can start once.")
            return
        }
        shared.started = true
        shared.captureDispatcher.registerNotifications()
        shared.captureDispatcher.delegate = shared.capture
    }

    public class func registerRouterWhiteList(_ routerResourceType: RouterResourceProtocol.Type) {
        let name = routerResourceType.tkName
        logger.debug("register router withiteList \(name) ", tag: LogTag.log)
        shared.config.routerWhiteList.insert(name)
    }

    public class func registerDefaultWindowName(_ name: String) {
        logger.debug("register default windowName \(name) ", tag: LogTag.log)
        shared.config.defaultWindows.insert(name)
    }
}

// MARK: - internal
extension TroubleKiller {
    static let encoder: JSONEncoder = {
        return JSONEncoder()
    }()

    static let logger = Logger.log(TroubleKiller.self, category: "TroubleKiller")
}

public final class TroubleKiller {
    private static let shared = TroubleKiller()

    private let config = Config()

    private let hook = Hook()

    private let capture: CaptureServiceImpl = CaptureServiceImpl()

    private let pet: PETServiceImpl = PETServiceImpl()

    private let captureDispatcher = CaptureDispatcher()

    private var started: Bool = false

    private init() {}
}
