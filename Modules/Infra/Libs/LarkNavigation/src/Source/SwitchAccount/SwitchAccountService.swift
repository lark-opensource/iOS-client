//
//  SwitchAccountService.swift
//  LarkAccountInterface
//
//  Created by CharlieSu on 1/2/20.
//

import Foundation
import RxCocoa
import LarkAccountInterface

/// [tenant.chatter.id : Int32]
public typealias AccountsBadges = [String: Int32]

public protocol SwitchAccountService: AnyObject {
    // 租户Badge
    var accountsBadgesDriver: Driver<AccountsBadges> { get }
    // 获取所有租户Badge
    func fetcAccountsBadge()
    // 更新push来的租户的Badge
    func updateAccountBadge(with badgesMap: AccountsBadges)
}
