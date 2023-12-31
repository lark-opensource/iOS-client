//
//  LaunchGuideViewController.swift
//  LKLaunchGuide
//
//  Created by Meng on 2020/9/14.
//

import Foundation
import UIKit
import LKCommonsTracker
import LarkAccountInterface

final class LaunchGuideViewController: UIViewController {

    private let launchGuideView: UIView

    init(launchGuideView: UIView) {
        self.launchGuideView = launchGuideView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

//    deinit {
//        launchGuideView.viewShouldRemove()
//    }

    override func loadView() {
        view = launchGuideView
        /// 新埋点，页面出现事件
        CommonsTracker.post(TeaEvent(
            "passport_landing_page_view",
            params: ["passport_appid": LarkAppID.lark,
                     "tracking_code": "none",
                     "template_id": "none",
                     "utm_from": "none"]
        ))
    }

    override var shouldAutorotate: Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        } else {
            return false
        }
    }
}
