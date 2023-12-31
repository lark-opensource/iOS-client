//
//  LKAssetBrowser.swift
//  LKBaseAssetBrowser
//
//  Created by Hayden Wang on 2022/1/25.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignActionPanel

public typealias LKAssetBrowserPage = LKGalleryPage

@dynamicMemberLookup
open class LKAssetBrowser: UIViewController {

    /// 滑动方向类型
    public typealias ScrollDirection = LKGalleryView.ScrollDirection

    // MARK: Configurations

    /// 自实现转场动画
    open lazy var transitionAnimator: LKAssetBrowserAnimatedTransitioning = LKAssetBrowserFadeAnimator()
    
    public subscript<T>(dynamicMember keyPath: WritableKeyPath<LKGalleryView, T>) -> T {
        get { galleryView[keyPath: keyPath] }
        set { galleryView[keyPath: keyPath] = newValue }
    }

//    /// 滑动方向
//    open var scrollDirection: ScrollDirection {
//        get { galleryView.scrollDirection }
//        set { galleryView.scrollDirection = newValue }
//    }
//
//    /// 页面间距
//    open var pageSpacing: CGFloat {
//        get { galleryView.pageSpacing }
//        set { galleryView.pageSpacing = newValue }
//    }
//
//    /// 当前页码
//    open var currentPageIndex: Int {
//        get { galleryView.currentPageIndex }
//        set { galleryView.currentPageIndex = newValue }
//    }
    
    private var currentPageIndex: Int {
        get { galleryView.currentPageIndex }
        set { galleryView.currentPageIndex = newValue }
    }

    open var onLongPressed: ((LKAssetBrowserPage) -> Void)?
    
    open var plugins: [LKAssetBrowserPlugin] = [] {
        didSet {
            reloadPluginButtons()
        }
    }

    // MARK: 数据源 & 回调

    /// 展示的数据
    open var displayAssets: [LKAsset] = [] {
        didSet {
            self.numberOfItems = { [weak self] in
                guard let self = self else { return 0 }
                return self.displayAssets.count
            }
            self.cellClassAtIndex = { [weak self] index in
                guard let self = self else { return LKAssetBaseImagePage.self }
                return self.displayAssets[index].associatedPageType
            }
            self.reloadPageAtIndex = { [weak self] context in
                guard let self = self else { return }
                var asset = self.displayAssets[context.index]
                asset.displayAsset(on: context.cell)
            }
            self.pageDidShow = { [weak self] page, index in
                guard let self = self else { return }
                guard var asset = self.displayAssets[index] as? LKLoadableAsset else {
                    return
                }
                self.showOriginButton.activeKey = asset.identifier
                self.showOriginButton.isHidden = true
                asset.updateProgressState = {[weak self] state in
                    DispatchQueue.main.async {
                        self?.handleProgress(state: state, asset: asset)
                    }
                }
                asset.downloadOrigin(on: page)
            }
        }
    }

    /// 浏览过程中实时获取数据总量
    private var numberOfItems: () -> Int = { 0 }

    /// 返回可复用的Cell类。用户可根据index返回不同的类。本闭包将在每次复用Cell时实时调用。
    private var cellClassAtIndex: (_ index: Int) -> LKAssetBrowserPage.Type = { _ in
        LKAssetBaseImagePage.self
    }

    /// Cell刷新时用的上下文。index: 刷新的Cell对应的index；currentIndex: 当前显示的页
    public typealias ReloadCellContext = (cell: LKAssetBrowserPage, index: Int)

    /// 刷新Cell数据。本闭包将在Cell完成位置布局后调用。
    private var reloadPageAtIndex: ((ReloadCellContext) -> Void)?

    /// 自然滑动引起的页码改变时回调
    open var didChangedPageIndex: ((Int) -> Void)?

    /// Cell将显示
    open var pageDidShow: ((LKAssetBrowserPage, Int) -> Void)?

    /// Cell将不显示
    open var pageWillScrollOut: ((LKAssetBrowserPage, Int) -> Void)?

    // MARK: UI Components

    /// 主视图
    open lazy var galleryView: LKGalleryView = {
        let galleryView = LKGalleryView(delegate: self)
        return galleryView
    }()

    /// 页码指示
    open var pageIndicator: LKAssetPageIndicator?

    lazy var showOriginButton: ShowOriginButton = {
        let button = ShowOriginButton()
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.font = UIFont.ud.body2(.fixed)
        button.textColor = UIColor.ud.primaryOnPrimaryFill
        button.backgroundColor = UIColor.ud.N600.nonDynamic.withAlphaComponent(0.6)
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(showOriginButtonClicked(sender:)))
        button.isUserInteractionEnabled = true
        button.addGestureRecognizer(tapGesture)
        return button
    }()
    
    private lazy var buttonGroup: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    internal lazy var moreButton: UIButton = {
        let button = UIButton(type: .custom)
        let moreIcon = UDIcon.getIconByKey(.moreBoldOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
        button.setImage(moreIcon, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.backgroundColor = LKAssetBrowserView.Cons.buttonColor
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 32),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])
        button.addTarget(self, action: #selector(didTapMoreButton), for: .touchUpInside)
        return button
    }()

    /// 背景蒙版
    open lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()

    open weak var previousNavigationControllerDelegate: UINavigationControllerDelegate?

    // MARK: Life Cycle

    deinit {
        LKAssetBrowserLogger.debug("deinit - \(self.classForCoder)")
        navigationController?.delegate = previousNavigationControllerDelegate
    }

    /// 刷新
    open func reloadData() {
        galleryView.reloadData()
        pageIndicator?.reloadData(numberOfItems: numberOfItems(), pageIndex: currentPageIndex)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            view.overrideUserInterfaceStyle = .light
        }

        hideNavigationBar(true)

        galleryView.assetBrowser = self
        transitionAnimator.assetBrowser = self

        view.backgroundColor = .clear
        view.addSubview(dimmingView)
        view.addSubview(galleryView)
        view.addSubview(buttonGroup)
        view.addSubview(showOriginButton)
        NSLayoutConstraint.activate([
            buttonGroup.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
            buttonGroup.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6),
            showOriginButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6),
            showOriginButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
            showOriginButton.heightAnchor.constraint(equalToConstant: 32),
            showOriginButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 96),
            showOriginButton.rightAnchor.constraint(lessThanOrEqualTo: buttonGroup.rightAnchor, constant: 10)
        ])

//        view.setNeedsLayout()
//        view.layoutIfNeeded()
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        dimmingView.frame = view.bounds
        galleryView.frame = view.bounds
        pageIndicator?.reloadData(numberOfItems: numberOfItems(), pageIndex: currentPageIndex)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideNavigationBar(true)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.delegate = previousNavigationControllerDelegate
        if let indicator = pageIndicator {
            view.addSubview(indicator)
            indicator.setup(with: self)
        }
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideNavigationBar(false)
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        galleryView.isDeviceRotating = true
    }
    
    private func reloadPluginButtons() {
        // Remove all action buttons
        buttonGroup.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        // Add action buttons according to plugins
        let bottomPlugins = plugins.filter { $0.type.contains(.bottomButton) }
        for plugin in bottomPlugins {
            buttonGroup.addArrangedSubview(plugin.button)
        }
        if bottomPlugins.count < plugins.count {
            buttonGroup.addArrangedSubview(moreButton)
        }
    }

    private func enablePlugins(enable: Bool) {
        for plugin in plugins {
            plugin.button.isEnabled = enable
        }
    }

    private func handleProgress(state: LKDisplayAssetState, asset: LKLoadableAsset) {
        guard self.showOriginButton.activeKey == asset.identifier else {
            LKAssetBrowserLogger.debug("download origin image current key \(asset.identifier) not match button key \(self.showOriginButton.activeKey)")
            return
        }
        self.showOriginButton.isUserInteractionEnabled = false
        enablePlugins(enable: true)
        switch state {
        case .none:
            self.showOriginButton.isHidden = true
            LKAssetBrowserLogger.debug("download origin image none \(asset.identifier)")
        case .start:
            self.showOriginButton.isHidden = false
            self.showOriginButton.isUserInteractionEnabled = true
            LKAssetBrowserLogger.debug("download origin image start \(asset.identifier)")
            self.showOriginButton.state = .start(key: asset.identifier, fileSize: 0)
        case .progress(let value):
            self.showOriginButton.isHidden = false
            enablePlugins(enable: false)
            LKAssetBrowserLogger.debug("download origin image progress \(asset.identifier)")
            self.showOriginButton.state = .progress(key: asset.identifier, value: value)
        case .end:
            LKAssetBrowserLogger.debug("download origin image end \(asset.identifier)")
            self.showOriginButton.isHidden = false
            self.showOriginButton.state = .end(key: asset.identifier)
        }
    }

    @objc
    private func showOriginButtonClicked(sender: UIControl?) {
        guard let page = galleryView.currentPage else { return }
        guard let asset = displayAssets[currentPageIndex] as? LKLoadableAsset, asset.identifier == self.showOriginButton.activeKey else {
            return
        }
        asset.downloadOrigin(on: page)
    }
    open func showPluginsActionSheet(forAsset asset: LKAsset, page: LKAssetBrowserPage, isLongPress: Bool) {
        let context = LKAssetBrowserContext(asset: asset, page: page, browser: self, actionInfo: isLongPress ? .fromLongPress : .fromMoreButton)
        let availablePlugins = plugins.filter { $0.type.contains(.actionSheet) }
        var shouldShowActionPanel: Bool = false
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: false))
        for plugin in availablePlugins {
            guard plugin.shouldDisplayPlugin(on: context) else { continue }
            guard let title = plugin.title else { return }
            shouldShowActionPanel = true
            actionSheet.addDefaultItem(text: title) {
                plugin.handleAsset(on: context)
            }
        }
        guard shouldShowActionPanel else { return }
        actionSheet.setCancelItem(text: BundleI18n.LarkAssetsBrowser.Lark_Legacy_Cancel)
        present(actionSheet, animated: true)
    }

    // MARK: - Show & Dismiss

    /// 通过本回调，把图片浏览器嵌套在导航控制器里
    public typealias PresentEmbedClosure = (LKAssetBrowser) -> UINavigationController

    /// 打开方式类型
    public enum ShowType {
        case push(inNC: UINavigationController?)
        case present(fromVC: UIViewController?, embedHandler: PresentEmbedClosure?)
    }

    /// 打开 AssetBrowser
    open func show(method: ShowType = .present(fromVC: nil, embedHandler: nil)) {
        switch method {
        case .push(let inNC):
            let nav = inNC ?? LKAssetBrowserUtils.topViewController?.navigationController
            previousNavigationControllerDelegate = nav?.delegate
            nav?.delegate = self
            nav?.pushViewController(self, animated: true)
        case .present(let fromVC, let embedHandler):
            let toVC = embedHandler?(self) ?? self
            toVC.modalPresentationStyle = .custom
            toVC.modalPresentationCapturesStatusBarAppearance = true
            toVC.transitioningDelegate = self
            let from = fromVC ?? LKAssetBrowserUtils.topViewController
            from?.present(toVC, animated: true, completion: nil)
        }
    }

    /// 关闭 AssetBrowser
    open func dismiss() {
        setStatusBarHidden(false)
        pageIndicator?.removeFromSuperview()
        if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.delegate = self
            navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - Navigation Bar

    /// 在PhotoBrowser打开之前，导航栏是否隐藏
    open var isPreviousNavigationBarHidden: Bool?

    private func hideNavigationBar(_ hide: Bool) {
        if hide {
            if isPreviousNavigationBarHidden == nil {
                isPreviousNavigationBarHidden = navigationController?.isNavigationBarHidden
            }
            navigationController?.setNavigationBarHidden(true, animated: false)
        } else {
            if let barHidden = isPreviousNavigationBarHidden {
                navigationController?.setNavigationBarHidden(barHidden, animated: false)
            }
        }
    }

    // MARK: - Status Bar

    private lazy var isPreviousStatusBarHidden: Bool = {
        var previousVC: UIViewController?
        if let vc = self.presentingViewController {
            previousVC = vc
        } else {
            if let navVCs = self.navigationController?.viewControllers, navVCs.count >= 2 {
                previousVC = navVCs[navVCs.count - 2]
            }
        }
        return previousVC?.prefersStatusBarHidden ?? false
    }()

    private lazy var isStatusBarHidden = self.isPreviousStatusBarHidden

    open override var prefersStatusBarHidden: Bool {
        return isStatusBarHidden
    }

    open func setStatusBarHidden(_ isHidden: Bool) {
        if isHidden {
            isStatusBarHidden = true
        } else {
            isStatusBarHidden = isPreviousStatusBarHidden
        }
        setNeedsStatusBarAppearanceUpdate()
    }

    @objc
    private func didTapMoreButton() {
        guard let page = galleryView.currentPage else { return }
        showPluginsActionSheet(forAsset: displayAssets[currentPageIndex], page: page, isLongPress: false)
    }
}

// MARK: - Transitioning

extension LKAssetBrowser: UIViewControllerTransitioningDelegate, UINavigationControllerDelegate {

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.isForShow = true
        transitionAnimator.assetBrowser = self
        return transitionAnimator
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.isForShow = false
        transitionAnimator.assetBrowser = self
        return transitionAnimator
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.isForShow = (operation == .push)
        transitionAnimator.assetBrowser = self
        transitionAnimator.isNavigationAnimation = true
        return transitionAnimator
    }
}

// MARK: - GalleryView Delegate

extension LKAssetBrowser: LKGalleryViewDelegate {

    public func numberOfPages(in galleryView: LKGalleryView) -> Int {
        return numberOfItems()
    }

    public func classForPage(in galleryView: LKGalleryView, atIndex index: Int) -> LKGalleryPage.Type {
        return cellClassAtIndex(index)
    }

    public func galleryView(_ galleryView: LKGalleryView, didChangePageIndex index: Int) {
        LKAssetBrowserLogger.info("\(#function) \(index + 1)")
        pageIndicator?.didChanged(pageIndex: index)
        didChangedPageIndex?(index)
    }

    public func galleryView(_ galleryView: LKGalleryView, didShowPage page: LKGalleryPage, atIndex index: Int) {
        LKAssetBrowserLogger.info("\(#function) \(index + 1)")
        pageDidShow?(page, index)
        for plugin in plugins {
            plugin.currentContext = LKAssetBrowserContext(asset: displayAssets[index], page: page, browser: self, actionInfo: .fromBottomButton)
        }
        updatePluginButtons(forAsset: displayAssets[index], page: page)
    }

    public func galleryView(_ galleryView: LKGalleryView, willScrollOutPage page: LKGalleryPage, atIndex index: Int) {
        LKAssetBrowserLogger.info("\(#function) \(index + 1)")
        pageWillScrollOut?(page, index)
    }

    public func galleryView(_ galleryView: LKGalleryView, didPreparePage page: LKGalleryPage, atIndex index: Int) {
        LKAssetBrowserLogger.info("\(#function) \(index + 1)")
    }

    public func galleryView(_ galleryView: LKGalleryView, didRecyclePage page: LKGalleryPage, atIndex index: Int) {
        LKAssetBrowserLogger.info("\(#function) \(index + 1)")
        displayAssets[index].cancelAsset(on: page)
    }

    public func galleryView(_ galleryView: LKGalleryView, shouldReloadDataForPage page: LKGalleryPage, atIndex index: Int) {
        LKAssetBrowserLogger.info("\(#function) \(index + 1)")
        reloadPageAtIndex?(ReloadCellContext(cell: page, index: index))
        // TODO: Refactor duplicate code.
        if let page = page as? LKAssetBaseImagePage {
            page.longPressedAction = { [weak self] (page, _) in
                guard let self = self else { return }
                self.onLongPressed?(page)
                self.showPluginsActionSheet(forAsset: self.displayAssets[index], page: page, isLongPress: true)
            }
        } else if let page = page as? LKAssetByteImagePage {
            page.longPressedAction = { [weak self] (page, _) in
                guard let self = self else { return }
                self.onLongPressed?(page)
                self.showPluginsActionSheet(forAsset: self.displayAssets[index], page: page, isLongPress: true)
            }
            page.didFinishLoadingImage = { [weak self, weak page] in
                guard let self = self, let page = page else { return }
                guard page === self.galleryView.currentPage else { return }
                self.updatePluginButtons(forAsset: self.displayAssets[index], page: page)
            }
        }  else if let page = page as? LKAssetByteImageViewPage {
            page.longPressedAction = { [weak self] (page, _) in
                guard let self = self else { return }
                self.onLongPressed?(page)
                self.showPluginsActionSheet(forAsset: self.displayAssets[index], page: page, isLongPress: true)
            }
            page.didFinishLoadingImage = { [weak self, weak page] in
                guard let self = self, let page = page else { return }
                guard page === self.galleryView.currentPage else { return }
                self.updatePluginButtons(forAsset: self.displayAssets[index], page: page)
            }
        }
    }
    
    private func updatePluginButtons(forAsset asset: LKAsset, page: LKAssetBrowserPage) {
        let context = LKAssetBrowserContext(asset: asset, page: page, browser: self, actionInfo: .fromBottomButton)
        let availablePlugins = plugins.filter { $0.type.contains(.bottomButton) }
        for plugin in availablePlugins {
            plugin.button.isHidden = !plugin.shouldDisplayPlugin(on: context)
        }
    }
}

extension UIControl {

    /// Adding a closure as target to a UIControl
    ///
    /// Example:
    /// ```
    /// button.addAction {
    ///     print("Hello, Closure!")
    /// }
    /// ```
    /// or
    /// ```
    /// self.button.addAction(for: .touchUpInside) { [unowned self] in
    ///     self.doStuff()
    /// }
    /// ```
    ///
    /// - SeeAlso:
    /// https://stackoverflow.com/questions/25919472/adding-a-closure-as-target-to-a-uibutton
    ///
    public func addAction(for controlEvents: UIControl.Event = .touchUpInside,
                          _ closure: @escaping () -> Void) {
        if #available(iOS 14.0, *) {
            addAction(UIAction { _ in
                closure()
            }, for: controlEvents)
        } else {
            @objc class ClosureSleeve: NSObject {
                let closure: ()-> Void
                init(_ closure: @escaping () -> Void) {
                    self.closure = closure
                }
                @objc func invoke() {
                    closure()
                }
            }
            let sleeve = ClosureSleeve(closure)
            addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)
            objc_setAssociatedObject(self, "\(UUID())", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
}
