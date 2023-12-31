//
//  MessageContentService.swift
//  LarkMessengerInterface
//
//  Created by 赵家琛 on 2020/9/27.
//

import Foundation
import RxSwift
import LarkModel

public protocol MessageContentService {
    func getMessageContent(messageIds: [String]) -> Observable<[String: Message]>?
}
