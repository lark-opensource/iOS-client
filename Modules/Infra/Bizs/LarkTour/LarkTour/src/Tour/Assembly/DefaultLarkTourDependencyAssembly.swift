//
//  DefaultLarkTourDependencyAssembly.swift
//  LarkTour
//
//  Created by Supeng on 2021/9/29.
//

import Foundation
import LarkTourInterface
import Swinject
import EENavigator
import RxSwift
import LarkAssembler

public final class DefaultLarkTourDependencyAssembly: LarkAssemblyInterface {

    public init() {}

    public func registContainer(container: Container) {
        container.register(TourDependency.self) { _ in DefaultTourDependencyImpl() as TourDependency}
    }
}

public final class DefaultTourDependencyImpl: TourDependency {
    public init() {}

    public var conversionDataReady: Bool = false

    public func setConversionDataHandler(_ handler: @escaping (String) -> Void) {}

    public var needSkipOnboarding: Bool = false
}
