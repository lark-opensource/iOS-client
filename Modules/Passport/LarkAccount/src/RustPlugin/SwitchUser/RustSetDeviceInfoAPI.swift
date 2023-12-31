//
//  RustSetDeviceInfoAPI.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/10.
//

import Foundation
import RxSwift
import LarkFoundation
import LarkRustClient
import LarkUIKit
import LKCommonsLogging
import LarkContainer
import RustPB
import LarkReleaseConfig

typealias SetDeviceRequest = RustPB.Device_V1_SetDeviceRequest

class RustSetDeviceInfoAPI: SetDeviceInfoAPI {

    static let logger = Logger.plog(RustSetDeviceInfoAPI.self, category: "SuiteLogin.RustSetDeviceInfoAPI")

    @Provider var client: GlobalRustService

    func setDeviceInfo(deviceId: String, installId: String) -> Observable<Void> {
        var request = SetDeviceRequest()
        request.deviceID = deviceId
        request.installID = installId
        // TNC need specifical devicePlatform and appName.
        // https://bytedance.feishu.cn/docs/doccnwt9lOhqwtU0XsU0vNpJA5c#
        request.appName = Utils.appName
        request.devicePlatform = Display.pad ? "iPad" : "iPhone"
        let osVersion = UIDevice.current.systemVersion
        let deviceType = LarkFoundation.Utils.machineType
        request.osVersion = osVersion
        request.deviceType = deviceType
        request.settingsQueries = ["device_model": deviceType, "app_channel": ReleaseConfig.releaseChannel]
        Self.logger.info("r_action_set_did", additionalData: ["deviceID": deviceId, "installID": installId, "osVersion": osVersion, "deviceType": deviceType, "appName": request.appName, "devicePlatform": request.devicePlatform])
//        Self.logger.info("SetDeviceRequest deviceId: \(deviceId), installId: \(installId), osVersion: \(osVersion), deviceType: \(deviceType), appName: \(request.appName), devicePlatform: \(request.devicePlatform).")
        return client.sendAsyncRequestBarrier(request)
            .trace("RustSetDeviceInfo", params: [
                "deviceId": deviceId,
                "installId": installId,
                "osVersion": osVersion,
                "deviceType": deviceType
            ])
    }
}
