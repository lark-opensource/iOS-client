//
//  RustMessageModule.swift
//  Lark
//
//  Created by linlin on 2017/8/15.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RustPB
import LarkModel
import LarkSDKInterface
import LarkAccountInterface

final class RustMessageModule {
    class func sortMessages(_ a: LarkModel.Message, _ b: LarkModel.Message) -> Bool {
        if a.position == b.position {
            return a.createTime < b.createTime
        }
        return a.position < b.position
    }

    class func fetchMessages(messageIds: [String], client: SDKRustService, needTryLocal: Bool = true) -> Observable<RustPB.Basic_V1_Entity> {
        var request = RustPB.Im_V1_MGetMessagesRequest()
        request.messageIds = messageIds
        if needTryLocal {
            request.syncDataStrategy = .tryLocal
        } else {
            request.syncDataStrategy = .local
        }
        return client.sendAsyncRequest(request, transform: { (res: RustPB.Im_V1_MGetMessagesResponse) -> RustPB.Basic_V1_Entity in
            return res.entity
        })
    }
}
