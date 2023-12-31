//
//  CalendarNavigatorAssembly.swift
//  Calendar
//
//  Created by zhuheng on 2021/3/5.
//

import UIKit
import Swinject
import LarkContainer
import AnimatedTabBar
import EENavigator
import LarkRustClient
import RxSwift
import RxCocoa
import LarkTab
import LarkNavigation
import LarkUIKit
import UniverseDesignToast
import UniverseDesignIcon

final class CalendarErrorViewController: BaseUIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        isNavigationBarHidden = true
        title = I18n.Calendar_NewSettings_Calendar
        let errorView = EmptyDataView(content: I18n.Calendar_Sync_FailedToRedirect, placeholderImage: Resources.load_fail)

        view.addSubview(errorView)
        errorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let btn = UIButton.cd.button(type: .custom)
        let backImage = UDIcon.getIconByKeyNoLimitSize(.leftOutlined).scaleNaviSize().renderColor(with: .n1)

        view.addSubview(btn)
        btn.setImage(backImage, for: .normal)
        btn.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        let isFullScreen = modalPresentationStyle == .fullScreen || (modalPresentationStyle == .pageSheet && Display.phone)
        let statusBarHeight = isFullScreen ? UIApplication.shared.statusBarFrame.height : 0
        btn.snp.makeConstraints { (make) in
            make.width.height.equalTo(24).priority(.high)
            make.left.equalToSuperview().offset(16)
            make.centerY.equalTo(view.snp.top).offset(statusBarHeight + 22)
        }
    }

    @objc
    private func backButtonPressed() {
        guard let naviVC = navigationController else {
            dismiss(animated: true, completion: nil)
            return
        }
        if naviVC.viewControllers.count > 1 {
            naviVC.popViewController(animated: true)
        } else {
            naviVC.dismiss(animated: true, completion: nil)
        }
    }
}
