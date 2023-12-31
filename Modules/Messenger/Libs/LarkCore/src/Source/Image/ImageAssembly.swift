//
//  ImageAssembly.swift
//  Lark
//
//  Created by liuwanlin on 2018/5/18.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkContainer
import Swinject
import LarkMessengerInterface
import EENavigator
import RustPB
import LarkRustClient
import LarkAssembler

public final class ImageAssembly: LarkAssemblyInterface {
    public init() {}

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(PreviewImagesBody.self).factory(cache: true, PreviewImagesHandler.init)

        Navigator.shared.registerRoute.type(UploadImageBody.self).factory(cache: true, UploadImageHandler.init(resolver:))

        Navigator.shared.registerRoute.type(PreviewAvatarBody.self).factory(cache: true, PreviewAvatarHandler.init(resolver:))

        Navigator.shared.registerRoute.type(SettingSingeImageBody.self).factory(cache: true, SettingSingleImageHandler.init(resolver:))
    }

    public func registRustPushHandlerInUserSpace(container: Container) {
        (.pushPrefetchAvatarPaths, PrefetchAvatarPathsPushHandler.init)
    }
}
