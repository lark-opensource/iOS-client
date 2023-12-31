//
//  CustomerChatPageService.swift
//  LarkCustomerService
//
//  Created by ByteDance on 2023/7/18.
//

import Foundation
import LarkMessageBase
import LarkModel
import RxSwift
import LKCommonsLogging
import LarkSetting

public final class CustomerChatPageService: PageService {
    static let logger = Logger.log(CustomerChatPageService.self, category: "LarkCustomerService")
    private let chat: Chat
    private let disposeBag: DisposeBag = DisposeBag()
    private var customerService: LarkCustomerServiceAPI?

    public init(chat: Chat, customerService: LarkCustomerServiceAPI?) {
        self.chat = chat
        self.customerService = customerService
    }

    public func afterFirstScreenMessagesRender() {
        let chatId = self.chat.id
        Self.logger.info("enterNewCustomerChat call \(chatId) \(chat.isOcicCustomerService)")
        guard chat.isOcicCustomerService else {
            return
        }
        customerService?.enterNewCustomerChat(chatid: self.chat.id).subscribe(onNext: {
            Self.logger.info("enterNewCustomerChat call is finish \(chatId)")
        }, onError: { error in
            Self.logger.error("enterNewCustomerChat call is error \(chatId)", error: error)
        }).disposed(by: self.disposeBag)
    }
}
