//
//  ShareContentCodeViewModel.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/3/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import ByteViewNetwork

enum ShareContentEntryCodeType {
    case shareCode(code: String)
    case meetingNumber(number: String)
}

typealias ShareContentCodeCommitAction = (ShareContentEntryCodeType, @escaping (Result<ShareScreenToRoomResponse?, Error>) -> Void) -> Void

final class ShareContentCodeViewModel {
    static let logger = Logger.localShare

    let commitAction: ShareContentCodeCommitAction
    let source: MeetingEntrySource

    init(commitAction: @escaping ShareContentCodeCommitAction, source: MeetingEntrySource) {
        self.commitAction = commitAction
        self.source = source
    }
}
