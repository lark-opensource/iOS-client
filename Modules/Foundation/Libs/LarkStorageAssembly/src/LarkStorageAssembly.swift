//
//  LarkStorageAssembly.swift
//  LarkStorageAssembly
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import Swinject
import BootManager
import LarkStorage
import LKLoadable
import LarkAssembler

#if !LARK_NO_DEBUG
import LarkDebugExtensionPoint

import EENavigator

public struct LarkStorageKeyValueDebugBody: CodablePlainBody {

    public static let pattern: String = "//client/lark_storage/key_value/debug"

    public let space: String
    public let domain: String
    public let type: String

    public init(space: String, domain: String, type: String) {
        self.space = space
        self.domain = domain
        self.type = type
    }
}
#endif

public final class LarkStorageAssembly: LarkAssemblyInterface {
    public init() { }

    public func registLaunch(container: Container) {
        NewBootManager.register(SetupStorageTask.self)
    }

    #if !LARK_NO_DEBUG
    public func registDebugItem(container: Container) {
        ({ LarkStorageDebugItem() }, SectionType.debugTool)
    }

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute_(type: LarkStorageKeyValueDebugBody.self) { body, _, res in
            let vc: UIViewController
            switch body.type {
            case "udkv":
                vc = UDKVDomainController(space: body.space, domain: body.domain)
            case "mmkv":
                vc = MMKVDomainController(space: body.space, domain: body.domain)
            default:
                return
            }
            res.end(resource: vc)
        }
    }
    #endif
}
