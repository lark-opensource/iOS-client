//
//  TangramAssembly.swift
//  TangramService
//
//  Created by 袁平 on 2021/6/9.
//

import Foundation
import RustPB
import Swinject
import LarkSetting
import LarkAssembler
import LarkContainer
import LarkRustClient

public enum URLPreview {
    private static var userScopeFG: Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.url") //Global
    }
    //是否开启兼容
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user，FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph，FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}

public final class TangramAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        let user = container.inObjectScope(URLPreview.userScope)
        let userGraph = container.inObjectScope(URLPreview.userGraph)

        user.register(URLPreviewAPI.self) { r in
            let client = try r.resolve(assert: RustService.self)
            return RustURLPreviewAPI(client: client)
        }

        user.register(InlineCacheService.self) { r in
            let pushCenter = try r.userPushCenter
            let urlAPI = try r.resolve(assert: URLPreviewAPI.self)
            return InlineCacheService(urlAPI: urlAPI, pushCenter: pushCenter)
        }
    }

    public func registRustPushHandlerInUserSpace(container: Container) {
        // URL预览
        (Command.pushMessagePreviews, URLPreviewPushHandler.init(resolver:))
        (Command.pushURLPreviews, URLEntryPushHandler.init(resolver:))
        (Command.pushPreviews, URLPreviewScenePushHandler.init(resolver:))
    }
}
