//
//  SwitchUserStatus.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2020/2/14.
//

import Foundation

enum SwitchUserStatus {
    case switchUser([V4UserInfo])
    case cancel
    case switchStatusFail(Error)
}
