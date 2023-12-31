//
//  LKSplitViewController.swift
//  LarkUIKit
//
//  Created by lixiaorui on 2019/8/14.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignEmpty
import LarkUIKit

public typealias LKSplitViewController2 = SplitViewController
extension SplitViewController {

    public static func defaultDetailController() -> UIViewController {
        return UIViewController.DefaultDetailController()
    }

    public class func makeDefaultDetailVC() -> UIViewController {
        return LkNavigationController(rootViewController: DefaultDetailController())
    }
}

extension UIViewController {
    public final class DefaultDetailController: BaseUIViewController, DefaultDetailVC {
        public override func viewDidLoad() {
            super.viewDidLoad()
            self.isNavigationBarHidden = true
            self.view.backgroundColor = UIColor.ud.bgBase
            var emptyText = ""
            if Display.pad {
                emptyText = BundleI18n.LarkSplitViewController.Lark_Onboard_WelcomeToFeishu()
            }
            let emptyView = UDEmpty(config: UDEmptyConfig(title: nil,
                                                            description: UDEmptyConfig.Description(
                                                                descriptionText: emptyText,
                                                                font: UIFont.systemFont(ofSize: 14)),
                                                            spaceBelowImage: 10,
                                                            spaceBelowTitle: 0,
                                                            spaceBelowDescription: 0,
                                                            spaceBetweenButtons: 0,
                                                            type: .defaultPage))
            emptyView.sizeToFit()
            self.view.addSubview(emptyView)
            emptyView.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
            }
        }
    }
}
