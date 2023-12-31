//
//  VideoDirectorAssembly.swift
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/6/13.
//

import Foundation
import AppContainer
import BootManager
import LarkCache
import LarkAssembler
import Swinject

public final class VideoDirectorAssembly: LarkAssemblyInterface {

    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(VideoSetupTask.self)
        NewBootManager.register(VEPreloadTask.self)
    }

    public func registBootLoader(container: Container) {
        (VideoEngineApplicationDelegate.self, DelegateLevel.default)
    }

    @_silgen_name("Lark.LarkCache_CleanTaskRegistry_regist.VideoDirectorAssembly")
    public static func assembleCacheCleanTask() {
        CleanTaskRegistry.register(cleanTask: VideoCacheCleanTask())
    }
}
