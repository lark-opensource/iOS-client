//
//  KATabAssembly.swift
//  KATabRegistry
//
//  Created by Supeng on 2021/11/5.
//

import Foundation
import Swinject
import EENavigator
import LarkAssembler
import BootManager
#if canImport(LKTabExternal)
import LKTabExternal
#endif



#if canImport(LKTabExternal)
public final class KATabAssembly: LarkAssemblyInterface {
    public init() {}

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute_(plainPattern: "//client/customNative/home", priority: .high) { (req, res) in
            print(req.context[ContextKeys.matchedParameters])
            if let keyValue = URLComponents(url: req.url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "key" })?.value,
               let config = allConfigs.first(where: { $0.appId == keyValue }) {
                res.end(resource: TabControllerWrapper(tabConfig: config))
            } else {
                res.end(resource: nil)
            }
        }
    }
}
#else
public final class KATabAssembly: LarkAssemblyInterface {
    public init() {}
}
#endif
