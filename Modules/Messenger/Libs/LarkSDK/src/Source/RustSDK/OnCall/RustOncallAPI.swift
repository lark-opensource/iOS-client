//
//  RustOncallAPI.swift
//  Lark
//
//  Created by liuwanlin on 2017/12/16.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RustPB
import LarkSDKInterface

import LarkModel

final class RustOncallAPI: LarkAPI, OncallAPI {
    //创建自己的值班号会话,返回chatId
    func putOncallChat(userId: String, oncallId: String, additionalData: AdditionalData?) -> Observable<String> {
        var request = CreateOncallChatRequest()
        request.userID = userId
        request.oncallID = oncallId
        if let additionalData = additionalData {
            request.additionalData = additionalData
        }
        return client.sendAsyncRequest(request) { (response: CreateOncallChatResponse) in
            response.chatID
        }.subscribeOn(scheduler)
    }

    func finishOncallChat(chatId: String, oncallId: String) -> Observable<Void> {
        var request = PutFinishOncallRequest()
        request.chatID = chatId
        request.oncallID = oncallId
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func getHomePageOncalls(fromLocal: Bool) -> Observable<[Oncall]> {
        var request = GetHomePageOncallsRequest()
        request.fromLocal = fromLocal

        return client.sendAsyncRequest(request) { (res: RustPB.Helpdesk_V1_GetHomePageOncallsResponse) -> [Oncall] in
            res.oncalls.map({ Oncall.transform(pb: $0) })
        }
    }
}
