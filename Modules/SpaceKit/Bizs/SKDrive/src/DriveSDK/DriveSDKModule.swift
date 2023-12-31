//
//  DriveSDKModule.swift
//  SpaceKit
//
//  Created by Weston Wu on 2020/6/16.
//

import Foundation
import SKCommon
import EENavigator
import SpaceInterface
import SKInfra
import LarkContainer

public final class DriveSDKModule: ModuleService {
    public init() {}
    /// 初始化时调用
    public func setup() {
        DocsContainer.shared.register(DriveSDKModule.self, factory: { _ in
            return self
        }).inObjectScope(.container)

        DocsContainer.shared.register(DriveSDK.self) { r in
            let config = DKConfig.config
            let ability = r.resolve(DriveSDKLocalFilePreviewAbility.self)
            let sdkImpl = DriveSDKImpl(config: config, ability: ability)
            return sdkImpl
        }.inObjectScope(.container)
        
        DocsContainer.shared.register(DKPreviewVCManagerProtocol.self) { _ in
            return DKPreviewVCManager()
        }.inObjectScope(.container)
        
        DocsContainer.shared.register(DriveFileBlockLoadingProtocol.self) { _ in
            return DriveFileBlockLoadingView(frame: .zero)
        }

        DocsContainer.shared.register(DriveShadowFileManagerProtocol.self) { _ in
            return DriveShadowFileManger.shared
        }.inObjectScope(.container)
    }

    /// 注册路由
    public func registerURLRouter() {
        Navigator.shared.registerRoute(type: DKNaviBarBody.self) {
            return DKNaviBarBodyHandler()
        }
    }
}
