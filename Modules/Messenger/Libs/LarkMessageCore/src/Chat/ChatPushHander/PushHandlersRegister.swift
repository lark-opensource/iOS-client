//
//  PushHandlersRegister.swift
//  LarkChat
//
//  Created by zc09v on 2019/4/14.
//

import Foundation
import LarkContainer
import LarkModel
import ThreadSafeDataStructure
import LKCommonsLogging
import LarkMessageBase
import AppContainer

public class PushHandler: LarkContainer.UserResolverWrapper {
    public let userResolver: UserResolver
    weak var dataSourceAPI: HandlePushDataSourceAPI?
    init(needCachePush: Bool, userResolver: UserResolver) {
        self.needCachePush = needCachePush
        self.userResolver = userResolver
    }

    func startObserve() throws {
        assertionFailure("must override")
    }

    var needCachePush: Bool {
            didSet {
                if !needCachePush {
                    for perform in self.pushPerformCache.getImmutableCopy() {
                        perform()
                    }
                }
            }
        }
    private var pushPerformCache: SafeArray<() -> Void> = [] + .readWriteLock
    func perform(_ perform: @escaping () -> Void) {
        if !needCachePush {
            perform()
        } else {
            self.pushPerformCache.append(perform)
        }
    }
}

public protocol PushData {
    var message: LarkModel.Message { get }
}

public protocol HandlePushDataSourceAPI: AnyObject {
    func update(messageIds: [String], doUpdate: @escaping (PushData) -> PushData?, completion: ((Bool) -> Void)?)
    func update(original: @escaping (PushData) -> PushData?, completion: ((Bool) -> Void)?)
}

extension HandlePushDataSourceAPI {
    public func update(messageIds: [String], doUpdate: @escaping (PushData) -> PushData?) {
        update(messageIds: messageIds, doUpdate: doUpdate, completion: nil)
    }
    public func update(original: @escaping (PushData) -> PushData?) {
        update(original: original, completion: nil)
    }
}

public protocol PushHandlerFactory: NSObject {
    func createHandler(channelId: String, needCachePush: Bool, userResolver: UserResolver) -> PushHandler
}

//Chat/ThreadChat/ThreadDetail三个页面通用模型为Message,Message纬度相关属性的推送变更处理是可复用的
public class BasePushHandlersRegister {
    static let logger = Logger.log(BasePushHandlersRegister.self, category: "Business.Chat")
    var factories: [PushHandlerFactory.Type] {
        return []
    }

    //需要提前监听push的handler
    var preObserveFactories: [PushHandlerFactory.Type] {
        return []
    }

    var handlers: [PushHandler] = []
    var preObserveHandlers: [PushHandler] = []
    let channelId: String
    let userResolver: UserResolver
    public init(channelId: String, userResolver: UserResolver) {
        self.channelId = channelId
        self.userResolver = userResolver
    }

    public func startObserve(_ api: HandlePushDataSourceAPI?) {
        self.handlers = self.factories.map { (type) -> PushHandler in
            return type.init().createHandler(channelId: channelId, needCachePush: false, userResolver: userResolver)
        }
        for handler in handlers {
            handler.dataSourceAPI = api
            try? handler.startObserve()
        }
    }

    public func startPreObserve() {
        self.preObserveHandlers = self.preObserveFactories.map { (type) -> PushHandler in
            return type.init().createHandler(channelId: channelId, needCachePush: true, userResolver: userResolver)
        }
        Self.logger.info("chatTrace startPreObserve \(channelId)")
        for handler in preObserveHandlers {
            try? handler.startObserve()
        }
    }

    public func performCachePush(api: HandlePushDataSourceAPI) {
        for handler in preObserveHandlers {
            handler.dataSourceAPI = api
            handler.needCachePush = false
        }
    }
}

/// Chat页面注册相关推送
public final class ChatPushHandlersRegister: BasePushHandlersRegister {
    override var factories: [PushHandlerFactory.Type] {
        return [FileMessageNoAuthorizePushHandlerFactory.self,
                DataInSpaceStorePushHandlerFactory.self,
                MessageReadCountPushHandlerFactory.self,
                ChatterPushHandlerFactory.self,
                TranslateInfoPushHandlerFactory.self,
                NickNamePushHandlerFactory.self,
                AudioRecognitionPushHandlerFactory.self,
                UpdateImageTranslationInfoHandlerFactory.self,
                UpdateInlineEntryHandlerFactory.self]
    }

    override var preObserveFactories: [PushHandlerFactory.Type] {
        return [
                UrgentAckChatterStatusPushHandlerFactory.self,
                UrgentPushHandlerFactory.self,
                MessageReactionsPushHandlerFactory.self,
                MessageFeedbackStatusPushHandlerFactory.self,
                MessageReadStatesPushHandlerFactory.self,
                UpdateURLPreviewHandlerFactory.self]
    }
}

/// ThreadChat、ThreadFilter页面注册相关推送
public final class ThreadChatPushHandlersRegister: BasePushHandlersRegister {
    override var factories: [PushHandlerFactory.Type] {
        return [ChatterPushHandlerFactory.self,
                NickNamePushHandlerFactory.self,
                TranslateInfoPushHandlerFactory.self,
                UpdateImageTranslationInfoHandlerFactory.self,
                MessageReactionsPushHandlerFactory.self,
                MessageReadStatesPushHandlerFactory.self,
                UpdateInlinePreviewHandlerFactory.self]
    }
}

/// ThreadRecommend页面注册相关推送
public final class ThreadRecommendPushHandlersRegister: BasePushHandlersRegister {
    override var factories: [PushHandlerFactory.Type] {
        return [TranslateInfoPushHandlerFactory.self,
                UpdateImageTranslationInfoHandlerFactory.self,
                UpdateInlinePreviewHandlerFactory.self]
    }
}

/// ThreadDetail页面注册相关推送
public final class ThreadDetailPushHandlersRegister: BasePushHandlersRegister {
    override var factories: [PushHandlerFactory.Type] {
        return [ChatterPushHandlerFactory.self,
                TranslateInfoPushHandlerFactory.self,
                UpdateImageTranslationInfoHandlerFactory.self,
                MessageReactionsPushHandlerFactory.self,
                MessageReadStatesPushHandlerFactory.self,
                UpdateInlinePreviewHandlerFactory.self]
    }
}
/// reply in thread 页面注册逻辑
public final class ReplyInThreadPushHandlersRegister: BasePushHandlersRegister {
    override var factories: [PushHandlerFactory.Type] {
        return [ChatterPushHandlerFactory.self,
                TranslateInfoPushHandlerFactory.self,
                UpdateImageTranslationInfoHandlerFactory.self,
                MessageReactionsPushHandlerFactory.self,
                MessageReadStatesPushHandlerFactory.self,
                UpdateURLPreviewHandlerFactory.self,
                AudioRecognitionPushHandlerFactory.self]
    }
}

/// MessageDetail页面注册相关推送
public final class MessageDetailPushHandlersRegister: BasePushHandlersRegister {
    override var factories: [PushHandlerFactory.Type] {
        return [UrgentPushHandlerFactory.self,
                TranslateInfoPushHandlerFactory.self,
                UpdateImageTranslationInfoHandlerFactory.self,
                MessageReactionsPushHandlerFactory.self,
                MessageReadStatesPushHandlerFactory.self,
                UpdateURLPreviewHandlerFactory.self]
    }
}
/// 合并转发页面注册相关推送
public final class MergeForwardPushHandlersRegister: BasePushHandlersRegister {
    override var factories: [PushHandlerFactory.Type] {
        return [TranslateInfoPushHandlerFactory.self]
    }
}
