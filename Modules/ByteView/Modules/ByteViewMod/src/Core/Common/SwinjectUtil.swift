//
//  SwinjectUtil.swift
//  ByteViewMod
//
//  Created by kiri on 2022/3/3.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkContainer
import EENavigator
import LarkAccountInterface
import ByteViewCommon
import LarkNavigator

extension UserSpaceScope {
    static let vcUser = UserLifeScope.userV2
}

extension Navigator {
    static var currentUserNavigator: Navigatable {
        Container.shared.getCurrentUserResolver().navigator
    }
}
