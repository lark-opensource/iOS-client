//
//  PushHandlers.swift
//  ByteViewMod
//
//  Created by kiri on 2022/12/13.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import RustPB
import LarkRustClient
import LarkContainer
import LarkAssembler
import LarkAccountInterface
import ByteView
import LarkSceneManager

final class PushAssembly: LarkAssemblyInterface {
    func registRustPushHandlerInUserSpace(container: Container) {
        // 网络状态变化，会触发registerClientInfo拉取会议信息
        (Command.pushWebSocketStatus, RustPushHandler.build({ StartupPush.webSocket }))
        // 会议信息
        (Command.notifyVideoChat, RustPushHandler.build({ StartupPush.notifyVideoChat }))
        // 推送提醒
        (Command.pushVideoChatPrompt, RustPushHandler.build({ StartupPush.videoChatPrompt }))
        // 推送通知
        (Command.pushVideoChatNotice, RustPushHandler.build({ StartupPush.videoChatNotice }))
        // 虚拟背景
        (Command.pushVcVirtualBackground, RustPushHandler.build({ Push.virtualBackground }))
        // 向群长连推送会议状态发生改变的命令字
        (Command.pushAssociatedVcStatus, RustPushHandler.build({ Push.associatedVideoChatStatus }))
        // 不会影响到状态机核心逻辑的数据推送
        (Command.notifyVideoChatExtra, RustPushHandler.build({ Push.videoChatExtra }))
        // Rust-sdk向客户端push 聚合之后的data
        (Command.pushVideoChatCombinedInfo, RustPushHandler.build({ Push.videoChatCombinedInfo }))
        // 通知客户端心跳停止了
        (Command.pushByteviewHeartbeatStop, RustPushHandler.build({ Push.heartbeatStop }))
        // 全量参会人
        (Command.pushMeetingInfo, RustPushHandler.build({ Push.fullParticipants }))
        // 参会人变化
        (Command.pushMeetingParticipantChange, RustPushHandler.build({ Push.participantChange }))
        // 网络研讨会观众列表更新 嘉宾专用
        (Command.pushMeetingWebinarAttendeeChange, RustPushHandler.build({ Push.webinarAttendeeChange}))
        // 观众的视图列表变化 观众专用
        (Command.pushMeetingWebinarAttendeeViewChange, RustPushHandler.build({ Push.webinarAttendeeViewChange }))
        // 会议变化通知
        (Command.pushMeetingChangedInfo, RustPushHandler.build({ Push.inMeetingChangedInfo }))
        // 全量等候室参会人
        (Command.pushFullVcLobbyParticipants, RustPushHandler.build({ Push.fullLobbyParticipants }))
        (Command.pushVcManageNotify, RustPushHandler.build({ Push.vcManageNotify }))
        (Command.pushVcManageResult, RustPushHandler.build({ Push.vcManageResult }))
        // 推送对VideoChatNotice的更新动作
        (Command.pushVideoChatNoticeUpdate, RustPushHandler.build({ Push.videoChatNoticeUpdate }))
        // groot通道推送的数据
        (Command.pushGrootCells, RustPushHandler.build({ Push.grootCells }))
        // Rust通知客户端当前channel状态
        (Command.pushGrootChannelStatus, RustPushHandler.build({ Push.grootChannelStatus }))
        // 消息推送
        (Command.pushVideoChatInteractionMessages, RustPushHandler.build({ Push.interactionMessages }))
        (Command.pushChatters, RustPushHandler.build({ Push.chatters }))
        // 用户设置推送
        (Command.pushViewUserSetting, RustPushHandler.build({ Push.viewUserSetting }))
        // RTC数据通道
        (Command.pushSendMessageToRtc, RustPushHandler.build({ Push.sendMessageToRtc }))
        // 翻译结果推送
        (Command.pushVcTranslateResults, RustPushHandler.build({ Push.translateResults }))
        // rtc远端网络状态
        (Command.pushVcRemoteRtcNetStatus, RustPushHandler.build({ Push.remoteRtcNetStatus }))
        (Command.pushSuggestedParticipants, RustPushHandler.build({ Push.suggestedParticipants }))
        // 会议视频链接更新推送
        (Command.pushCalendarEventVideoMeetingChange, RustPushHandler.build({ Push.calendarEventVideoMeetingChange }))
        // vc接入im互动消息推送
        (Command.pushVcMessagePreviews, RustPushHandler.build({ Push.messagePreviews }))
        (Command.pushEmojiPanel, RustPushHandler.build({ Push.emojiPanel }))
        (Command.pushVcImChatBannerChange, RustPushHandler.build({ Push.vcEventCard }))
        // 推送入会设备变更
        (Command.pushJoinedDevicesInfo, RustPushHandler.build({ Push.vcJoinedDevicesInfo }))
        #if TabMod
        // LarkMod包含ByteViewTab
        // 最多返回一个正在进行的会议，在已经加入/等候会议室。
        (Command.pushVcMeetingJoinStatus, RustPushHandler.build({ TabPush.meetingJoinStatus }))
        (Command.pushDynamicNetStatus, RustPushHandler.build({ TabPush.dynamicNetStatus }))
        (Command.pushVcSyncUpcomingInstances, RustPushHandler.build({ TabPush.syncUpcomingInstances }))
        #endif
    }

    func registServerPushHandlerInUserSpace(container: Container) {
        // ---------- global ----------
        // 面试满意度问卷推送
        (ServerCommand.pushInterviewQuestionnaire, ServerPushHandler.build({ StartupPush.interviewQuestionnaire }))
        // ---------- user ----------
        (ServerCommand.notifyEnterprisePhone, ServerPushHandler.build({ ServerPush.enterprisePhone }))
        // 推送用户常用表情
        (ServerCommand.pushUserRecentEmoji, ServerPushHandler.build({ ServerPush.userRecentEmoji }))
        // 交换会议Key
        (ServerCommand.pushE2EeKeyExchange, ServerPushHandler.build({ ServerPush.meetingKeyExchange }))
        #if TabMod
        // LarkMod包含ByteViewTab
        // VC-Tab红点数据推送
        (ServerCommand.notifyVcTabMissedCalls, ServerPushHandler.build({ TabServerPush.missedCalls }))
        // 推送录制完成
        (ServerCommand.pushVcTabRecordInfo, ServerPushHandler.build({ TabServerPush.recordInfo }))
        #endif
    }
}

private class RustPushHandler: UserPushHandler {
    static func build(_ factory: @escaping () -> ByteViewPushHandler) -> ((UserResolver) -> RustPushHandler) {
        { RustPushHandler(factory: factory, resolver: $0) }
    }

    let factory: () -> ByteViewPushHandler
    init(factory: @escaping () -> ByteViewPushHandler, resolver: UserResolver) {
        self.factory = factory
        super.init(resolver: resolver)
    }

    func process(push: RustPushPacket<Data>) throws {
        let userId = userResolver.userID // push.packet.userID?
        let packet = RawPushPacket(userId: userId, contextId: push.contextID, command: .rust(push.cmd), data: push.payload)
        factory().handlePushPacket(userResolver: userResolver, packet: packet)
    }
}

private class ServerPushHandler: UserPushHandler {
    static func build(_ factory: @escaping () -> ByteViewPushHandler) -> ((UserResolver) -> ServerPushHandler) {
        { ServerPushHandler(factory: factory, resolver: $0) }
    }

    let factory: () -> ByteViewPushHandler
    init(factory: @escaping () -> ByteViewPushHandler, resolver: UserResolver) {
        self.factory = factory
        super.init(resolver: resolver)
    }

    func process(push: ServerPushPacket<Data>) throws {
        let userId = userResolver.userID // push.packet.userID?
        let packet = RawPushPacket(userId: userId, contextId: push.contextID, command: .server(push.cmd), data: push.payload)
        factory().handlePushPacket(userResolver: userResolver, packet: packet)
    }
}

private class StartupPush {
    /// 网络状态变化，会触发registerClientInfo拉取会议信息
    /// - pushWebSocketStatus = 5005
    static let webSocket = StartupPushReceiver {
        try $0.resolve(assert: MeetingNotifyService.self).handleWebSocketPush($1.message)
    }

    /// 会议信息
    /// - notifyVideoChat = 2210
    static let notifyVideoChat = StartupPushReceiver {
        try $0.resolve(assert: MeetingNotifyService.self).handlePushVideoChat($1.message)
        Push.notifyVideoChat.consumePacket($1)
    }

    /// 推送提醒
    /// - pushVideoChatPrompt = 2371
    static let videoChatPrompt = StartupPushReceiver {
        try $0.resolve(assert: MeetingNotifyService.self).handlePromptPush($1.message)
    }

    /// 推送通知
    /// - pushVideoChatNotice = 2215
    static let videoChatNotice = StartupPushReceiver {
        let httpClient = try $0.resolve(assert: HttpClient.self)
        ResidentPushObserver.shared.didReceiveNotice($1.message, httpClient: httpClient)
        Push.videoChatNotice.consumePacket($1)
    }

    /// 面试满意度问卷推送(89376)
    /// - pushInterviewQuestionnaire = 89376
    static let interviewQuestionnaire = StartupPushReceiver {
        let dep = try InterviewQuestionnaireDependencyImpl(userResolver: $0)
        ResidentPushObserver.shared.didReceiveInterviewQuestionnaire($1.message, dependency: dep)
    }
}

protocol ByteViewPushHandler {
    func handlePushPacket(userResolver: UserResolver, packet: RawPushPacket)
}

private class StartupPushReceiver<T: NetworkDecodable>: ByteViewPushHandler {
    let handler: (UserResolver, PushPacket<T>) throws -> Void
    init(handler: @escaping (UserResolver, PushPacket<T>) throws -> Void) {
        self.handler = handler
    }

    func handlePushPacket(userResolver: UserResolver, packet: RawPushPacket) {
        PushUtil.process(packet: packet, canHandle: { _ in true }) {
            try self.handler(userResolver, $0)
        }
    }
}

extension PushReceiver: ByteViewPushHandler where T: NetworkDecodable {
    func handlePushPacket(userResolver: UserResolver, packet: RawPushPacket) {
        PushUtil.process(packet: packet, canHandle: {
            self.shouldConsumePacket($0)
        }, handler: {
            self.consumePacket($0)
        })
    }
}

private struct PushUtil {
    static func process<T>(packet: RawPushPacket, canHandle: @escaping (RawPushPacket) -> Bool,
                           handler: @escaping (PushPacket<T>) throws -> Void) where T: NetworkDecodable {
        let startTime = CACurrentMediaTime()
        let logger = Logger.push.withContext(packet.contextId).withTag(packet.command.description)
        let isLogEnabled = packet.command.isLogEnabled
        if isLogEnabled {
            logger.info("didReceivePushMessage for user \(packet.userId)")
        }
        Queue.push.async {
            let t0 = CACurrentMediaTime()
            if !canHandle(packet) {
                logger.debug("ignored")
                return
            }
            let latency = t0 - startTime
            if latency > 2 {
                logger.warn("wait too long, latency = \(Util.formatTime(latency))")
                let fromSouce = "[\(packet.contextId)]\(packet.command)"
                DevTracker.post(.warning(.push_queue_timeout).category(.network).params([.latency: latency, .from_source: fromSouce]))
            }

            do {
                if isLogEnabled {
                    logger.info("start, latency = \(Util.formatTime(latency))")
                }
                let message = try T.init(serializedData: packet.data)
                try handler(PushPacket(userId: packet.userId, contextId: packet.contextId, command: packet.command, message: message))
                let duration = CACurrentMediaTime() - t0
                if duration > 2 {
                    logger.warn("process too long, duration = \(Util.formatTime(duration)), message = \(message)")
                } else if isLogEnabled {
                    logger.info("process finished, duration = \(Util.formatTime(duration)), message = \(message)")
                }
            } catch {
                let duration = Util.formatTime(CACurrentMediaTime() - t0)
                logger.error("process failed: deserialization failed, duration = \(duration), error = \(error)")
            }
        }
    }
}

private extension NetworkCommand {
    var isLogEnabled: Bool {
        switch self {
        case .rust(.pushGrootCells):
            return false
        default:
            return true
        }
    }
}

private final class InterviewQuestionnaireDependencyImpl: InterviewQuestionnaireDependency {
    let userResolver: UserResolver
    let httpClient: HttpClient
    var userId: String { userResolver.userID }
    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        self.httpClient = try userResolver.resolve(assert: HttpClient.self)
    }

    func openURL(_ url: URL) {
        let nav = userResolver.navigator
        SceneManager.shared.active(scene: .mainScene(), from: nil) { w, _ in
            if let w = w {
                nav.open(url, from: w)
            }
        }
    }
}
