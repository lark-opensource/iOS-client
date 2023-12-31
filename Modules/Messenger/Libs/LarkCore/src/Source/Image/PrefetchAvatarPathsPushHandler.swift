//
//  PrefetchAvatarPathsPushHandler.swift
//  EEImageService
//
//  Created by 袁平 on 2020/10/16.
//

import Foundation
import RustPB
import LarkRustClient
import LKCommonsLogging
import LarkContainer
import ByteWebImage

extension Media_V1_PushPrefetchAvatarPathsResponse: PushMessage {}

/// 进群时SDK会预加载thumb头像，这部分头像也需要接入LarkCache的缓存超时清理
public final class PrefetchAvatarPathsPushHandler: UserPushHandler {
    static var logger = Logger.log(PrefetchAvatarPathsPushHandler.self,
                                   category: "EEImageService.PrefetchAvatarPathsPushHandler")

    public override class var compatibleMode: Bool { M.userScopeCompatibleMode }

    public func process(push message: Media_V1_PushPrefetchAvatarPathsResponse) throws {
        message.paths.forEach {
            let url = URL(fileURLWithPath: $0)
            // TODO: 用户隔离 LarkImageService
            LarkImageService.shared.thumbCache.diskCache.setExistFile(for: url.lastPathComponent, with: $0)
        }
        Self.logger.info("PrefetchAvatarPathsPushHandler receive paths: \(message.paths)")
    }
}
