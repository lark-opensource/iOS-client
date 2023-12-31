//
//  SpaceFolderContainerController.swift
//  SKECM
//
//  Created by Weston Wu on 2021/3/15.
//

import Foundation
import SKUIKit
import SKFoundation
import SKCommon
import SnapKit
import RxSwift
import RxRelay
import RxCocoa
import EENavigator
import LarkUIKit
import UniverseDesignColor
import SKResource
import UniverseDesignToast
import UIKit
import SpaceInterface
import LarkContainer

private extension SpaceFolderContainerController {

    enum State {
        // 无权限
        case noPermission(permissionView: PermissionView, permissionBag: DisposeBag)
        // 需要密码
        case requirePassword(passwordViewController: PasswordInputViewController, passwordBag: DisposeBag)
        // 正常展示
        case normal
    }
}

extension SpaceFolderContainerController {

    enum ApplyPermissionState {
        case allow(ownerName: String)
        case disallow
    }

    enum StateChange {
        // 是否允许申请权限，和申请权限按钮的回调，附带备注信息
        case noPermission(canApply: ApplyPermissionState, folderType: FolderType?, handler: (String?, Int) -> Void)
        case requirePassword(folderToken: String, folderType: FolderType?, handler: (Bool) -> Void)
        case displayContent
    }

    enum Action {
        case present(viewController: UIViewController, popoverConfiguration: ((UIViewController) -> Void)?)
        case getHostController(action: (UIViewController) -> Void)
        case showHUD(_ action: HUDAction)
        case hideHUD
        // dismiss or pop containerVC
        case exit

        enum HUDAction {
            case loading
            case failure(_ content: String)
            case success(_ content: String)
            case tips(_ content: String)
            @available(*, deprecated, message: "use custom instead")
            case tipsmanualOffline(text: String, buttonText: String)
        }
    }
}

// 通过该协议将spaceHomeViewController与文件夹容器VC解耦
public protocol SpaceFolderContentViewController: UIViewController {
    var contentNaviBarCoordinator: SpaceNaviBarCoordinator? { get }
    func reloadHomeLayout()
}

// 带有导航栏和搜索栏的容器VC，提供给文件夹列表使用
class SpaceFolderContainerController: BaseViewController, UIViewControllerTransitioningDelegate, CustomNaviAnimation {

    private let bag = DisposeBag()

    private var state: State = .normal
    private let contentViewController: SpaceFolderContentViewController
    private let viewModel: SpaceFolderContainerViewModel
    private let userResolver: UserResolver

    override var commonTrackParams: [String: String] {
        [
            "module": viewModel.bizParams.params["module"] ?? "null",
            "sub_module": viewModel.bizParams.params["sub_module"] ?? "none"
        ]
    }

    init(userResolver: UserResolver,
         contentViewController: SpaceFolderContentViewController,
         viewModel: SpaceFolderContainerViewModel) {
        self.contentViewController = contentViewController
        self.viewModel = viewModel
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        contentViewController.contentNaviBarCoordinator?.update(naviBarProvider: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupVM()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DocsTracker.reportSpaceFolderView(isShareFolder: viewModel.bizParams.isShareFolder, bizParms: viewModel.bizParams)
        viewModel.viewDidAppear()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentViewController.reloadHomeLayout()
    }

    private func setupUI() {
        supportSecondaryOnly = true
        supportSecondaryPanGesture = true
        keyCommandToFullScreen = true
        
        view.backgroundColor = UDColor.bgBody
        navigationController?.isNavigationBarHidden = true

        addChild(contentViewController)
        view.addSubview(contentViewController.view)
        contentViewController.didMove(toParent: self)

        contentViewController.view.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        navigationBar.layoutAttributes.titleHorizontalAlignment = SKDisplay.pad ? .leading : .center
    }

    private func setupVM() {
        viewModel.actionSignal
            .emit(onNext: { [weak self] action in
                self?.handle(containerAction: action)
            })
            .disposed(by: bag)

        viewModel.titleUpdated
            .drive(onNext: { [weak self] title, isExternal, showSecondTag in
                self?.navigationBar.title = title
                self?.navigationBar.titleView.needDisPlayTag = isExternal
                self?.navigationBar.titleView.tagContent = self?.viewModel.organizationTagValue
                self?.navigationBar.titleView.showSecondTag = showSecondTag
            })
            .disposed(by: bag)

        viewModel.stageChanged
            .drive(onNext: { [weak self] stageChange in
                self?.handle(stageChange: stageChange)
            })
            .disposed(by: bag)
        viewModel.setup()
    }

    private func handle(containerAction: Action) {
        switch containerAction {
        case let .present(viewController, popoverConfiguration):
            if SKDisplay.pad, isMyWindowRegularSize() {
                popoverConfiguration?(viewController)
            }
            userResolver.navigator.present(viewController, from: self)
        case let .showHUD(action):
            let viewForHUD: UIView = view.window ?? view
            switch action {
            case .loading:
                UDToast.showDefaultLoading(on: viewForHUD)
            case let .failure(content):
                UDToast.showFailure(with: content, on: viewForHUD)
            case let .success(content):
                UDToast.showSuccess(with: content, on: viewForHUD, delay: 2)
            case let .tips(content):
                UDToast.showTips(with: content, on: viewForHUD)
            case let .tipsmanualOffline(text, buttonText):
                let opeartion = UDToastOperationConfig(text: buttonText, displayType: .horizontal)
                let config = UDToastConfig(toastType: .info, text: text, operation: opeartion)
                UDToast.showToast(with: config, on: view, delay: 2, operationCallBack: { [weak self] _ in
                    guard let self = self else { return }
                    NetworkFlowHelper.dataTrafficFlag = true
                    UDToast.removeToast(on: self.view)
                    })
            }
        case .hideHUD:
            UDToast.removeToast(on: view.window ?? view)
        case let .getHostController(action):
            action(self)
        case .exit:
            // 参考 BaseViewController 的 back 方法实现
            if let navigationController = navigationController {
                navigationController.popViewController(animated: true)
                if self.presentingViewController != nil {
                    dismiss(animated: true, completion: nil)
                }
            } else {
                dismiss(animated: true, completion: nil)
            }
        }
    }

    // MARK: - Search Bar Transition  UIViewControllerTransitioningDelegate, CustomNaviAnimation {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        rawAnimationController(forPresented: presented, presenting: presenting, source: source)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        rawAnimationController(forDismissed: dismissed)
    }
}

// State Transition
private extension SpaceFolderContainerController {
    private func handle(stageChange: StateChange) {
        switch (state, stageChange) {
        // noPermission -> newState
        case let (.noPermission(permissionView, _), .noPermission(canApply, _, requestHandler)):
            DocsLogger.info("folder.container.vc --- stage change", extraInfo: ["from": "noPermission", "to": "noPermission"])

            update(permissionView: permissionView, canApply: canApply, requestHandler: requestHandler)

        case let (.noPermission(permissionView, _), .requirePassword(folderToken, folderType, handler)):
            DocsLogger.info("folder.container.vc --- stage change", extraInfo: ["from": "noPermission", "to": "requirePassword"])

            // cleanup permissionView
            cleanUpPermissionState(permissionView: permissionView)
            // setup passwordState
            state = setupPasswordState(folderToken: folderToken, folderType: folderType, handler: handler)

        case let (.noPermission(permissionView, _), .displayContent):
            DocsLogger.info("folder.container.vc --- stage change", extraInfo: ["from": "noPermission", "to": "normal"])
            // cleanup permissionView
            cleanUpPermissionState(permissionView: permissionView)
            state = .normal

        // requirePassword -> newState
        case let (.requirePassword(passwordViewController, _), .noPermission(canApply, folderType, handler)):
            DocsLogger.info("folder.container.vc --- stage change", extraInfo: ["from": "requirePassword", "to": "noPermission"])
            // cleanup passwordView
            cleanUpPasswordState(passwordViewController: passwordViewController)
            // setup permissionView
            state = setupRequirePermissionState(canApply: canApply, folderType: folderType, requestHandler: handler)

        case (.requirePassword, .requirePassword):
            DocsLogger.info("folder.container.vc --- stage change", extraInfo: ["from": "requirePassword", "to": "requirePassword"])
            DocsLogger.error("wanring: change from requirePassword to requirePassword has no effect")

        case let (.requirePassword(passwordViewController, _), .displayContent):
            DocsLogger.info("folder.container.vc --- stage change", extraInfo: ["from": "requirePassword", "to": "normal"])
            cleanUpPasswordState(passwordViewController: passwordViewController)
            state = .normal

        // normal -> newState
        case let (.normal, .noPermission(canApply, folderType, handler)):
            DocsLogger.info("folder.container.vc --- stage change", extraInfo: ["from": "normal", "to": "noPermission"])
            state = setupRequirePermissionState(canApply: canApply, folderType: folderType, requestHandler: handler)
        case let (.normal, .requirePassword(folderToken, folderType, handler)):
            DocsLogger.info("folder.container.vc --- stage change", extraInfo: ["from": "normal", "to": "requirePassword"])
            state = setupPasswordState(folderToken: folderToken, folderType: folderType, handler: handler)
        case (.normal, .displayContent):
            DocsLogger.info("folder.container.vc --- stage change", extraInfo: ["from": "normal", "to": "normal"])
            DocsLogger.info("notice: change from normal to normal has no effect")
            return
        }
    }

    private func setupRequirePermissionState(canApply: ApplyPermissionState, folderType: FolderType?, requestHandler: @escaping (String?, Int) -> Void) -> State {
        let v2 = folderType?.v2 ?? false
        let permissionView = PermissionView(isFolderV2: v2)
        let permissionBag = DisposeBag()

        view.addSubview(permissionView)
        permissionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        update(permissionView: permissionView, canApply: canApply, requestHandler: requestHandler)
        navigationBar.trailingButtonBar.isHidden = true
        permissionView.presentHandler = { [weak self] vc in
            self?.present(vc, animated: true, completion: nil)
        }
        return .noPermission(permissionView: permissionView, permissionBag: permissionBag)
    }

    private func update(permissionView: PermissionView,
                        canApply: ApplyPermissionState,
                        requestHandler: @escaping (String?, Int) -> Void) {
        switch canApply {
        case let .allow(ownerName):
            permissionView.showApplyPermissionInterface()
            permissionView.update(ownerName: ownerName)
        case .disallow:
            permissionView.hideForOutsideCompany()
        }
        permissionView.requestPermissionHandler = requestHandler
    }

    private func cleanUpPermissionState(permissionView: PermissionView) {
        permissionView.removeFromSuperview()
        navigationBar.trailingButtonBar.isHidden = false
    }

    private func setupPasswordState(folderToken: String, folderType: FolderType?, handler: @escaping (Bool) -> Void) -> State {
        // 密码输入的页面不显示标题和导航栏按钮
        navigationBar.titleView.isHidden = true
        navigationBar.trailingButtonBar.isHidden = true
        var isFolderV2 = false
        if let folderType = folderType, folderType.v2 {
            isFolderV2 = true
        }
        let passwordInputVC = PasswordInputViewController(token: folderToken,
                                                          type: .folder,
                                                          isFolderV2: isFolderV2)
        addChild(passwordInputVC)
        view.addSubview(passwordInputVC.view)
        passwordInputVC.didMove(toParent: self)
        passwordInputVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        // 专供当前 passwordView 使用的 bag
        let passwordBag = DisposeBag()
        passwordInputVC.unlockStateRelay.asSignal()
            .emit(onNext: handler)
            .disposed(by: passwordBag)
        return .requirePassword(passwordViewController: passwordInputVC, passwordBag: passwordBag)
    }

    private func cleanUpPasswordState(passwordViewController: PasswordInputViewController) {
        passwordViewController.removeFromParent()
        passwordViewController.view.removeFromSuperview()
        // 离开密码输入的页面，重新显示标题
        navigationBar.titleView.isHidden = false
        navigationBar.trailingButtonBar.isHidden = false
    }
}

// Search Bar Transition
extension SpaceFolderContainerController {

    private func rawAnimationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard presented.transitionViewController is SearchBarTransitionTopVCDataSource else {
            return nil
        }
        return SearchBarPresentTransition()
    }

    private func rawAnimationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard dismissed.transitionViewController is SearchBarTransitionTopVCDataSource else {
            return nil
        }
        return SearchBarDismissTransition()
    }
}
