//
//  MailAPI.swift
//  LarkMail
//
//  Created by 谭志远 on 2019/5/19.
//  Copyright © 2019年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel

public protocol MailAPI {
    func mailSendCard(threadId: String, messageIds: [String], chatIds: [String], note: String) -> Observable<()>
    func mailShareAttachment(chatIds: [String], attachmentToken: String, note: String, isLargeAttachment: Bool) -> Observable<()>
}

public typealias MailAPIProvider = () -> MailAPI
