//
//  RustLogAPIImpl.swift
//  Pods
//
//  Created by lichen on 2018/10/10.
//

import Foundation
import RxSwift
import RustPB
import LarkModel
import LarkSDKInterface

final class RustLogAPIImpl: LarkAPI, RustLogAPI {
    func log(level: RustPB.Tool_V1_SetLogBySDKRequest.Level, tag: String, message: String, extra: [String: String]) -> Observable<Void> {
        var request = RustPB.Tool_V1_SetLogBySDKRequest()
        request.level = level
        request.tag = tag
        request.message = message
        request.extra = extra
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
    }
}
