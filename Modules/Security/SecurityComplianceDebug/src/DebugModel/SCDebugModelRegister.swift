//
//  SCDebugModelRegister.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2022/9/24.
//

import UIKit
import LarkContainer

public protocol SCDebugModelRegister: UserResolverWrapper {
    init(resolver: UserResolver)

    func registModels()
}
