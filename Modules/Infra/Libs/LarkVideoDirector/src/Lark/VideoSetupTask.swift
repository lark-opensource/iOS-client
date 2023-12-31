//
//  VideoSetupTask.swift
//  LarkVideoDirector
//
//  Created by Saafo on 2023/5/5.
//

import Foundation
import BootManager
import LKCommonsLogging
import RunloopTools
import LarkStorage
import LarkContainer

final class VideoSetupTask: FlowBootTask, Identifiable {

    static let logger = Logger.log(VideoSetupTask.self, category: "VideoSetupTask")

    static var identify = "VideoSetupTask"

    override var delayScope: Scope? { return .container }

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        let userResolver = try? Container.shared.getUserResolver(userID: context.currentUserID)
        if LarkPlayerKit.isEnabled(userResolver: userResolver), let userResolver {
            LarkPlayerKit.setupLegacyEngine(userResolver: userResolver)
        } else {
            VideoEngineSetupManager.setupTTVideoEngine()
        }
        VideoEditorManager.shared.setVEConfigNotSetHandler()
        #if VideoDirectorIncludesCKNLE
        // 将 UserDefaults(suiteName: kLVDCacheUserDefaultsSuiteName) 纳入 LarkStorage 管控
        KVManager.shared.registerUnmanaged(.suiteName(kLVDCacheUserDefaultsSuiteName))
        #endif
    }
}
