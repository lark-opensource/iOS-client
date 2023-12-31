//
//  LarkSendMessageAssembly.swift
//  LarkSendMessage
//
//  Created by Bytedance on 2022/10/18.
//

import Foundation
import LarkAssembler // LarkAssemblyInterface
import LarkSDKInterface // SDKRustService
import LarkContainer // Container
import LarkAccountInterface // scheduler
import LarkDebugExtensionPoint // SectionType.debugTool
import LarkSetting

public final class LarkSendMessageAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        let user = container.inObjectScope(M.userScope)
        let userGraph = container.inObjectScope(M.userGraph)
        // MARK: - 消息发送
        // 进入后台时，继续发消息
        user.register(SendingMessageManager.self) { (_) -> SendingMessageManager in
            return SendingMessageManagerImpl()
        }
        // 发送消息
        user.register(SendMessageAPI.self) { (r) -> SendMessageAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return try RustSendMessageAPI(
                userResolver: r,
                chatAPI: try r.resolve(assert: ChatAPI.self),
                progressService: try r.resolve(assert: ProgressService.self),
                pushCenter: try r.userPushCenter,
                client: rustClient,
                onScheduler: scheduler,
                dependency: try r.resolve(assert: SDKDependency.self)
            )
        }
        // 发送消息记录，提供给SendMessageTracker+ChatKeyPointTracker实现埋点逻辑
        user.register(SendMessageKeyPointRecorderProtocol.self) { r -> SendMessageKeyPointRecorderProtocol in
            return SendMessageKeyPointRecorder(userResolver: r, stateListeners: [])
        }
        // 附件上传进度
        user.register(ProgressService.self) { _ in
            TaskProgressManager()
        }
        // 话题群创建话题
        user.register(SendThreadAPI.self) { (r) -> SendThreadAPI in
            let rustClient = try r.resolve(assert: SDKRustService.self)
            return try RustSendThreadAPI(
                userResolver: r,
                chatAPI: r.resolve(assert: ChatAPI.self),
                pushCenter: r.userPushCenter,
                client: rustClient,
                onScheduler: scheduler,
                dependency: r.resolve(assert: SDKDependency.self)
            )
        }
        // 图片、视频磁盘空间检测等工具方法
        userGraph.register(MediaDiskUtil.self, factory: MediaDiskUtil.init(userResolver:))

        // MARK: - 发视频
        // 视频转码
        user.register(VideoTranscodeService.self) { (r) -> VideoTranscodeService in
            let ugSettings = try r.resolve(assert: UserGeneralSettings.self)
            let transcodeStrategy = VideoTranscodeStrategyImpl(userResolver: r, videoSetting: ugSettings.videoSynthesisSetting)
            return VideoTranscoder(transcodeStrategy: transcodeStrategy)
        }
        // 发送视频
        user.register(VideoMessageSendService.self) { r in
            return try VideoMessageSend(
                userResolver: r,
                sendMessageAPI: try r.resolve(assert: SendMessageAPI.self),
                transcodeService: try r.resolve(assert: VideoTranscodeService.self),
                client: try r.resolve(assert: SDKRustService.self),
                pushDynamicNetStatus: try r.userPushCenter.observable(for: PushDynamicNetStatus.self)
            )
        }

        // MARK: - 发富文本
        // 发送富文本
        user.register(PostSendService.self) { (r) -> PostSendService in
            return try PostSendServiceImpl(
                userResolver: r,
                sendMessageAPI: try r.resolve(assert: SendMessageAPI.self),
                sendThreadAPI: try r.resolve(assert: SendThreadAPI.self),
                videoSendService: try r.resolve(assert: VideoMessageSendService.self)
            )
        }
    }

    public func registDebugItem(container: Container) {
        ({ VideoDebugItem() }, SectionType.debugTool)
    }
}

/// 用于FG控制UserResolver的迁移, 控制Resolver类型.
/// 使用UserResolver后可能抛错，需要控制对应的兼容问题
enum M {
    private static var userScopeFG: Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: "lark.ios.messeger.userscope.refactor") // Global
    }
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}
