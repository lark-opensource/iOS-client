//
//  BootLoader.swift
//  Pods-AppContainerDev
//
//  Created by liuwanlin on 2018/11/15.
//

import UIKit
import Foundation
import Swinject
import LarkContainer

public final class BootLoader {
    typealias ApplicationDelegateCache = (DelegateLevel, ApplicationDelegate.Type)

    public internal(set) static var shared = BootLoader()

    public static var container: Container { Container.shared } //Global

    public static var assemblyLoaded: Bool = false

    // DidFinishLaunching是否结束
    public static var isDidFinishLaunchingFinished = false

    var context: AppInnerContext?

    /// get Application instance
    /// - Parameter delegate: ApplicationDelegate
    public static func resolver<T: ApplicationDelegate>(_ delegate: T.Type) -> T? {
        return shared.context?.applications[delegate.config.name]?.delegate as? T
    }

    /// register application delegate
    /// can only be called inside assembly
    /// - Parameters:
    ///   - delegate: ApplicationDelegate item type
    ///   - level: ApplicationDelegate level
    public func registerApplication(
        delegate: ApplicationDelegate.Type,
        level: DelegateLevel) {
        context?.registerApplication(config: delegate.config, delegate: delegate)
        assert(!Self.assemblyLoaded, "can only call this method inside assembly")
    }

    public func start<T: AppDelegate>(delegate: T.Type, config: AppConfig) {
        self.context = AppInnerContext(config: config, container: Self.container)
        implicitResolver = Self.container.synchronize() //Global
        UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(delegate))
    }
}
