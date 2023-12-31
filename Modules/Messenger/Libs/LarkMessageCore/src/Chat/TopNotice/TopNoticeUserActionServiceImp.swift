//
//  TopNoticeUserActionServiceImp.swift
//  LarkMessageCore
//
//  Created by liluobin on 2021/12/14.
//

import Foundation
import UIKit
import LarkModel
import RxSwift
import RustPB
import LarkContainer
import LarkSDKInterface
import LarkMessengerInterface

/// 这个监听本地的patch结果
/// 普通群完全可以依赖服务端的PUSH，但是超大群的话 push可能会被限流，PUSH不一定及时 为了保证用户的体验
/// 将本地patch调用后，服务端返回的结果当做PUSH发送，数据源接收的地方会有数据校验，虽然会有多次push，但是会过滤掉无用的数据，不影响使用
public final class TopNoticeUserActionServiceImp: TopNoticeUserActionService {
    public let updatePublishSubject = PublishSubject<(ChatTopNotice, Int64)>()
    private let chatAPI: ChatAPI
    init(chatAPI: ChatAPI) {
        self.chatAPI = chatAPI
    }
    /// 替换置顶消息& 删除 & 关闭置顶消息
    public func patchChatTopNoticeWithChatID(_ chatId: Int64,
                                             type: RustPB.Im_V1_PatchChatTopNoticeRequest.ActionType,
                                             senderId: Int64?,
                                             messageId: Int64?) -> Observable<RustPB.Im_V1_PatchChatTopNoticeResponse> {
        return self.chatAPI.patchChatTopNoticeWithChatID(chatId, type: type, senderId: senderId, messageId: messageId)
            .observeOn(MainScheduler.instance)
            .do { [weak self] (response) in
                self?.updatePublishSubject.onNext((response.topNoticeInfo, chatId))
            }
    }
}
