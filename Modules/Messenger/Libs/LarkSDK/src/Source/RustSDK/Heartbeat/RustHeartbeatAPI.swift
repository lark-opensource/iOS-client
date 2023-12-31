//
//  RustHeartbeatAPI.swift
//  LarkSDK
//
//  Created by lichen on 2018/10/18.
//

import Foundation
import RxSwift
import LarkModel
import RustPB
import LarkSDKInterface

final class RustHeartbeatAPI: LarkAPI, HeartbeatAPI {
    func start(token: String, type: RustPB.Videoconference_V1_StartByteviewHeartbeatRequest.ServiceType, cycle: Int32, expiredTime: Int32) -> Observable<Void> {
        var request = RustPB.Videoconference_V1_StartByteviewHeartbeatRequest()
        request.token = token
        request.serviceType = type
        request.cycle = cycle
        request.expiredTime = expiredTime
        return self.client.sendAsyncRequest(request, transform: { (_: RustPB.Videoconference_V1_StartByteviewHeartbeatResponse) -> Void in
            return ()
        }).subscribeOn(scheduler)
    }

    func stop(token: String, type: RustPB.Videoconference_V1_StartByteviewHeartbeatRequest.ServiceType) -> Observable<Void> {
        var request = RustPB.Videoconference_V1_StopByteviewHeartbeatRequest()
        request.token = token
        request.serviceType = type
        return self.client.sendAsyncRequest(request, transform: { (_: RustPB.Videoconference_V1_StopByteviewHeartbeatResponse) -> Void in
            return ()
        }).subscribeOn(scheduler)
    }

}
