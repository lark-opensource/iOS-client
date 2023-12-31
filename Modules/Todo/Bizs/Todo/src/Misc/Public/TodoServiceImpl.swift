//
//  TodoServiceImpl.swift
//  Todo
//
//  Created by 张威 on 2021/3/31.
//

import RxSwift
import TodoInterface
import LarkContainer
import LarkAccountInterface
import LarkStorage

class TodoServiceImpl: TodoService, UserResolverWrapper {

    var userResolver: LarkContainer.UserResolver

    // 会话新用户引导的 kv
    private lazy var guideInChatConfig = KVConfig(
        key: Utils.KVKey.guideInChat,
        default: false,
        store: KVStores.udkv(
            space: .user(id: userResolver.userID),
            domain: Domain.biz.todo
        )
    )
    // 是否发送到会话的 kv
    private lazy var sendToChatConfig = KVConfig(
        key: Utils.KVKey.sendToChat,
        default: true,
        store: KVStores.udkv(
            space: .user(id: userResolver.userID),
            domain: Domain.biz.todo
        )
    )
    @ScopedInjectedLazy private var chatTodoApi: ChatTodoApi?

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    /// 是否展示会话引导
    func shouldDisplayGuideToastInChat() -> Bool {
        return !guideInChatConfig.value
    }

    /// 会话引导已展示
    func setGuideInChatDisplayed() {
        guideInChatConfig.value = true
    }

    /// url 是否是任务清单 AppLink
    func isTaskListAppLink(_ url: URL) -> Bool {
        return url.path == TodoAppLink.TaskList && url.queryParameters["guid"] != nil
    }

    func getSendToChatIsSeleted() -> Bool {
        sendToChatConfig.value
    }

    func setSendToChatIsSeleted(isSeleted: Bool) {
        sendToChatConfig.value = isSeleted
    }
}
