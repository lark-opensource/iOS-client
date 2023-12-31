//
//  LarkInterface+URL.swift
//  LarkMessengerInterface
//
//  Created by 李晨 on 2019/12/18.
//

import Foundation
import RxSwift

public protocol LarkPushTokenUploaderService {
    func subscribeVoIPObservable(_ voIPObservable: Observable<String?>)
    func subscribeApnsObservable(_ apnsbservable: Observable<String?>)
    func subscribeTriggerUploadObservable(_ triggerObservable: Observable<Void>)
    func multiUserNotificationSwitchChange(_ isOn: Bool)
}

public protocol LarkBackgroundUserResetTokenService {
    func backgroundUserWillOffline(userId: String, completion: @escaping (() -> Void))
}

public protocol LarkCouldPushUserListService {
    func uploadCouldPushUserList(_ activityUserIDList: [String])
}
