//
//  AppMenuContext.swift
//  TTMicroApp
//
//  Created by 刘洋 on 2021/5/6.
//

import Foundation
import LarkUIKit

/// 小程序的菜单上下文
@objc
public final class AppMenuContext: NSObject, MenuContext {
    /// 小程序的容器
    @objc
    public private(set) weak var containerController: UIViewController?

    /// 小程序的uniqueID
    @objc
    public let uniqueID: OPAppUniqueID

    /// 使用小程序的容器和uniqueID初始化上下文
    @objc
    public init(uniqueID: OPAppUniqueID, containerController: BDPBaseContainerController?) {
        self.containerController = containerController
        self.uniqueID = uniqueID
        super.init()
    }
}
