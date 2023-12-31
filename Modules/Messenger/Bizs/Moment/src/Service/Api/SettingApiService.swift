//
//  SettingApiService.swift
//  Moment
//
//  Created by zc09v on 2021/6/15.
//
import Foundation
import RxSwift
import RustPB

protocol SettingApiService {
    func setRedDotNotify(enable: Bool) -> Observable<Void>
}

extension RustApiService: SettingApiService {
    func setRedDotNotify(enable: Bool) -> Observable<Void> {
        var request: Moments_V1_PatchUserSettingRequest = Moments_V1_PatchUserSettingRequest()
        request.updateFields = [.muteRedDotNotify]
        var userSetting = Moments_V1_UserSetting()
        userSetting.muteRedDotNotify = !enable
        request.userSetting = userSetting
        return client.sendAsyncRequest(request).map { (_) -> Void in
            return
        }
    }
}
