//
//  DemoVC.swift
//  SCDemo
//
//  Created by qingchun on 2022/9/14.
//

import UIKit
import RxSwift
import RxCocoa
import AnimatedTabBar
import LarkNavigation
import LarkTab
import LarkUIKit
import LarkAccountInterface
import LarkContainer

class DemoVC: UIViewController, TabRootViewController, LarkNaviBarDataSource, LarkNaviBarDelegate {

    var titleText: BehaviorRelay<String> {
        if let service = implicitResolver?.resolve(PassportService.self), let name = service.foregroundUser?.name {
            return BehaviorRelay(value: name)
        }
        return BehaviorRelay(value: "安全合规")
    }

    var isNaviBarEnabled: Bool { true }

    var isDrawerEnabled: Bool { true }

    var tab: Tab { DemoTab.tab }

    var controller: UIViewController { self }

    lazy var container = try? Container(userResolver: self.userResolver, frame: UIScreen.main.bounds) ?? UIView()
    let userResolver: UserResolver

    override func loadView() {
        view = container
    }

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}
