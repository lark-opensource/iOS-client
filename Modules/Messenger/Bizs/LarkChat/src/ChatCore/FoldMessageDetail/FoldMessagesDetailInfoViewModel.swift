//
//  FoldMessagesDetailInfoViewModel.swift
//  LarkChat
//
//  Created by liluobin on 2022/9/19.
//

import Foundation
import UIKit
import RxSwift
import LarkContainer
import LarkSDKInterface
import RustPB
import LarkModel
import LarkRichTextCore

final class FoldMessagesDetailInfoViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    let messageAPI: MessageAPI
    let disposeBag = DisposeBag()
    private var startTimeMs: Int64 = 0
    var hasMore: Bool = false
    var cellViewModels: [FoldMessageDetailCellViewModel] = []
    let foldId: Int64
    private let chat: Chat
    private let message: Message
    private let content: Basic_V1_RichText
    private let atColor: AtColor

    init(userResolver: UserResolver,
         content: Basic_V1_RichText,
         chat: Chat,
         message: Message,
         atColor: AtColor
    ) throws {
        self.userResolver = userResolver
        self.messageAPI = try userResolver.resolve(assert: MessageAPI.self)
        self.chat = chat
        self.foldId = message.foldId
        self.message = message
        self.content = content
        self.atColor = atColor
    }

    func loadData(finish: ((Error?) -> Void)?) {
        let timeMs = self.startTimeMs
        self.messageAPI.messageFoldFollowListWith(foldId: foldId,
                                                  count: 30,
                                                  chatId: Int64(self.chat.id) ?? 0,
                                                  startTimeMs: timeMs)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response: RustPB.Im_V1_GetMessageFoldFollowListResponse) in
                guard let self = self else { return }
                self.startTimeMs = response.follows.last?.followTimeMs ?? 0
                self.hasMore = response.hasMore_p
                if timeMs == 0 {
                    self.cellViewModels = response.follows.map({ entity in
                        let chatter: Chatter? = self.chatterFromEntity(entity: response.entity,
                                                                       chatID: self.chat.id,
                                                                       userId: "\(entity.userID)")
                        return FoldMessageDetailCellViewModel(userResolver: self.userResolver,
                                                              entity: entity,
                                                              content: self.content,
                                                              chatter: chatter,
                                                              chat: self.chat,
                                                              message: self.message,
                                                              atColor: self.atColor)
                    })
                } else {
                    self.cellViewModels.append(contentsOf: response.follows.map({ entity in
                        let chatter: Chatter? = self.chatterFromEntity(entity: response.entity,
                                                                       chatID: self.chat.id,
                                                                       userId: "\(entity.userID)")
                        return FoldMessageDetailCellViewModel(userResolver: self.userResolver,
                                                              entity: entity,
                                                              content: self.content,
                                                              chatter: chatter,
                                                              chat: self.chat,
                                                              message: self.message,
                                                              atColor: self.atColor)
                    }))
                }
                finish?(nil)
            }, onError: { error in
                finish?(error)
            }).disposed(by: self.disposeBag)
    }

    func refreshData(finish: ((Error?) -> Void)?) {
        self.loadData(finish: finish)
    }

    func loadFristScreenreData(finish: ((Error?) -> Void)?) {
        self.startTimeMs = 0
        self.loadData(finish: finish)
    }

    func chatterFromEntity(entity: RustPB.Basic_V1_Entity, chatID: String, userId: String) -> Chatter? {
        if let chatterPB = entity.chatChatters[chatID]?.chatters[userId] ?? entity.chatters[userId] {
            return Chatter.transform(pb: chatterPB)
        }
        return nil
    }

}
