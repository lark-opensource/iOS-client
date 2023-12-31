//
//  GadgetNavigationProtocol.swift
//  OPGadget
//
//  Created by 刘洋 on 2021/4/19.
//

import Foundation
import UIKit

/// 使用小程序路由时，VC需要满足的一些协议
public protocol GadgetNavigationProtocol {

    /// 这个VC所在的导航栈只有它，而且它还在其他的Scene，VC将被路由到其他地方时，是否关闭这个Scene
    var isCloseOtherSceneWhenOnlyHasIt: Bool {get}

    /// 当存在模态视图，指定打开自己的方式
    /// - Parameter modalViewController: 当前路由找到的模态VC
    /// - Returns: 打开自己的样式
    func navigationStyle(in modalViewController: UIViewController) -> GadgetNavigationStyle

    /// 当存在模态视图时，模态弹出时这个VC的模态样式
    /// - Parameter targetViewController: 当前路由找到的模态VC
    /// - Returns: 模态打开的样式
    func modalStyleWhenPresented(from modalViewController: UIViewController) -> UIModalPresentationStyle

    /// 当模态视图中的导航控制器中的视图被替换为空白的占位符的时候，可以让这个VC来设置如何从空白页面恢复
    /// - Returns: 恢复行为，行为入参是空白页面
    func recoverBlankViewControllerActionOnPresented() -> ((_ blankViewController: UIViewController) -> ())?
    
    var openInTemporaryTab: Bool {get}
}
