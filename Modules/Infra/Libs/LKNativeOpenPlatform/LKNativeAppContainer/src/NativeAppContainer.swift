//
//  NativeAppContainer.swift
//  LKNativeAppContainer
//
//  Created by Bytedance on 2021/12/17.
//  Copyright © 2021 Bytedance. All rights reserved.
//

import Foundation
import LarkAppLinkSDK
import LKNativeAppExtension
import LKNativeAppExtensionAbility

public class NativeAppContainer {
    public static let shared = NativeAppContainer()
    public init() {
        LarkAppLinkSDK.registerHandler(path: "/client/native_extension/open") { [weak self] link in
            if let appId = link.url.queryParameters("appId"),
            !appId.isEmpty,
            let appExtension = self?.loadApp(appId) {
                (appExtension as? LKNativeAppExtensionPageRoute)?.pageRoute(link.url, from: link.fromControler)
            }
        }
    }

    private func loadApp(_ appId: String) -> LKNativeAppExtension? {
        let config = LKNativeAppExtensionFinder.shared().getConfigByAppId(appId)
        if let implClass = NSClassFromString(config?.implName ?? "") as? LKNativeAppExtension.Type {
            return implClass.init()
        }
        return nil
    }
}

extension URL {
    public func queryParameters(_ key: String) -> String? {
        guard let component = URLComponents(string: self.absoluteString) else { return nil }
        return component.queryItems?.first(where: { $0.name == key })?.value
    }
}
