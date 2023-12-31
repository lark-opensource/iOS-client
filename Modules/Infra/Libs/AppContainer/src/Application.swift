//
//  Application.swift
//  Pods-AppContainerDev
//
//  Created by liuwanlin on 2018/11/15.
//

import Foundation

public struct Config {
    public let name: String
    public let daemon: Bool

    public init(
        name: String,
        daemon: Bool = false) {

        self.name = name
        self.daemon = daemon
    }
}

// swiftlint:disable class_delegate_protocol
public enum DelegateLevel: Int {
    case low = 1
    case `default` = 100
    case high = 1000
}

public protocol ApplicationDelegate: Observer {
    init(context: AppContext)

    func didCreate()
    func willResume()
    func willPause()
    func willTerminate()
}

public extension ApplicationDelegate {
    func didCreate() {}
    func willResume() {}
    func willPause() {}
    func willTerminate() {}
}

final class Application {
    let config: Config
    // swiftlint:disable weak_delegate
    let delegate: ApplicationDelegate
    // swiftlint:enable weak_delegate

    init(config: Config, delegate: ApplicationDelegate) {
        self.config = config
        self.delegate = delegate
        delegate.didCreate()
    }

    func pause() {
        delegate.willPause()
    }

    func resume() {
        delegate.willResume()
    }

    deinit {
        delegate.willTerminate()
    }
}
