//
//  AppreciableTracker.swift
//  LarkChatSetting
//
//  Created by qihongye on 2020/11/3.
//

import UIKit
import Foundation
import LarkModel
import LarkAccountInterface
import LarkSDKInterface
import AppReciableSDK
import LarkContainer

enum ChatType: Int {
    case unknown = 0
    case single
    case group
    case topic
    case threadDetail

    @inline(__always)
    static func getChatType(chat: Chat) -> ChatType {
        if chat.type == .p2P {
            return .single
        }
        if chat.type == .group {
            return .group
        }
        if chat.chatMode == .threadV2 || chat.chatMode == .thread {
            return .topic
        }
        return .threadDetail
    }
}

final class AppreciableTracker {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    struct TrackerInfo {
        var startTimeStamp = CACurrentMediaTime()
        var sdkCost: CFTimeInterval = 0
        var initViewCost: CFTimeInterval = 0
        var firstRenderCost: CFTimeInterval = 0
        var iosGetLocalChatCost: CFTimeInterval = 0
        let pageName: String
        let chatterCount: Int32
        let feedID: String
        let chatType: ChatType
        let isExternal: Bool
        let isOwner: Bool

        init(userResolver: UserResolver, pageName: String = "", chat: Chat? = nil) {
            self.pageName = pageName
            self.chatterCount = chat?.chatterCount ?? 0
            self.feedID = chat?.id ?? ""
            if let chat = chat {
                self.chatType = ChatType.getChatType(chat: chat)
            } else {
                self.chatType = .unknown
            }
            self.isOwner = chat?.ownerId == userResolver.userID
            self.isExternal = chat?.isPublic ?? false
        }
    }

    private var info: TrackerInfo?
    private var isStart = false

    func start(chat: Chat? = nil, pageName: String = "") {
        isStart = true
        self.info = TrackerInfo(userResolver: userResolver, pageName: pageName, chat: chat)
    }

    func updateGetLocalChatCost(_ cost: CFTimeInterval) {
        if !isStart {
            return
        }
        info?.iosGetLocalChatCost = cost
    }

    func updateSDKCost(_ cost: CFTimeInterval) {
        if !isStart {
            return
        }
        info?.sdkCost = cost
    }

    func initViewStart() {
        if !isStart {
            return
        }
        info?.initViewCost = CACurrentMediaTime()
    }

    func initViewEnd() {
        guard isStart, let info = info else {
            return
        }
        self.info?.initViewCost = CACurrentMediaTime() - info.initViewCost
    }

    func viewDidLoadEnd() {
        guard isStart, let info = info else {
            return
        }
        self.info?.firstRenderCost = CACurrentMediaTime() - info.startTimeStamp
    }

    func end() {
        if !isStart {
            return
        }
        isStart = false
        guard let info = info else {
            return
        }

        let cost = Int((CACurrentMediaTime() - info.startTimeStamp) * 1000)
        AppReciableSDK.shared.timeCost(params: TimeCostParams(
            biz: .Messenger, scene: .Chat, event: .enterChatSetting, cost: cost,
            page: info.pageName,
            extra: Extra(
                isNeedNet: true,
                latencyDetail: [
                    "init_view_cost": Int(info.initViewCost * 1000),
                    "first_render_cost": Int(info.firstRenderCost * 1000),
                    "sdk_cost": Int(info.sdkCost * 1000),
                    "ios_get_local_chat_cost": Int(info.iosGetLocalChatCost * 1000)
                ],
                metric: [
                    "chatter_count": info.chatterCount,
                    "feed_id": info.feedID
                ],
                category: [
                    "chat_type": info.chatType.rawValue,
                    "is_owner": info.isOwner,
                    "is_external": info.isExternal
                ]
            )
        ))
    }

    func error(_ error: Error) {
        guard let info = info, let error = error.underlyingError as? APIError else {
            return
        }
        AppReciableSDK.shared.error(params: ErrorParams(
            biz: .Messenger, scene: .Chat, event: .enterChatSetting, errorType: .SDK,
            errorLevel: .Fatal, errorCode: Int(error.code), userAction: nil,
            page: info.pageName, errorMessage: error.errorDescription,
            extra: Extra(
                isNeedNet: true,
                latencyDetail: nil,
                metric: [
                    "chatter_count": info.chatterCount,
                    "feed_id": info.feedID
                ],
                category: [
                    "chat_type": info.chatType.rawValue,
                    "is_owner": info.isOwner,
                    "is_external": info.isExternal
                ]
            )
        ))
    }
}

final class GroupChatDetailTracker {
    struct TrackerInfo {
        var startTimeStamp: CFTimeInterval = 0
        var initViewStart: CFTimeInterval = 0
        var getLocalChatCost: CFTimeInterval = 0
        var initViewCost: CFTimeInterval = 0
        var viewDidLoadCost: CFTimeInterval = 0
        var sdkCost: CFTimeInterval = 0
    }

    enum ActionType: Int {
        case unknown = 0
        case add
        case delete
        case search
    }

    private var info: TrackerInfo
    private let pageName = "GroupChatDetailViewController"
    private let chatType: ChatType
    private let chatterCount: Int32
    private let isExternal: Bool
    private let feedID: String
    private var hasEnd = false

    init(chat: Chat) {
        self.info = TrackerInfo()
        self.chatType = ChatType.getChatType(chat: chat)
        self.chatterCount = chat.chatterCount
        self.isExternal = chat.isCrossTenant
        self.feedID = chat.id
    }

    func start(_ time: CFTimeInterval? = nil) {
        self.info.startTimeStamp = time ?? CACurrentMediaTime()
    }

    func getLocalChatEnd() {
        self.info.getLocalChatCost = CACurrentMediaTime() - self.info.initViewStart
    }

    func initViewStart() {
        self.info.initViewStart = CACurrentMediaTime()
    }

    func initViewEnd() {
        self.info.initViewCost = CACurrentMediaTime() - self.info.initViewCost
    }

    func viewDidLoadEnd() {
        self.info.viewDidLoadCost = CACurrentMediaTime() - self.info.initViewStart
    }

    func sdkCostStart() {
        self.info.sdkCost = CACurrentMediaTime()
    }

    func sdkCostEnd() {
        self.info.sdkCost = CACurrentMediaTime() - self.info.sdkCost
    }

    func end() {
        if hasEnd {
            return
        }
        hasEnd = true
        let cost = Int((CACurrentMediaTime() - info.startTimeStamp) * 1000)
        AppReciableSDK.shared.timeCost(params: TimeCostParams(
            biz: .Messenger, scene: .Chat, event: .showChatMembers, cost: cost,
            page: pageName,
            extra: Extra(
                isNeedNet: true,
                latencyDetail: [
                    "ios_get_local_chat_cost": Int(info.getLocalChatCost * 1000),
                    "sdk_cost": Int(info.sdkCost * 1000),
                    "init_view_cost": Int(info.initViewCost * 1000),
                    "first_render": Int(info.viewDidLoadCost * 1000)
                ],
                metric: [
                    "chatter_count": chatterCount,
                    "feed_id": feedID
                ],
                category: [
                    "chat_type": chatType.rawValue,
                    "is_external": isExternal
                ]
            )
        ))
    }

    func error(_ error: Error) {
        var errorCode = 0
        var errorMessage: String?
        if let error = error.underlyingError as? APIError {
            errorCode = Int(error.code)
            errorMessage = error.localizedDescription
        } else {
            errorCode = (error as NSError).code
            errorMessage = (error as NSError).localizedDescription
        }
        AppReciableSDK.shared.error(params: ErrorParams(
            biz: .Messenger, scene: .Chat, event: .showChatMembers, errorType: .SDK, errorLevel: .Exception,
            errorCode: errorCode, userAction: nil, page: pageName, errorMessage: errorMessage,
            extra: Extra(
                isNeedNet: true,
                latencyDetail: nil,
                metric: [
                    "chatter_count": chatterCount,
                    "feed_id": feedID
                ],
                category: [
                    "chat_type": chatType.rawValue,
                    "is_external": isExternal
                ]
            )
        ))
    }

    func actionCost(_ cost: CFTimeInterval, sdkCost: CFTimeInterval? = nil, iosFetchChatCost: CFTimeInterval? = nil, action: ActionType) {
        var latencyDetail = [
            "sdk_cost": Int(cost * 1000)
        ]
        if let sdkCost = sdkCost {
            latencyDetail["sdk_cost"] = Int(sdkCost * 1000)
        }
        if let iosFetchChatCost = iosFetchChatCost {
            latencyDetail["ios_fetch_chat_cost"] = Int(iosFetchChatCost * 1000)
        }
        AppReciableSDK.shared.timeCost(params: TimeCostParams(
            biz: .Messenger, scene: .Chat, event: .chatMembersAction, cost: Int(cost * 1000),
            page: pageName,
            extra: Extra(
                isNeedNet: true,
                latencyDetail: latencyDetail,
                metric: [
                    "chatter_count": chatterCount,
                    "feed_id": feedID
                ],
                category: [
                    "action_type": action.rawValue,
                    "chat_type": chatType.rawValue,
                    "is_external": isExternal
                ]
            )
        ))
    }

    func actionError(_ error: Error, action: ActionType) {
        var errorCode = 0
        var errorMessage: String?
        if let error = error.underlyingError as? APIError {
            errorCode = Int(error.code)
            errorMessage = error.localizedDescription
        } else {
            errorCode = (error as NSError).code
            errorMessage = (error as NSError).localizedDescription
        }
        AppReciableSDK.shared.error(params: ErrorParams(
            biz: .Messenger, scene: .Chat, event: .chatMembersAction, errorType: .SDK, errorLevel: .Exception,
            errorCode: errorCode, userAction: nil, page: pageName, errorMessage: errorMessage,
            extra: Extra(
                isNeedNet: true,
                latencyDetail: nil,
                metric: [
                    "chatter_count": chatterCount,
                    "feed_id": feedID
                ],
                category: [
                    "action_type": action.rawValue,
                    "chat_type": chatType.rawValue,
                    "is_external": isExternal
                ]
            )
        ))
    }
}
