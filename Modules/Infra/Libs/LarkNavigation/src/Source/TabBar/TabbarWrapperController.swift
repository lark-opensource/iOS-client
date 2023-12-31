//
//  TabbarWrapperController.swift
//  LarkNavigation
//
//  Created by 袁平 on 2022/5/31.
//

import UIKit

// UITabbarController调用setViewControllers时，当多于6个VC时，系统会默认把多余的VC加入到moreNavigation里，
// moreNavigation自身就是一个UINavigationController，不能再push一个节点是UINavigationController的导航栈
// 此时需要wrapper一层
public final class TabbarWrapperController: UIViewController {}
