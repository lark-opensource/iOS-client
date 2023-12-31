//
//  MessageCardPageService.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/11/9.
//

import Foundation
import UniversalCard
import LarkMessageBase
import LKCommonsLogging

// 消息卡片进入会话时机统一回调器
public class MessageCardPageService: PageService {
    static private let logger = Logger.log(MessageCardPageService.self, category: "MessageCardPageService")
    private var cardSharePoolService: UniversalCardSharePoolProtocol?
    public init(pageContainer: PageContainer?) {
        guard let pageContainer = pageContainer else {
            Self.logger.error("UniversalCardSharePoolProtocol create fail:  pageContainer is nil")
            return
        }
        cardSharePoolService = pageContainer.resolve(UniversalCardSharePoolProtocol.self)
    }

    ///对应viewDidLoad
    public func pageViewDidLoad() {
        cardSharePoolService?.createNew(count: 5)
    }

    public func pageDeinit() {
        cardSharePoolService?.clearAll()
    }
}
