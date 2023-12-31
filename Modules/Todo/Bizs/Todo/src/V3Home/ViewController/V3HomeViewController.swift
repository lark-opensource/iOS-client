//
//  V3HomeViewController.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/16.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkContainer
import TodoInterface

final class V3HomeViewController: BaseViewController, ModuleContextHolder, UserResolverWrapper {

    var userResolver: LarkContainer.UserResolver
    let context: V3HomeModuleContext
    let viewModel: V3HomeViewModel
    // list module
    let listModule: V3ListViewController
    // filter tab module
    let filterTab: FilterTabViewController
    // drawer module
    let drawerModule: FilterDrawerViewController
    // 侧边栏
    let sidebarModule: HomeSidebarViewController
    var sharePanel: V3ListSharePanel?

    // + 号大按钮
    lazy var bigAddButton: BigAddButton = BigAddButton()
    // loading view
    lazy var stateView: ListStateView = {
        return ListStateView(
            with: view,
            targetView: view,
            backgroundColor: UIColor.ud.bgBody
        )
    }()
    lazy var disposeBag = DisposeBag()
    lazy var fg = FeatureGating(resolver: userResolver)

    @ScopedInjectedLazy var settingService: SettingService?
    @ScopedInjectedLazy var routeDependency: RouteDependency?
    @ScopedInjectedLazy var messengerDependency: MessengerDependency?

    init(resolver: UserResolver, scene: HomeModuleScene = .center) {
        self.userResolver = resolver
        self.context = V3HomeModuleContext(state: .init(), scene: scene)
        self.viewModel = V3HomeViewModel(resolver: resolver, context: context)
        self.listModule = V3ListViewController(resolver: resolver, context: context)
        self.filterTab = FilterTabViewController(resolver: resolver, context: context)
        self.drawerModule = FilterDrawerViewController(resolver: resolver, context: context)
        self.sidebarModule = HomeSidebarViewController(resolver: resolver, context: context)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBasicView()
        viewModel.setup { [weak self] result in
            if case .succeed = result {
                self?.setupAfterData()
            }
        }
    }

    @objc
    func shareItemClick(_ btn: UIButton) {
        V3Home.logger.info("start share task list")
        let contianer = context.store.state.container
        V3Home.Track.shareTasklistInView(with: contianer)
        shareTaskList(with: contianer, sourceView: btn)
    }

    @objc
    func moreItemClick(_ btn: UIButton) {
        guard let contianer = context.store.state.container else { return }
        showTasklistMoreAction(data: .init(container: contianer), sourceView: btn, sourceVC: nil, scene: .listDetail)
    }
}
