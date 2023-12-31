//
//  SpaceIpadHomeViewController.swift
//  SKSpace
//
//  Created by majie.7 on 2023/10/9.
//

import LarkContainer
import LarkTraitCollection
import LarkSplitViewController
import LarkUIKit
import RxSwift
import SKWorkspace

public struct iPadSpaceHomeConfig {

    // 是否要根据滑动位置控制创建按钮的展示
    var createButtonVisableWhenScroll: Bool
    // 是否要根据RC视图的切换控制创建按钮的展示
    var createButtonVisableWhenRCChange: Bool
    // 是否需要再secondVC为空的时候打开主页
    var needOpenHomeEntranceWhenSeondVCNil: Bool
    
    public init(createButtonVisableWhenScroll: Bool,
                createButtonVisableWhenRCChange: Bool,
                needOpenHomeEntranceWhenSeondVCNil: Bool) {
        self.createButtonVisableWhenScroll = createButtonVisableWhenScroll
        self.createButtonVisableWhenRCChange = createButtonVisableWhenRCChange
        self.needOpenHomeEntranceWhenSeondVCNil = needOpenHomeEntranceWhenSeondVCNil
    }
    
    public static let `default` = iPadSpaceHomeConfig(createButtonVisableWhenScroll: false,
                                                      createButtonVisableWhenRCChange: false,
                                                      needOpenHomeEntranceWhenSeondVCNil: false)
    
    public static let tabHome = iPadSpaceHomeConfig(createButtonVisableWhenScroll: false,
                                                    createButtonVisableWhenRCChange: true,
                                                    needOpenHomeEntranceWhenSeondVCNil: true)
    
    public static let subFolder = iPadSpaceHomeConfig(createButtonVisableWhenScroll: false,
                                                      createButtonVisableWhenRCChange: false,
                                                      needOpenHomeEntranceWhenSeondVCNil: false)
}


public class SpaceIpadHomeViewController: SpaceHomeViewController {
    // 创建cell加导航栏高度一共120
    private let headerHeight: CGFloat = 120
    
    private var viewWidth: CGFloat = 0.0
    
    private let ipadHomeConfig: iPadSpaceHomeConfig
    
    private let bag = DisposeBag()
    
    public init(userResolver: UserResolver,
                naviBarCoordinator: SpaceNaviBarCoordinator,
                homeUI: SpaceHomeUI,
                homeViewModel: SpaceHomeViewModel,
                useCircleRefreshAnimator: Bool = hideRefreshNumbers,
                config: SpaceHomeViewControllerConfig = .default,
                ipadHomeConfig: iPadSpaceHomeConfig = .default) {
        self.ipadHomeConfig = ipadHomeConfig
        super.init(userResolver: userResolver,
                   naviBarCoordinator: naviBarCoordinator,
                   homeUI: homeUI,
                   homeViewModel: homeViewModel,
                   useCircleRefreshAnimator: useCircleRefreshAnimator,
                   config: config)
        self.createButton.isHidden = true
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupTraitCollection()
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil, completion: { [weak self] _ in
            self?.updateSecondaryIfNeed()
        })
    }

    private func updateSecondaryIfNeed() {
        guard ipadHomeConfig.needOpenHomeEntranceWhenSeondVCNil else { return }
        guard checkSecondaryIsDefaultController() else { return }

        let vcFactory = SpaceVCFactory(userResolver: userResolver)
        let phoneViewController = vcFactory.makeAllFilesController(initialSection: .recent)
        let ipadViewController = vcFactory.makeIpadHomeViewController(userResolver: userResolver)
        let containerVC = LkNavigationController(rootViewController:  WorkspaceIPadContainerController(compactController: phoneViewController,
                                                                                                       regularController: ipadViewController))
        containerVC.navigationBar.isHidden = true

        userResolver.navigator.showDetail(containerVC, from: self)
    }
    
    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard viewWidth != view.frame.width else {
            return
        }
        viewWidth = view.frame.width
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func setupCreateButtonHiddenStatus() {}
    
    private func checkSecondaryIsDefaultController() -> Bool {
        guard let larkSplitViewController else { return false }
        guard var secondaryController = larkSplitViewController.viewController(for: .secondary) else { return false }
        if let navigationController = secondaryController as? UINavigationController,
           let topController = navigationController.topViewController {
            secondaryController = topController
        }
        if (secondaryController as? DefaultDetailVC) != nil {
            return true
        }
        return false
    }
    
    private func setupTraitCollection() {
        guard ipadHomeConfig.createButtonVisableWhenRCChange else { return }

        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: view)
            .observeOn(MainScheduler.instance)
            .filter { change in
                change.old.horizontalSizeClass != change.new.horizontalSizeClass
            }
            .subscribe(onNext: { [weak self] _ in
                self?.updateForTraitCollectionChanged()
            })
            .disposed(by: bag)
        updateForTraitCollectionChanged()
    }
    
    private func updateForTraitCollectionChanged() {
        switch traitCollection.horizontalSizeClass {
        case .unspecified, .regular:
            createButton.isHidden = true
        case .compact:
            createButton.isHidden = false
        @unknown default:
            // 按 R 处理
            createButton.isHidden = true
        }
    }
    
    //用来处理创建section划出屏幕后创建按钮的隐藏与展示
    public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard ipadHomeConfig.createButtonVisableWhenScroll else { return }
        
        let needHidden = scrollView.contentOffset.y <= headerHeight
        if createButton.isHidden != needHidden {
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                self?.createButton.alpha = needHidden ? 0 : 1.0
                self?.view.layoutIfNeeded()
            }, completion: { [weak self] _ in
                self?.createButton.isHidden = needHidden
            })
        }
    }
}
