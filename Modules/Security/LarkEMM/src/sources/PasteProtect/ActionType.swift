//
//  ActionType.swift
//  LarkEMM
//
//  Created by ByteDance on 2023/10/24.
//

import Foundation

@objc
public enum SCResponderActionType: Int {
    case performOriginActionAllow = 0
    case performActionAllow
    case performActionForbid
}
