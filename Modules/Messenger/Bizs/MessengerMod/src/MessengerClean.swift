//
//  MessengerClean.swift
//  MessengerMod
//
//  Created by aslan on 2023/7/25.
//

import LarkClean
import LarkStorage
#if canImport(LarkSDKInterface)
import LarkSDKInterface
#endif
#if canImport(LarkVideoDirector)
import LarkVideoDirector
#endif
#if canImport(LarkSendMessage)
import LarkSendMessage
#endif

extension CleanRegistry {
    @_silgen_name("Lark.LarkClean_CleanRegistry.Messenger")
    public static func registerMessenger() {
        registerPaths(forGroup: "messenger") { ctx in
            var paths = [CleanIndex.Path]()

            let userIds = ctx.userList.map(\.userId)
            paths.append(contentsOf: [
                .abs((AbsPath.cache + "com.bt.image.cache").absoluteString),
                .abs((AbsPath.cache + "com.lark.cache.thumb").absoluteString),
                .abs((AbsPath.cache + "com.lark.cache.origin").absoluteString),
                .abs((AbsPath.cache + "ttVideoCaches").absoluteString)
            ])
#if canImport(LarkVideoDirector)
            paths.append(.abs(VideoEngineSetupManager.videoCacheRootPath().absoluteString))
#endif
#if canImport(LarkSendMessage)
            let videoPassPaths: [IsoPath] = userIds.map(VideoPassRootPath(userID:))
            paths.append(contentsOf: videoPassPaths.map { .abs($0.absoluteString) })
#endif
#if canImport(LarkSDKInterface)
            let downloadPaths: [IsoPath] = userIds.map(fileDownloadRootPath(userID:))
            paths.append(contentsOf: downloadPaths.map { .abs($0.absoluteString) })
#endif
            return paths
        }
        registerVkeys(forGroup: "messenger") { ctx in
            let spaces = ctx.userList.map { Space.user(id: $0.userId) } + [.global]
            return spaces.map { space in
                let unified = CleanIndex.Vkey.Unified(space: space, domain: Domain.biz.feed, type: .udkv)
                return .unified(unified)
            }
        }
    }
}
