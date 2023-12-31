//
//  BootManager.swift
//  MailSDK
//
//  Created by tefeng liu on 2022/3/22.
//  注意：！！ 因为不是高频使用场景，为了效率，这里的属性和方法都没有加锁
//

import Foundation
import RustPB
import LarkContainer

protocol BootObserver {
    func beforeInitMail()
    func didLoadSetting(_ setting: Email_Client_V1_Setting)
}

public final class MailBootManager {
    let homePreloader: MailHomePreloader

    var observers: [BootObserver] {
        return [homePreloader]
    }

    init(resolver: UserResolver) {
        self.homePreloader = MailHomePreloader(resolver: resolver)
    }
}

// MARK: time line
extension MailBootManager {
    public func handleBeforeInitMail() {
        for obj in observers {
            obj.beforeInitMail()
        }
    }

    public func handleSetting(_ setting: Email_Client_V1_Setting) {
        for obj in observers {
            obj.didLoadSetting(setting)
        }
    }
}
