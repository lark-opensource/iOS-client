//
//  BitableInterface.swift
//  SKCommon
//
//  Created by ByteDance on 2023/11/15.
//

import UIKit
import LarkContainer
import SpaceInterface

// 用于 SKBitable 中创建 符合业务要求的SpaceHomeViewController
public protocol BitableVCFactoryProtocol  {
    var userResolver: UserResolver { get }
    
    init(userResolver: UserResolver)
    
    func makeBitableMultiListController(context: BaseHomeContext) -> BitableMultiListControllerProtocol?
}

