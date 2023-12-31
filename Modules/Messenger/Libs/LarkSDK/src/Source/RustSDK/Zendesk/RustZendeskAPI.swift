//
//  RustOncallAPI.swift
//  Lark
//
//  Created by maozhenning on 2019/05/07.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RustPB
import LarkSDKInterface

import LarkModel

final class RustZendeskAPI: LarkAPI, ZendeskAPI {

    func getGetLinkExtraData(link: String) -> Observable<Bool> {
        var request = GetLinkExtraDataRequest()
        request.link = link
        return client.sendAsyncRequest(request) { (res: RustPB.Basic_V1_GetLinkExtraDataResponse) -> (Bool) in
            if case .some(.zendeskLink) = res.extraData {
                return true
            }
            return false
        }.subscribeOn(scheduler)
    }

}
