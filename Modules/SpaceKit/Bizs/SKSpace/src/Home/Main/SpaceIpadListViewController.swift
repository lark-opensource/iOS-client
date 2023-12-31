//
//  SpaceIpadListViewController.swift
//  SKSpace
//
//  Created by majie.7 on 2023/10/12.
//

import SKCommon
import UniverseDesignColor
import UniverseDesignDialog
import UniverseDesignToast
import UniverseDesignIcon
import SKWorkspace
import LarkContainer
import SKResource
import SKUIKit
import SKFoundation
import SpaceInterface
import SKInfra
import LarkUIKit
import RxSwift
import RxCocoa

public struct SpaceIpadListConfig {
    public let canBack: Bool
    public let needShowPinFolderList: Bool
    
    public static let `default` = SpaceIpadListConfig(canBack: false, needShowPinFolderList: false)
    public static let cloudDriver = SpaceIpadListConfig(canBack: false, needShowPinFolderList: UserScopeNoChangeFG.MJ.quickAccessFolderEnable)
    public static let pinFolderList = SpaceIpadListConfig(canBack: true, needShowPinFolderList: false)
}


public class SpaceIpadListViewControler: BaseViewController {
    
    private var spaceCreateIntentProvider: (() -> SpaceCreateIntent)
    private let userResolver: UserResolver
    
    private let headerTitle: String?
    private let rootViewController: UIViewController
    
    private let reachabilityRelay = BehaviorRelay(value: true)
    private var reachabilityChanged: Observable<Bool> {
        reachabilityRelay.distinctUntilChanged().asObservable()
    }
    
    private let createEnableRelay = BehaviorRelay(value: true)
    
    private let disposeBag = DisposeBag()
    
    private lazy var stackHeaderView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 8
        return view
    }()
    
    private lazy var titleView: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.textColor = UDColor.textTitle
        return label
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.leftOutlined, for: .normal)
        button.docs.addHighlight(with: UIEdgeInsets(top: 6, left: -6, bottom: 6, right: -6), radius: 6)
        return button
    }()
    
    private lazy var createView: WorkspaceCreateView = {
        let view = WorkspaceCreateView(enableObservable: createEnableRelay.asObservable())
        view.onClickPanel = { [weak self] sourceView, type in
            self?.showCreatePanel(sourceView: sourceView, type: type)
        }
        return view
    }()
    
    //TODO: 考虑将快速访问文件夹view抽离
    private lazy var pinFolderView: CloudDriverPinFolderView = {
        let quickAccessDataModel = QuickAccessDataModel(userID: userResolver.userID, apiType: .justFolder)
        let quickAccessViewModel = QuickAccessViewModel(dataModel: quickAccessDataModel)
        let view = CloudDriverPinFolderView(viewModel: quickAccessViewModel, isShowInDetail: true)
        view.isHidden = true
        return view
    }()
    private let config: SpaceIpadListConfig
    
    public init(userResolver: UserResolver,
                title: String?,
                rootViewController: UIViewController,
                config: SpaceIpadListConfig = .default,
                createIntentProvider: @escaping (() -> SpaceCreateIntent)) {
        self.userResolver = userResolver
        self.headerTitle = title
        self.spaceCreateIntentProvider = createIntentProvider
        self.rootViewController = rootViewController
        self.config = config
        super.init(nibName: nil, bundle: nil)
        
        self.bindAction()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        self.navigationBar.isHidden = true
        
        view.addSubview(createView)
        view.addSubview(pinFolderView)

        
        if let headerTitle {
            view.addSubview(stackHeaderView)
            stackHeaderView.addArrangedSubview(backButton)
            stackHeaderView.addArrangedSubview(titleView)
            
            stackHeaderView.snp.makeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
                make.left.right.equalToSuperview().inset(24)
                make.height.equalTo(56)
            }
            
            backButton.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.height.width.equalTo(24)
            }
            
            titleView.text = headerTitle
            titleView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.height.equalTo(56)
            }
            
            createView.snp.makeConstraints { make in
                make.top.equalTo(stackHeaderView.snp.bottom).offset(8)
                make.left.right.equalToSuperview()
                make.height.equalTo(64)
            }
            
            backButton.isHidden = !config.canBack
        } else {
            createView.snp.makeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
                make.left.right.equalToSuperview()
                make.height.equalTo(64)
            }
        }
        
        pinFolderView.snp.makeConstraints { make in
            make.top.equalTo(createView.snp.bottom).offset(24)
            make.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        
        addChild(rootViewController)
        view.addSubview(rootViewController.view)
        rootViewController.didMove(toParent: self)
        rootViewController.view.snp.makeConstraints { (make) in
            make.top.equalTo(pinFolderView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        
    }
    
    private func bindAction() {
        RxNetworkMonitor.networkStatus(observerObj: self)
            .map { $1 }
            .bind(to: reachabilityRelay)
            .disposed(by: disposeBag)
        
        backButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }).disposed(by: disposeBag)
        
        if let spaceHomeVC = rootViewController as? SpaceHomeViewController {
            spaceHomeVC.homeViewModel.createEnableDriver.asObservable().bind(to: createEnableRelay).disposed(by: disposeBag)
        }
        
        if config.needShowPinFolderList {
            bindPinFolderListAction()
        }
    }
    
    private func showCreatePanel(sourceView: UIView, type: WorkspaceCreatePanelType) {
        let intent = spaceCreateIntentProvider()
        let ccmOpenSource = intent.context.module.generateCCMOpenCreateSource()
        let trackParameters = DocsCreateDirectorV2.TrackParameters(source: intent.source,
                                                                   module: intent.context.module,
                                                                   ccmOpenSource: ccmOpenSource)
        let helper = SpaceCreatePanelHelper(trackParameters: trackParameters,
                                                  mountLocation: intent.context.mountLocation,
                                                  createDelegate: self,
                                                  createRouter: self,
                                                  createButtonLocation: .bottomRight)
        switch type {
        case .create:
            guard createEnableRelay.value else {
                UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_SharedSpaces_NewGayed_Tooltip, on: view.window ?? view)
                return
            }
            let items = helper.generateCloudDocItmesForLark(intent: intent, preferNonSquareBaseIcon: true, reachable: self.reachabilityChanged)
            let controller = WorkspaceCreateTypePickerController(items: items, sourceView: sourceView)
            present(controller, animated: true)
        case .upload:
            guard reachabilityRelay.value else {
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_OperateFailedNoNet, on: view.window ?? view)
                return
            }
            guard createEnableRelay.value else {
                UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_SharedSpaces_UploadGayed_Tooltip, on: view.window ?? view)
                return
            }
            let items = helper.generateUploadItemForLark(intent: intent, reachable: self.reachabilityChanged)
            let controller = WorkspaceCreateTypePickerController(items: items, sourceView: sourceView)
            present(controller, animated: true)
        case .template:
            guard reachabilityRelay.value else {
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_OperateFailedNoNet, on: view.window ?? view)
                return
            }
            guard createEnableRelay.value else {
                UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_SharedSpaces_NewGayed_Tooltip, on: view.window ?? view)
                return
            }
            let templateVC = TemplateCenterViewController(mountLocation: intent.context.mountLocation, source: .fromSpaceIcon)
            let controller = LkNavigationController(rootViewController: templateVC)
            present(controller, animated: true)
        }
    }
    
}

extension SpaceIpadListViewControler: DocsCreateViewControllerRouter {
    public func routerPresent(vc: UIViewController, animated: Bool, completion: (() -> Void)?) {
        present(vc, animated: animated, completion: completion)
    }
    
    public var routerImpl: UIViewController? {
        self
    }
    
    public func routerPush(vc: UIViewController, animated: Bool) {
        userResolver.navigator.push(vc, from: self)
    }
}

extension SpaceIpadListViewControler: DocsCreateViewControllerDelegate {
    public func createCancelled() {}
    
    public func createComplete(token: String?, type: SpaceInterface.DocsType, error: Error?) {
        if let docsError = error as? DocsNetworkError {
            let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
            let context = PermissionCommonErrorContext(objToken: token ?? "", objType: type, operation: .createSubNode)
            if let behavior = permissionSDK.canHandle(error: docsError, context: context) {
                behavior(self, BundleI18n.SKResource.Doc_Facade_CreateFailed)
                return
            }
            if docsError.code == .createLimited {
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_1000, execute: { [weak self] in
                    // 租户达到创建的上线，弹出付费提示
                    let dialog = UDDialog()
                    dialog.setTitle(text: BundleI18n.SKResource.Doc_List_CreateDocumentExceedLimit)
                    dialog.setContent(text: docsError.errorMsg)
                    dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
                    dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_Facade_NotifyAdminUpgrade)
                    self?.present(dialog, animated: true, completion: nil)
                })
            } else {
                UDToast.showFailure(with: docsError.errorMsg, on: view.window ?? view)
            }
            return
        }
        if error != nil {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_CreateFailed, on: view.window ?? view)
        }
    }
    
    // 列表创建文件夹后需要打开文件夹
    public func createFolderComplete(folderToken: String) {
        if let delay = SettingConfig.createFolderDelay, delay > 0 {
            // 延时单位是毫秒
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) { [weak self] in
                self?.didCreateFolderComplete(folderToken: folderToken)
            }
        } else {
            // 不延时
            didCreateFolderComplete(folderToken: folderToken)
        }
    }

    private func didCreateFolderComplete(folderToken: String) {
        guard let folderManager = try? userResolver.resolve(assert: FolderRouterService.self) else {
            UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Facade_CreateSuccessfully, on: self.view)
            return
        }
        folderManager.destinationController(for: folderToken, sourceController: self) { [weak self] controller in
            guard let self = self else { return }
            self.userResolver.navigator.push(controller, from: self)
        }
    }
}

extension SpaceIpadListViewControler: SpaceFolderContentViewController {
    public var contentNaviBarCoordinator: SpaceNaviBarCoordinator? {
        if let rootVC = rootViewController as? SpaceHomeViewController {
            return rootVC.naviBarCoordinator
        }
        return nil
    }
    
    public func reloadHomeLayout() {
        if let rootVC = rootViewController as? SpaceHomeViewController {
            rootVC.reloadHomeLayout()
            return
        }
        view.layoutIfNeeded()
    }
}


// 快速访问文件夹列表相关
extension SpaceIpadListViewControler {
    private func bindPinFolderListAction() {
        if let homeVC = rootViewController as? SpaceHomeViewController,
           let homeVM = homeVC.homeViewModel as? SpaceStandardHomeViewModel {
            pinFolderView.viewModel.actionSignal.map { action in
                return SpaceHomeAction.sectionAction(action)
            }
            .emit(to: homeVM.actionInput)
            .disposed(by: disposeBag)
        }
        
        pinFolderView.viewAllButton.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] _ in
                guard let self, let vcFactory = try? self.userResolver.resolve(assert: SpaceVCFactory.self) else {
                    return
                }
                
                let pinFolderListVC = vcFactory.makeIpadPinFolderListViewController()
                self.userResolver.navigator.push(pinFolderListVC, from: self)
            })
            .disposed(by: disposeBag)
        
        pinFolderView.updateShowStatusSignal
            .emit(onNext: { [weak self] needShow in
                self?.updatePinFolderView(needShow: needShow)
            })
            .disposed(by: disposeBag)
        
        pinFolderView.prepare()
    }
    
    private func updatePinFolderView(needShow: Bool) {
        pinFolderView.isHidden = !needShow
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self else { return }
            if needShow {
                self.pinFolderView.snp.updateConstraints { make in
                    make.height.equalTo(self.pinFolderView.viewHeight)
                }
            } else {
                self.pinFolderView.snp.updateConstraints { make in
                    make.height.equalTo(0)
                }
            }
            self.view.layoutIfNeeded()
        }
        
    }
}
