//
//  ContactInviteInfoService.swift
//  LarkMessengerInterface
//
//  Created by ByteDance on 2022/12/7.
//

import Foundation

/// 邀请服务
public protocol ContactInviteInfoService {

    func fetchInviteInfo()

    func fetchTenantCreateGuide()

    func setAvatarObserver()

    func trackPushNotificationStatus()
}
