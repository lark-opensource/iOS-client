//
//  V3HomeViewController+Setup.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/25.
//

import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import UniverseDesignIcon
import UniverseDesignFont

// MARK: - Setup

extension V3HomeViewController {

    func setupAfterData() {
        setupModule()
        setupView()
        bindBusEvent()
    }

    func setupBasicView() {
        // 如果在一级页面比如home，则需要隐藏NavigationBar；其他需要显示
        isNavigationBarHidden = navigationController?.viewControllers.count ?? 0 <= 1
        view.backgroundColor = UIColor.ud.bgBody
        // view State
        viewModel.rxViewState.distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self] element in
                    guard let self = self else { return }
                    self.resetViews(by: element)
                })
            .disposed(by: disposeBag)
        viewModel.rxAddOverflow.distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self] key in
                    guard let self = self else { return }
                    switch key {
                    case .activity:
                        self.tryRemoveOverflowVC(exception: ListActivityRecordsViewController.self)
                        self.addActivity()
                    case .taskLists:
                        self.tryRemoveOverflowVC(exception: OrganizableTasklistViewController.self)
                        self.addOrganizableTasklist()
                    case .none:
                        self.tryRemoveOverflowVC()
                    }
                })
            .disposed(by: disposeBag)
        stateView.retryHandler = { [weak self] in
            self?.context.bus.post(.refetchAllTask)
        }
    }

    func resetViews(by element: V3HomeViewModel.HomeViewElement) {
        let backItem = addBackItem()
        if let title = element.title, !title.isEmpty {
            let titleItem = UIBarButtonItem(customView: {
                let label = UILabel()
                label.text = title
                label.font = UDFont.systemFont(ofSize: 17, weight: .medium)
                label.textColor = UIColor.ud.textTitle
                return label
            }())
            DispatchQueue.main.async { [weak self] in
                self?.navigationItem.leftBarButtonItems = [backItem, titleItem]
            }
        } else {
            navigationItem.leftBarButtonItems = [backItem]
        }
        bigAddButton.isHidden = !element.showBigBtn

        if case .failed(let state) = element.viewState, case .noAuth = state {
            let applyPermission = V3ListApplyPermissionView(resolver: userResolver, container: context.store.state.container ?? .init())
            applyPermission.controller = self
            view.addSubview(applyPermission)
            applyPermission.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            if let subView = view.subviews.first(where: { $0.isKind(of: V3ListApplyPermissionView.self) }) {
                subView.removeFromSuperview()
            }

            var failedText = I18N.Lark_Legacy_LoadFailedRetryTip
            if case .failed(let state) = element.viewState {
                switch state {
                case .deleted: failedText = I18N.Todo_ListCard_ListHasBeenDeleted_Empty
                default: break
                }
            }
            stateView.updateViewState(
                state: element.viewState,
                loadingText: I18N.Todo_DataLoadingNowPleaseWait_Text,
                failedText: failedText
            )
        }

        if case .data = element.viewState {
            let shareItem = LKBarButtonItem(image: UDIcon.shareOutlined.ud.withTintColor(UIColor.ud.N800), buttonType: .custom)
            shareItem.button.addTarget(self, action: #selector(shareItemClick(_:)), for: .touchUpInside)
            let moreItem = LKBarButtonItem(image: UDIcon.moreOutlined.ud.withTintColor(UIColor.ud.iconN1), buttonType: .custom)
            moreItem.button.addTarget(self, action: #selector(moreItemClick(_:)), for: .touchUpInside)
            navigationItem.rightBarButtonItems = [moreItem, LKBarSpaceItem(width: 2), shareItem]
        } else {
            navigationItem.rightBarButtonItems = nil
        }
    }

    func setupView() {
        bigAddButton.isHidden = true
        view.addSubview(bigAddButton)
        bigAddButton.rx.controlEvent(.touchUpInside)
            .bind { [weak self] _ in self?.handleBigAdd() }
            .disposed(by: disposeBag)
        bigAddButton.snp.makeConstraints { make in
            make.width.height.equalTo(48)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
        }
        registerDrawer()
    }

    func setupModule() {
        // filter tab
        addChild(filterTab)
        view.addSubview(filterTab.view)
        filterTab.view.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            if isNavigationBarHidden {
                make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).offset(Utils.UI.naviBarHeight)
            } else {
                make.top.equalToSuperview()
            }
        }
        filterTab.didMove(toParent: self)

        // list
        addChild(listModule)
        view.addSubview(listModule.view)
        listModule.view.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(filterTab.view.snp.bottom)
        }
        listModule.didMove(toParent: self)
    }

    func bindBusEvent() {
        context.bus.subscribe { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .showFilterDrawer(let sourceView):
                self.shwoFilterDrawer(sourceView: sourceView)
            case .showDetail(let guid, let needLoading, let callbacks):
                self.showDetail(with: guid, needLoading: needLoading, callbacks: callbacks)
            case .closeDetail(let guid):
                self.closeDetail(for: guid)
            case .createTodo(let param):
                self.createTodo(.inline(param: param))
            case .refetchAllTask:
                self.viewModel.retryFetch()
            case .tasklistMoreAction(let data, let sourceView, let sourceVC, let scene):
                self.showTasklistMoreAction(
                    data: data,
                    sourceView: sourceView,
                    sourceVC: sourceVC,
                    scene: scene
                )
            case .unarchivedTasklist(let container):
                self.doUnarchiveTasklist(container: container, sourceVC: nil)
            case .createTasklist(let section, let from, let callback, let completion):
                self.showCreateTaskList(section: section, from: from, callback: callback, completion: completion)
            case .organizableTasklistMoreAction(let sourceView):
                self.showOrganizableActionSheet(sourceView: sourceView)
            default: break
            }
        }.disposed(by: disposeBag)
    }

    private func addActivity() {
        let viewModel = ListActivityRecordsViewModel(resolver: userResolver, scene: .user)
        let viewController = ListActivityRecordsViewController(resolver: userResolver, viewModel: viewModel)
        layoutOverflowVC(from: viewController)
    }

    private func addOrganizableTasklist() {
        guard !children.contains(where: { $0.isKind(of: OrganizableTasklistViewController.self)}) else {
            return
        }
        let viewModel = OrganizableTasklistViewModel(resolver: userResolver, context: context)
        let vc = OrganizableTasklistViewController(resolver: userResolver, viewModel: viewModel)
        layoutOverflowVC(from: vc)
    }

    private func layoutOverflowVC(from viewController: BaseViewController) {
        // 必须隐藏掉，不然布局有问题
        viewController.isNavigationBarHidden = true
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(filterTab.view.snp.bottom)
        }
        viewController.didMove(toParent: self)
    }

    private func tryRemoveOverflowVC(exception: BaseViewController.Type? = nil) {
        var overflowVCTypes = [OrganizableTasklistViewController.self, ListActivityRecordsViewController.self]
        if let exception = exception {
            overflowVCTypes.removeAll(where: { $0 == exception })
        }
        overflowVCTypes.forEach { vcType in
            if let vc = children.first(where: { $0.isKind(of: vcType) }) {
                vc.willMove(toParent: nil)
                vc.view.removeFromSuperview()
                vc.removeFromParent()
            }
        }
    }
}
