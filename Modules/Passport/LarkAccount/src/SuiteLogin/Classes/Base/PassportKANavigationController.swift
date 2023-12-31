//
//  PassportKANavigationController.swift
//  LarkLogin
//
//  Created by au on 1/9/19.
//

import LarkUIKit

class PassportKANavigationController: LkNavigationController {

    override public func viewDidLoad() {
        super.viewDidLoad()
        // 订阅状态栏点击事件，导出日志分享页面
        FetchClientLogHelper.subscribeStatusBarInteraction()
    }

}
