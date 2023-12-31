//
//  SettingViewController.swift
//  Todo
//
//  Created by 白言韬 on 2021/2/22.
//

import Foundation
import LarkContainer
import LarkUIKit

class SettingViewController: BaseViewController, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    private lazy var rootView = UIScrollView()
    // module container
    private lazy var containerView = ModuleContainerView()
    // modules
    private var modules = [SettingBaseModule]()

    @ScopedInjectedLazy private var settingService: SettingService?

    private lazy var containerContext: SettingModuleContainerContext = {
        let context = SettingModuleContainerContext()
        context.viewController = self
        context.containerView = self.containerView
        return context
    }()

    init(resolver: UserResolver) {
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
        settingService?.forceFetchData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = I18N.Todo_Task_Tasks
        Setting.Track.viewSetting()
        setupView()
        setupModule()
    }

    private func setupView() {
        rootView.showsVerticalScrollIndicator = false
        rootView.contentInsetAdjustmentBehavior = .never
        rootView.alwaysBounceVertical = true
        rootView.backgroundColor = UIColor.ud.bgFloatBase

        view.addSubview(rootView)
        rootView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        containerView.stackView.snp.remakeConstraints {
            $0.edges.equalToSuperview()
        }

        rootView.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.edges.centerX.equalToSuperview()
        }
    }

    private func setupModule() {
        let badgeModule = SettingBadgeModule(resolver: userResolver)
        let defaultReminderModule = SettingDefaultReminderModule(resolver: userResolver)
        modules = [badgeModule, defaultReminderModule]

        var groupList = [ModuleGroup]()
        let todoTaskReminderModule = SettingTodoTaskReminderModule(resolver: userResolver)
        modules.append(todoTaskReminderModule)
        groupList.append(ModuleGroup(items: [todoTaskReminderModule], topMargin: .init(height: 16)))
        groupList.append(ModuleGroup(items: [badgeModule], topMargin: .init(height: 16)))
        groupList.append(ModuleGroup(items: [defaultReminderModule], topMargin: .init(height: 16)))

        containerView.groups = groupList
        view.setNeedsLayout()

        for module in modules {
            module.containerContext = containerContext
            module.setup()
        }
    }

}
