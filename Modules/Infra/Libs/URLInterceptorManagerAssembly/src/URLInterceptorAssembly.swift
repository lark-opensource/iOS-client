//
//  URLInterceptorAssembly.swift
//  URLInterceptorManagerAssembly
//
//  Created by su on 2022/5/13.
//

import Foundation
import AppContainer
import Swinject
import LarkAssembler

public final class URLInterceptorAssembly: LarkAssemblyInterface {
    public init() {}

    public func registBootLoader(container: Container) {
        (OpenURLApplicationDelegate.self, DelegateLevel.default)
    }
}
