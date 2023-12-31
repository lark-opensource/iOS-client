//
//  TodoService.swift
//  TodoInterface
//
//  Created by 张威 on 2021/3/31.
//

import RxSwift

/// Todo 对外接口/能力

public protocol TodoService {
    /// 是否展示会话引导
    func shouldDisplayGuideToastInChat() -> Bool
    /// 会话引导已展示
    func setGuideInChatDisplayed()
    /// url 是否是任务清单 AppLink
    func isTaskListAppLink(_ url: URL) -> Bool

    /// 是否发送到会话相关
    func getSendToChatIsSeleted() -> Bool
    func setSendToChatIsSeleted(isSeleted: Bool)
}
