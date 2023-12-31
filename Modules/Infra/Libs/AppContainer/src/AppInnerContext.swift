//
//  AppContext.swift
//  Pods-AppContainerDev
//
//  Created by liuwanlin on 2018/11/15.
//

import UIKit
import Foundation
import Swinject
import BootManager

public protocol AppContext {
    var dispatcher: Dispatcher { get }
    var config: AppConfig { get }
    var launchOptions: [UIApplication.LaunchOptionsKey: Any]? { get }
    var launchTime: TimeInterval? { get }
    var container: Container { get }
}

final class AppInnerContext: AppContext {
    struct ApplicationRegistery {
        let config: Config
        let type: ApplicationDelegate.Type
    }

    var dispatcher = Dispatcher()

    var config: AppConfig
    let container: Container

    var launchOptions: [UIApplication.LaunchOptionsKey: Any]?

    var launchTime: TimeInterval?

    var applications: [String: Application] = [:]
    var applicationsRegistery: [ApplicationRegistery] = []

    init(config: AppConfig, container: Container) {
        self.config = config
        self.container = container
    }

    func registerApplication(config: Config, delegate: ApplicationDelegate.Type) {
        let registery = ApplicationRegistery(config: config, type: delegate)
        self.applicationsRegistery.append(registery)
    }

    func unregisterApplication(name: String) {
        if let index = self.applicationsRegistery.firstIndex(where: { $0.config.name == name }) {
            self.applicationsRegistery.remove(at: index)
        }
    }

    func startApplication(name: String) {
        if self.applications.contains(where: { $0.key == name }) {
            return
        }
        guard let registery = self.applicationsRegistery.first(where: { $0.config.name == name }) else {
            return
        }
        let delegate = registery.type.init(context: self)
        let application = Application(config: registery.config, delegate: delegate)
        if registery.config.daemon {
            self.applications[application.config.name] = application
        }
    }

    func stopApplication(name: String) {
        self.applications = self.applications.filter { $0.key != name }
    }

    func startAllApplicationsIfNeeded() {
        self.applicationsRegistery
            .forEach {
                self.startApplication(name: $0.config.name)
            }
    }
}

final class StartApplicationTask: FlowBootTask, Identifiable { //Global
    static var identify = "StartApplicationTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        BootLoader.shared.context?.startAllApplicationsIfNeeded()
    }
}

extension AppInnerContext {
    static var `default`: AppInnerContext {
        return .init(config: .default, container: Container.shared)
    }
}
