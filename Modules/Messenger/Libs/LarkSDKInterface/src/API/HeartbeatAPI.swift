//
//  HeartbeatAPI.swift
//  LarkSDKInterface
//
//  Created by lichen on 2018/10/18.
//

import Foundation
import LarkModel
import RxSwift
import RustPB

public protocol HeartbeatAPI {
    func start(token: String, type: RustPB.Videoconference_V1_StartByteviewHeartbeatRequest.ServiceType, cycle: Int32, expiredTime: Int32) -> Observable<Void>

    func stop(token: String, type: RustPB.Videoconference_V1_StartByteviewHeartbeatRequest.ServiceType) -> Observable<Void>
}
