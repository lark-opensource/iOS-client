//
//  RustAuthModule.swift
//  Lark
//
//  Created by Sylar on 2017/10/30.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RustPB
import LarkModel
import LarkSDKInterface
import LKCommonsLogging
import LarkAccountInterface

final class RustAuthModule {

    static let logger = Logger.log(RustAuthModule.self, category: "RustSDK.Auth")
    static var log = RustAuthModule.logger

    class func fetchValidSessions(client: SDKRustService) -> Observable<[RustPB.Basic_V1_Device]> {
        let request = RustPB.Device_V1_GetValidDevicesRequest()
        return client.sendAsyncRequest(request) { (response: GetValidDevicesResponse) -> [RustPB.Basic_V1_Device] in
            return response.devices
        }
    }

    class func forceSessionInvalid(identifier: SessionIdentifier, client: SDKRustService) -> Observable<Bool> {
        var request = RustPB.Device_V1_LogoutDeviceRequest()
        request.deviceID = identifier
        let observable: Observable<RustPB.Device_V1_LogoutDeviceResponse>
        observable = client.sendAsyncRequest(request)
        return observable.map({ (res) -> Bool in
            return res.isSuccess
        })
    }

    class func logout(client: SDKRustService) -> Observable<Void> {
        let request = RustPB.Tool_V1_MakeUserOfflineRequest()
        return client.sendAsyncRequest(request)
    }

    class func updateDeviceInfo(deviceInfo: RustPB.Basic_V1_Device, client: SDKRustService) -> Observable<Void> {
        guard !deviceInfo.name.isEmpty, !deviceInfo.model.isEmpty, !deviceInfo.os.isEmpty else {
            return Observable.just(())
        }
        var request = RustPB.Device_V1_UpdateDeviceRequest()
        request.name = deviceInfo.name
        request.model = deviceInfo.model
        request.os = deviceInfo.os
        return client.sendAsyncRequest(request)
    }

    class func setReqIdSuffix(_ suffix: String, client: SDKRustService) -> Observable<Void> {
        var request = RustPB.Basic_V1_SetReqIdSuffixRequest()
        request.suffix = suffix
        return client.sendAsyncRequest(request)
    }
}
