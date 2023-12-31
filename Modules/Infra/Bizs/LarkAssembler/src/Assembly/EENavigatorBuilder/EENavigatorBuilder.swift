//
//  LarkAssemblyBuilder.swift
//  LarkContainer
//
//  Created by yangjing.sniper on 2021/12/23.
//

import Foundation
import EENavigator

@resultBuilder
public struct RouterFactory {
    public static func buildBlock(_ components: Router...) {
    }
}

@resultBuilder
public struct URLInterceptorFactory {
    public static func buildBlock(_ components: (String, (URL, NavigatorFrom) -> Void)...) {
        components.forEach { compent in
            URLInterceptorManager.shared.register(compent.0, handler: compent.1)
        }
    }
}
