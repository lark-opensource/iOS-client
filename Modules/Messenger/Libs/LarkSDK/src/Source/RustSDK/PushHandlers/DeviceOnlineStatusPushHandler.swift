//
//  DeviceOnlineStatusPushHandler.swift
//  LarkSDK
//
//  Created by 李勇 on 2019/4/18.
//

import Foundation
import RustPB
import LarkRustClient
import LarkSDKInterface

import LarkContainer
import RxSwift

final class DeviceOnlineStatusPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var authAPI: AuthAPI? { try? userResolver.resolve(assert: AuthAPI.self) }
    private let disposeBag = DisposeBag()

    func process(push message: RustPB.Device_V1_PushDeviceNotifySettingResponse) {
        self.authAPI?.fetchValidSessions().subscribe().disposed(by: self.disposeBag)
    }
}
