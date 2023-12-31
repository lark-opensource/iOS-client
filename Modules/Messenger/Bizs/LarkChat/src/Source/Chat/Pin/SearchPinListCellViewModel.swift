//
//  SearchPinListCellViewModel.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/26.
//

import UIKit
import Foundation
import LarkModel
import EENavigator
import LarkMessengerInterface
import LarkSDKInterface
import LarkContainer

final class SearchPinListCellViewModel {
    let navigator: Navigatable
    let result: SearchResultType

    init(navigator: Navigatable, result: SearchResultType) {
        self.navigator = navigator
        self.result = result
    }

    func toNextPage(from: UIViewController) {
        guard case .message(let meta) = result.meta else { return }
        if !meta.threadID.isEmpty {
            if meta.position == replyInThreadMessagePosition {
                let body = ReplyInThreadByIDBody(threadId: meta.threadID, loadType: .root)
                navigator.push(body: body, from: from)
            } else {
                let body = ThreadDetailByIDBody(threadId: meta.threadID, loadType: .root)
                navigator.push(body: body, from: from)
            }
        } else {
            let body = ChatControllerByIdBody(
                chatId: meta.chatID,
                position: meta.position
            )
            navigator.push(body: body, from: from)
        }
    }
}
