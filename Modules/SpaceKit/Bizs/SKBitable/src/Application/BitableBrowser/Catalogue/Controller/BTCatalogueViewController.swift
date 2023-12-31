//
//  BTCatalogueViewController.swift
//  SKSheet
//
//  Created by huayufan on 2021/3/22.
//  


import UIKit
import RxSwift
import SKUIKit
import SKCommon
import SKFoundation
import SnapKit
import RxCocoa
import UniverseDesignColor

// Bitable管理面板

final class BTCatalogueViewController: DraggableViewController, UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate {

    enum Event {
        /// 占位
        case none
        /// 点击cell
        case choose(IndexPath)
        /// 底部添加
        case add(Weak<UIView>?, CatalogueCreateViewData?)
        /// 左滑： 添加，更多
        case slide(IndexPath, BTCatalogueContextualAction.ActionType, Weak<UIView>?)
        
        case dismiss
    }
    
    struct Layout {
        static let titleViewHeight: CGFloat = 60
    }
    
    enum Stage: Int {
        case new = 0
        case viewDidLoad = 1
        case viewDidAppear = 2
    }
    
    let triggerRelay = PublishRelay<[String: Any]>()
    
    let dragable: Bool
    
    fileprivate var hasLayoutSubviews = BehaviorRelay<Bool>(value: false)
    
    private let dismissRelay = PublishRelay<Event>()
    
    private let viewModel: BTCatalogueViewModel
        
    private let createStackView = BTCatalogueCreateStackView()
    
    private let catalogueView = BTCatalogueView()
    
    private let titleView = BTCatalogueTitleView()
    
    private let bottomBlankView = UIView().construct { it in
        it.backgroundColor = UDColor.bgFloat
    }
    
    private lazy var viewCapturePreventer: ViewCapturePreventable = {
        let preventer = ViewCapturePreventer()
        preventer.notifyContainer = [] // 目录这里的防护不需要toast,因为正文已经有了
        return preventer
    }()
    
    private let disposeBag = DisposeBag()
    
    private let baseContext: BaseContext
    private let basePermissionHelper: BasePermissionHelper
    
    required init(api: CatalogueServiceAPI, dragable: Bool, baseContext: BaseContext) {
        DocsLogger.info("BTCatalogueViewController.init dragable:\(dragable)")
        viewModel = BTCatalogueViewModel(api: api)
        self.dragable = dragable
        self.baseContext = baseContext
        self.basePermissionHelper = BasePermissionHelper(baseContext: baseContext)
        super.init(nibName: nil, bundle: nil)
        setupInit()
        makeUI()
        setupLayout()
        bindViewModel()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addGestureRecognizer()
        
        if view.frame.size.height > 0 {
            contentViewMaxY = view.frame.size.height * (1 - 0.70)
        }
        
        basePermissionHelper.startObserve(observer: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if hasLayoutSubviews.value == false {
            hasLayoutSubviews.accept(true)
        }
        setupCornerRadii()
        updateCreateViewConstraints()
    }

    private func setupInit() {
        transitioningDelegate = self
        if !dragable {
            gapState = .full
        }
    }
    
    
    func ensureSubviewsDidLayout(block: @escaping () -> Void) {
        hasLayoutSubviews.subscribe(onNext: { (_) in
            block()
        }).disposed(by: disposeBag)
    }
    
    private func bindViewModel() {
        let bottomTap = createStackView.rx
                                  .action
                                  .flatMap { event in
                                      let weakCreateView: Weak<UIView> = Weak(event.1)
                                      return Observable.just(Event.add(weakCreateView, event.0))
                                  }.asDriver(onErrorJustReturn: .add(nil, nil))
        
        let dismiss = dismissRelay.asDriver(onErrorJustReturn: .dismiss)
        
        let input = BTCatalogueViewModel.Input(trigger: triggerRelay,
                                               eventDrive: Driver.merge(bottomTap,
                                                                        catalogueView.eventDrive,
                                                                        dismiss))
        
        let output = viewModel.transform(input: input)

        output.title.distinctUntilChanged().bind(to: titleView.rx.title).disposed(by: disposeBag)
        output.catalogue.bind(to: catalogueView.rx.state).disposed(by: disposeBag)
        output.bottomDatas.do(onNext: { [weak self] (_) in
            self?.updateCreateViewConstraints()
        }).bind(to: createStackView.rx.data).disposed(by: disposeBag)
        
        output.close.asObservable().subscribe(onNext: { [weak self] (_) in
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
    }

    private func addGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapDimiss))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc
    private func onTapDimiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func dragDismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return [.allButUpsideDown]
    }

    deinit {
        dismissRelay.accept(.dismiss)
    }

    // MARK: - UI,
    
    private func makeUI() {
        if !self.dragable {
            titleView.viewType = .closeButton
        }
        if ViewCapturePreventer.isFeatureEnable {
            viewCapturePreventer.contentView.backgroundColor = UDColor.bgFloatBase
            contentView = viewCapturePreventer.contentView
        } else {
            contentView = UIView().construct({
                $0.backgroundColor = UDColor.bgFloatBase
            })
        }
        
        titleView.construct {
            $0.backgroundColor = UIColor.clear
            $0.showDefaultShadowColor()
        }
        titleView.closeButtonClickHandler = { [weak self] in
            self?.navigationController?.dismiss(animated: true)
        }
        
        if !SKDisplay.pad {
            if dragable {
                // 整个区域可拖动（scroll 区域还需要另外适配手势冲突情况，当 scroll 区域内容不可滚动时，此处生效）
                contentView.addGestureRecognizer(panGestureRecognizer)
            } else {
                // 仅标题区域可拖动
                titleView.addGestureRecognizer(panGestureRecognizer)
            }
        }
//        createView.construct {
//            $0.backgroundColor = UDColor.bgFloat
//        }
        
        view.addSubview(contentView)
        contentView.addSubview(bottomBlankView)
        contentView.addSubview(titleView)
        contentView.addSubview(catalogueView)
        contentView.addSubview(createStackView)
        
        if dragable {
            catalogueView.catalogueViewDelegate = self
        }
    }
    
    private func setupCornerRadii() {
        contentView.layer.cornerRadius = 12
        contentView.layer.maskedCorners = .top
    }
    
    private func updateCreateViewConstraints() {
        let isPhoneLandscape = SKDisplay.phone && UIApplication.shared.statusBarOrientation.isLandscape
        guard !isPhoneLandscape else {
            createStackView.snp.updateConstraints { (make) in
                make.height.equalTo(0)
            }
            createStackView.isHidden = true
            bottomBlankView.isHidden = true
            return
        }
        if contentView.frame.minY >= contentViewMaxY {
            createStackView.snp.updateConstraints { (make) in
                make.height.equalTo(viewModel.bottomViewsHeight)
                make.bottom.equalTo(bottomBlankView.snp.top).offset(contentView.frame.minY - contentViewMaxY)
            }
        } else {
            createStackView.snp.updateConstraints { (make) in
                make.height.equalTo(viewModel.bottomViewsHeight)
                make.bottom.equalTo(bottomBlankView.snp.top)
            }
        }
        createStackView.isHidden = (viewModel.bottomViewsHeight == 0)
        bottomBlankView.isHidden = (viewModel.bottomViewsHeight == 0)
    }
    
    private func setupLayout() {
        contentView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(contentViewMaxY)
            make.bottom.equalToSuperview()
        }
        
        titleView.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(Layout.titleViewHeight)
        }
        
        catalogueView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(titleView.snp.bottom)
            make.bottom.equalTo(createStackView.snp.top)
        }
        
        bottomBlankView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        
        createStackView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(BTCatalogueCreateStackView.height(0))
            make.bottom.equalTo(bottomBlankView.snp.top)
        }
    }
    // MARK: - Tap Gesture Handling
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == view ? true : false
    }
    // MARK: - Animation Transition,  UIViewControllerTransitioningDelegate
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DimmingPresentAnimation(animateDuration: 0.25, layerAnimationOnly: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DimmingDismissAnimation(animateDuration: 0.25, layerAnimationOnly: true)
    }

    @objc
    private func orientationDidChange() {
        updateCreateViewConstraints()
        view.setNeedsLayout()
    }
}


extension BTCatalogueViewController {
    
    func udpate(param: [String: Any]) {
        ensureSubviewsDidLayout { [weak self] in
            self?.triggerRelay.accept(param)
        }
    }
}

extension BTCatalogueViewController {
    /// 设置允许被截图
    func setCaptureAllowed(_ allow: Bool) {
        DocsLogger.info("BTCatalogueViewController setCaptureAllowed => \(allow)")
        viewCapturePreventer.isCaptureAllowed = allow
    }
}


extension BTCatalogueViewController: BTCatalogueViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleScrollViewDidScroll(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        handleScrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
    }
}

extension BTCatalogueViewController: BasePermissionObserver {
    func initOrUpdateCapturePermission(hasCapturePermission: Bool) {
        DocsLogger.info("[BasePermission] BTCatalogueViewController initOrUpdateCapturePermission \(hasCapturePermission)")
        setCaptureAllowed(hasCapturePermission)
    }
}
