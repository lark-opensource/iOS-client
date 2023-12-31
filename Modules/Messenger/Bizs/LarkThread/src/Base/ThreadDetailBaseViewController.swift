//
//  ThreadDetailBaseViewController.swift
//  LarkThread
//
//  Created by liluobin on 2021/6/8.
//

import UIKit
import Foundation
import LarkUIKit
import Lottie
import LarkFeatureGating
import LarkContainer
import LarkMessengerInterface
import LarkMessageCore

class ThreadDetailBaseViewController: BaseUIViewController, UserResolverWrapper {
    /// 保持当前tableView的offset不变 不再受键盘frame的影响
    var lockTableOffset = false

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @ScopedInjectedLazy var alertService: PostMessageErrorAlertService?
    /// 自定义导航栏
    let rightView = UIButton()

    lazy var navBar: TitleNaviBar = {
        let navBar = TitleNaviBar(titleString: "")
        return navBar
    }()

    lazy var threadTitleView: ThreadDetailTitleView = {
        let titleView = ThreadDetailTitleView()
        return titleView
    }()

    lazy var copyOptimizeFG: Bool = {
        return (try? userResolver.fg)?.staticFeatureGatingValue(with: .init(key: .groupMobileCopyOptimize)) ?? false
    }()

    lazy var forwardBarButton: UIButton = {
        let forwardButton = UIButton()
        forwardButton.setImage(Resources.thread_foward.withRenderingMode(.alwaysTemplate), for: .normal)
        forwardButton.addTarget(self, action: #selector(forwardButtonTapped(sender:)), for: .touchUpInside)
        forwardButton.tintColor = UIColor.ud.iconN1
        forwardButton.addPointerStyle()
        return forwardButton
    }()

    lazy var cancelMutilButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.LarkThread.Lark_Legacy_Cancel, for: .normal)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(cancelMutilButtonTapped(sender:)), for: .touchUpInside)
        button.addPointerStyle()
        return button
    }()

    /// 切换scene
    lazy var sceneButton: UIButton = {
        let button = UIButton()
        button.setImage(Resources.scene_icon.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        button.addTarget(self, action: #selector(clickSceneButton(sender:)), for: .touchUpInside)
        button.addPointerStyle()
        return button
    }()

    var multiSelecting = false {
        didSet {
            multiSelectingValueUpdate()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    /// 当前是否在多选的状态更新了
    func multiSelectingValueUpdate() {
        assertionFailure("子类需要重写")
    }

    @objc
    func clickSceneButton(sender: UIButton) {
    }

    @objc
    func cancelMutilButtonTapped(sender: UIButton) {
    }

    @objc
    func forwardButtonTapped(sender: UIButton) {
    }
}
