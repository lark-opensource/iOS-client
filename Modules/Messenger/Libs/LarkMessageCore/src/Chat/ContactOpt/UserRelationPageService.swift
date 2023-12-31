//
//  UserRelationPageService.swift
//  LarkMessageCore
//
//  Created by JackZhao on 2020/10/22.
//

import Foundation
import LarkContainer
import LarkMessageBase
import RxSwift
import LarkModel
import LarkSDKInterface
import LarkSetting
import LarkMessengerInterface

public final class UserRelationPageService: PageService {
    private var userRelationService: UserRelationService?
    private let chat: Chat
    lazy var externalContactOptEnable: Bool = {
        return self.chat.type == .p2P && self.chat.isCrossTenant
    }()

    private let disposeBag = DisposeBag()

    public init(chat: Chat, userRelationService: UserRelationService?) {
        self.chat = chat
        self.userRelationService = userRelationService
    }

    public func pageDeinit() {
        guard externalContactOptEnable else {
            return
        }
        let userId = self.chat.chatter?.id ?? ""
        // 移除当前单聊用户关系的监听
        self.userRelationService?.removeBlockStatusBehaviorRelay(userId: userId)
        self.userRelationService?.removeUserRelationBehaviorRelay(userId: userId)
    }

    deinit {
        print("UserRelationPageService deinit")
    }

}
