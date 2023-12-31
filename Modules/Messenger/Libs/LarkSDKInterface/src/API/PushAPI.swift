//
//  PushAPI.swift
//  LarkSDKInterface
//
//  Created by mochangxing on 2019/11/5.
//

import Foundation
import RxSwift
import LarkModel
import RustPB

public protocol PushAPI {
    func updatePushToken(voipToken: String?, apnsToken: String?) -> Observable<Void>
}
