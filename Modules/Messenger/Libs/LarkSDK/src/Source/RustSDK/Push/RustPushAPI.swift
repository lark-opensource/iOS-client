//
//  RustPushAPI.swift
//  LarkSDK
//
//  Created by mochangxing on 2019/11/5.
//

import Foundation
import LarkSDKInterface
import RxSwift
import RustPB
import LarkReleaseConfig

final class RustPushAPI: LarkAPI, PushAPI {

    func updatePushToken(voipToken: String?, apnsToken: String?) -> Observable<Void> {
        var request = RustPB.Device_V1_SetPushTokenRequest()
        if let voipToken = voipToken {
            request.voipToken = voipToken
        }
        if let apnsToken = apnsToken {
            request.apnsToken = apnsToken
        }
        request.channel = ReleaseConfig.pushChannel
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }
}
