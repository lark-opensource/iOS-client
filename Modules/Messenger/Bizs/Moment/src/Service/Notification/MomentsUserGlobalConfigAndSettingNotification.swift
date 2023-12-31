//
//  MomentsUserGlobalConfigAndSettingNotification.swift
//  Moment
//
//  Created by liluobin on 2021/5/16.
//

import Foundation
import RustPB
import RxSwift
import LarkRustClient

protocol MomentsUserGlobalConfigAndSettingNotification: AnyObject {
    var rxConfig: PublishSubject<RawData.UserGlobalConfigAndSettingsNof> { get }
}

final class MomentsUserGlobalConfigAndSettingNotificationHandler: MomentsUserGlobalConfigAndSettingNotification {
    let rxConfig: PublishSubject<RawData.UserGlobalConfigAndSettingsNof> = .init()
    init(client: RustService) {
        client.register(pushCmd: .momentsPushUserGlobalConfigAndSettingsLocalNotification) { [weak self] data in
            do {
                let rustBody = try RawData.UserGlobalConfigAndSettingsNof(serializedData: data)
                self?.rxConfig.onNext(rustBody)
            } catch {
                assertionFailure("serialize update noti payload failed")
            }
        }
    }
}
