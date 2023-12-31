//
//  MinimumModeAPI.swift
//  LarkMinimumMode
//
//  Created by zc09v on 2021/5/7.
//

import Foundation
import LarkRustClient
import RxSwift
import ServerPB

protocol MinimumModeAPI {
    func putDeviceMinimumMode(_ inMinimumMode: Bool) -> Observable<Void>
    func pullDeviceMinimumMode() -> Observable<Bool>
}

final class MinimumModeAPIImpl: MinimumModeAPI {
    private let client: RustService
    init(client: RustService) {
        self.client = client
    }

    func putDeviceMinimumMode(_ inMinimumMode: Bool) -> Observable<Void> {
        var request = ServerPB_Device_PutDeviceBasicModeSettingRequest()
        request.basicModeStatus = inMinimumMode
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .putDeviceBasicModeSetting)
    }

    func pullDeviceMinimumMode() -> Observable<Bool> {
        let request = ServerPB_Device_PullDeviceBasicModeSettingRequest()
        let ob: Observable<ServerPB_Device_PullDeviceBasicModeSettingResponse> = self.client.sendPassThroughAsyncRequest(request, serCommand: .pullDeviceBasicModeSetting)
        return ob.map { (res) -> Bool in
            return res.basicModeStatus
        }
    }
}
