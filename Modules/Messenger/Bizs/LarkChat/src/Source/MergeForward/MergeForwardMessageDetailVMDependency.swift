//
//  MergeForwardMessageDetailVMDependency.swift
//  LarkChat
//
//  Created by 袁平 on 2021/6/22.
//

import Foundation
import LarkContainer
import TangramService
import RxSwift
import RustPB
import LarkModel
import LarkCore
import LarkMessengerInterface
import LarkSDKInterface

final class MergeForwardMessageDetailVMDependency: UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedInjectedLazy var urlPreviewAPI: URLPreviewAPI?
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?
    @ScopedInjectedLazy var messageAPI: MessageAPI?
    let inlinePreviewVM: MessageInlineViewModel = MessageInlineViewModel()
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    /// 通过chatID获取首屏Messages
    final public func fetchPreviewChatMessages(chatId: String) -> Observable<[Message]> {
        return messageAPI?.fetchChatMessages(chatId: chatId,
                                            scene: .firstScreen,
                                            redundancyCount: 5,
                                            count: 30,
                                            expectDisplayWeights: nil,
                                            redundancyDisplayWeights: nil,
                                            needResponse: true).map({ result -> [Message] in
            return result.messages
        }).observeOn(MainScheduler.instance)
        ?? .error(UserScopeError.disposed)
    }
}
