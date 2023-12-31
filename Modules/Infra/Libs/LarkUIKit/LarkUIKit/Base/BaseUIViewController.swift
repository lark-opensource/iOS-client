//
//  BaseViewController.swift
//  Lark
//
//  Created by 刘晚林 on 2016/12/28.
//  Copyright © 2016年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LKCommonsLogging
import AVFoundation
import SnapKit
import RoundedHUD
import RxSwift
import LarkExtensions
import LarkTraitCollection
import LarkSceneManager
import UniverseDesignColor
import UniverseDesignDialog
import UniverseDesignTheme
import LarkFeatureGating
import LarkSensitivityControl

extension UIViewController {
    open var hasBackPage: Bool {
        guard let navi = navigationController else { return false }
        // 自己已经不是第一级页面
        if let index = navi.realViewControllers.firstIndex(of: self),
            index > 0 {
            return true
        }
        // parent是不是第一级页面
        return parent?.hasBackPage ?? false
    }
}

public protocol CustomNavigationBar {
    var navigationBarStyle: NavigationBarStyle { get }
    var navigationItem: UINavigationItem { get }
}

open class BaseUIViewController: UIViewController, CustomNavigationBar {
    open var closeCallback: (() -> Void)?
    open var backCallback: (() -> Void)?

    open var isNavigationBarHidden: Bool = false
    open var isToolBarHidden: Bool = true // UINavigationController默认隐藏toolBar，这里也默认隐藏

    open var navigationBarStyle: NavigationBarStyle {
        return .default
    }

    public var viewTopConstraint: ConstraintItem {
        return view.safeAreaLayoutGuide.snp.top
    }

    public var viewBottomConstraint: ConstraintItem {
        return view.safeAreaLayoutGuide.snp.bottom
    }

    private lazy var baseTitleView: BaseTitleView = {
        let titleV = BaseTitleView()
        return titleV
    }()

    open override var title: String? {
        didSet {
            titleString = title ?? ""
        }
    }

    open var titleString: String = "" {
        didSet {
            self.baseTitleView.setTitle(title: self.titleString)
            self.navigationItem.titleView = self.baseTitleView
        }
    }

    open var titleColor: UIColor = UIColor.ud.textTitle {
        didSet {
            self.baseTitleView.setTitleColor(color: titleColor)
            self.navigationItem.titleView = self.baseTitleView
        }
    }

    private lazy var _loadingPlaceholderView: LoadingPlaceholderView = {
        let loading = LoadingPlaceholderView()
        loading.isHidden = true
        self.layoutPlaceHolderView(placeholderView: loading)
        return loading
    }()

    open var loadingPlaceholderView: LoadingPlaceholderView {
        self.view.bringSubviewToFront(_loadingPlaceholderView)
        return _loadingPlaceholderView
    }

    private lazy var _retryLoadingView: LoadFaildRetryView = {
        let loading = LoadFaildRetryView()
        loading.isHidden = true
        self.layoutPlaceHolderView(placeholderView: loading)
        return loading
    }()

    open var retryLoadingView: LoadFaildRetryView {
        self.view.bringSubviewToFront(_retryLoadingView)
        return _retryLoadingView
    }

    open func layoutPlaceHolderView(placeholderView: UIView) {
        self.view.addSubview(placeholderView)
        placeholderView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    public typealias ChooseImageCallback = ((UIImage, UIImage, UIImagePickerController) -> Void)
    fileprivate var chooseImageCallback: ChooseImageCallback?
    fileprivate var chooseImageCancelCallback: (() -> Void)?
    fileprivate var hasCallonExit: Bool = false
    private let disposeBag = DisposeBag()
    private var backItem: UIBarButtonItem?

    public static let baseLogger = Logger.log(BaseUIViewController.self, category: "Base.BaseUIViewController")

    open func onExit() {
        let className = NSStringFromClass(type(of: self))
        BaseUIViewController.baseLogger.debug("onExit " + className)
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            if UDThemeManager.getRealUserInterfaceStyle() == .dark {
                return .lightContent
            } else {
                return .darkContent
            }
        } else {
            // Fallback on earlier versions
            return .default
        }
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    open override var shouldAutorotate: Bool {
        return true
    }

    /// 自动避让键盘的Bottom `ConstraintItem`,
    /// 添加在`viewController.view`上的`view`才可以使用,
    /// 目前仅对iPhone适用，iPad由于键盘和VC显示方式太多不在此统一处理
    public private(set) lazy var avoidKeyboardBottom: ConstraintRelatableTarget = {
        return createAvoidKeyboardBottom()
    }()

    // 是否禁止掉了左滑手势
    private var isDisablePopGesture: Bool?

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBase
        DispatchQueue.main.async {
            RootTraitCollection.observer
                .observeRootTraitCollectionDidChange(for: self.view)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.autoConfigNaviItem()
                }).disposed(by: self.disposeBag)
        }
        rememberContentSizeEnabled = true
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.modalPresentationControl.readyToControlIfNeeded()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if self.navigationController?.isNavigationBarHidden != self.isNavigationBarHidden {
            self.navigationController?.setNavigationBarHidden(self.isNavigationBarHidden, animated: animated)
        }
        if !self.isNavigationBarHidden {
            (self.navigationController as? LkNavigationController)?.update(style: self.navigationBarStyle)
        }

        if self.navigationController?.isToolbarHidden != self.isToolBarHidden {
            self.navigationController?.setToolbarHidden(self.isToolBarHidden, animated: false)
        }

        // 自动添加返回按钮和关闭按钮,放到willAppear里做
        // 1. presentingViewController在viewdidLoad里拿不准
        // 2. C视图下返回到该页，需要reload一下naviitem
        autoConfigNaviItem()
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isRemoved() {
            self.onExit()
            self.hasCallonExit = true
        }

        //// 解决 iOS 17 键盘不收起来，左滑返回上一页可能发生页面闪屏情况
        //// https://meego.feishu.cn/larksuite/issue/detail/15529784       
        if self.isMovingFromParent || self.isBeingDismissed {
            self.view.endEditing(true)
        }

        // 解决iOS 15左滑返回冻屏的问题
        // doc: https://bytedance.feishu.cn/docx/doxcnaul0dGUB37JG5OymVR9Tgg
        if #available(iOS 15.0, *), self.parentIsBeingDismissed, let nav = self.presentingViewController as? UINavigationController {
            Self.baseLogger.info("fix freeze screen start, popGesture enable = \(nav.interactivePopGestureRecognizer?.isEnabled)")
            // 在willDismiss之前禁止左滑
            if nav.interactivePopGestureRecognizer?.isEnabled == true {
                Self.baseLogger.info("fix freeze screen disable PopGesture")
                nav.interactivePopGestureRecognizer?.isEnabled = false
                self.isDisablePopGesture = true
            }

            // didDismiss后会调用completion重置左滑, 这里的闭包实现无代码侵入性
            self.transitionCoordinator?.animate(alongsideTransition: nil, completion: { [weak self] context in
                let nav = context.viewController(forKey: .to) as? UINavigationController
                Self.baseLogger.info("fix freeze screen transitionCoordinator completion callback, nav is nil: \(nav == nil), isDisablePopGesture = \(self?.isDisablePopGesture)")
                if let nav = nav, self?.isDisablePopGesture == true {
                    Self.baseLogger.info("fix freeze screen resume PopGesture")
                    nav.interactivePopGestureRecognizer?.isEnabled = true
                    self?.isDisablePopGesture = nil
                }
            })
        }
    }

    private var parentIsBeingDismissed: Bool {
        var controller: UIViewController = self
        while let parent = controller.parent {
            if parent.isBeingDismissed {
                return true
            }
            controller = parent
        }
        return false
    }

    // 分屏时，需要考虑detail的第一个页面返回按钮的出现/隐藏
    // 若双栏变单栏，当前页面没有自定义的非返回按钮，则添加返回按钮(不能替换掉其他自定义按钮)
    // 若单栏变双栏，当前页面有自定义的返回按钮，则隐藏返回按钮(不能替换掉其他自定义按钮)
    private func autoConfigNaviItem() {
        // 自动添加返回按钮和关闭按钮
        guard let item = navigationItem.leftBarButtonItem else { // 左边没有按钮
            if !hasBackPage, presentingViewController != nil { // 没有回退页，被present，设置关闭按钮
                navigationItem.leftBarButtonItem = addCloseItem()
            } else if isAssistantSceneRootVC() {
                navigationItem.leftBarButtonItem = addCloseItem()
            } else if hasBackPage { // 有回退页，设置返回按钮; 否则维持原有左边按钮
                navigationItem.leftBarButtonItem = backItem ?? addBackItem()
            }
            return
        }

        if !hasBackPage, item == backItem { // 没有回退页，且左边按钮为返回，清空左边按钮
            navigationItem.leftBarButtonItem = nil
        } else if hasBackPage, item != backItem { // 保证返回按钮的DarkMode适配
            navigationItem.leftBarButtonItem = backItem ?? addBackItem()
        }
    }

    /// ios9, 默认不隐藏状态栏
    open override var prefersStatusBarHidden: Bool {
        return false
    }

    private func isRemoved() -> Bool {
        if self.isMovingFromParent {
            if let state = self.navigationController?.interactivePopGestureRecognizer?.state {
                if state == .began || state == .changed { // 滑动返回
                    return false
                }
            }
            return true
        }
        if self.isBeingDismissed {
            return true
        }
        var controller: UIViewController = self
        while let parent = controller.parent {
            if parent.isMovingFromParent {
                return true
            }
            if parent.isBeingDismissed {
                return true
            }
            controller = parent
        }
        return false
    }

    deinit {
        if !self.hasCallonExit {
            self.onExit()
        }
        NotificationCenter.default.removeObserver(self)
        let className = NSStringFromClass(type(of: self))
        BaseUIViewController.baseLogger.debug("deinit " + className)
    }

    open func showLoadingHud() -> (() -> Void) {
        return showLoadingHud(BundleI18n.LarkUIKit.Lark_Legacy_BaseUiLoading)
    }

    open func showLoadingHud(_ title: String) -> (() -> Void) {
        self.view.subviews.forEach { $0.isHidden = true }
        let hud = self.showActivityIndicatiorHUD(title, in: self.view)
        return { [weak self] in
            hud.remove()
            self?.view.subviews.forEach { $0.isHidden = false }
        }
    }

    func showActivityIndicatiorHUD(_ title: String, in view: UIView) -> RoundedHUD {
        return RoundedHUD.showLoading(with: title, on: view, disableUserInteraction: true)
    }

    @available(*, deprecated, message: "Please use LarkVideoDirector.LarkCameraKit.takePhoto")
    open func takePhoto(_ completion: ChooseImageCallback? = nil, cancel: (() -> Void)? = nil) {
        cameraPermissions { [weak self] granted in
            guard let self = self else { return }
            if granted {
                let picker = UIImagePickerController()
                picker.sourceType = .camera
                picker.delegate = self
                self.chooseImageCallback = completion
                self.chooseImageCancelCallback = cancel
                self.present(picker, animated: true, completion: nil)
            } else {
                let dialog = UDDialog.noPermissionDialog(title: BundleI18n.LarkUIKit.Lark_Core_CameraAccess_Title,
                                       detail: BundleI18n.LarkUIKit.Lark_Core_CameraAccessForPhoto_Desc(),
                                       onClickCancel: cancel,
                                       onClickGoToSetting: cancel)
                self.present(dialog, animated: true)
            }
        }
    }

    @available(*, deprecated, message: "Please use LarkVideoDirector.LarkCameraKit.takePhoto")
    open func takePhoto(token: Token, _ completion: ChooseImageCallback? = nil, cancel: (() -> Void)? = nil) throws {
        let context = Context([AtomicInfo.Album.createImagePickerController.rawValue])
        try SensitivityManager.shared.checkToken(token, context: context)
        takePhoto(completion, cancel: cancel)
    }

    func cameraPermissions(completion: @escaping (Bool) -> Void) {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if authStatus == .denied || authStatus == .restricted {
            completion(false)
        } else if authStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            })
        } else {
            completion(true)
        }
    }

    @discardableResult
    open func addBackItem() -> UIBarButtonItem {
        let barItem = LKBarButtonItem(image: Resources.navigation_back_light, title: nil)
        barItem.button.addTarget(self, action: #selector(backItemTapped), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = barItem
        backItem = barItem
        return barItem
    }

    open func resetBackItem(title: String) {
        let backItem = LKBarButtonItem(image: Resources.navigation_back_light, title: title)
        backItem.button.addTarget(self, action: #selector(backItemTapped), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = backItem
        self.backItem = backItem
    }

    @discardableResult
    open func addCloseItem() -> UIBarButtonItem {
        let barItem = LKBarButtonItem(image: Resources.navigation_close_light)
        barItem.button.addTarget(self, action: #selector(closeBtnTapped), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = barItem
        return barItem
    }

    @discardableResult
    open func addCancelItem() -> UIBarButtonItem {
        let barItem = LKBarButtonItem(title: BundleI18n.LarkUIKit.Lark_Legacy_Cancel)
        barItem.button.addTarget(self, action: #selector(closeBtnTapped), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = barItem
        return barItem
    }

    open func showAlert(title: String, message: String, handler: ((UIAlertAction) -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: BundleI18n.LarkUIKit.Lark_Legacy_Sure, style: .default, handler: handler)
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }

    open func showAlert(
        title: String,
        message: String,
        sureHandler: ((UIAlertAction) -> Void)?,
        cancelHandler: ((UIAlertAction) -> Void)?
    ) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: BundleI18n.LarkUIKit.Lark_Legacy_Sure, style: .default, handler: sureHandler)
        let cancelAction = UIAlertAction(title: BundleI18n.LarkUIKit.Lark_Legacy_Cancel, style: .default, handler: cancelHandler)
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }

    @available(*, deprecated, message: "Parse use LarkAlertController")
    open func showFlexibleAlert(
        textAlignment: NSTextAlignment = .left,
        title: String?,
        message: String?,
        leftTitle: String? = nil,
        leftHandler: ((UIAlertAction) -> Void)? = nil,
        rightTitle: String? = nil,
        rightHandler: ((UIAlertAction) -> Void)? = nil
    ) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        // 不择手段呀!
        let messageLabel = alertController.view
            .subviews.first?
            .subviews.first?
            .subviews.first?
            .subviews.first?
            .subviews.first?
            .subviews[1] as? UILabel
        messageLabel?.textAlignment = textAlignment
        if let leftTitle = leftTitle {
            let leftAction = UIAlertAction(title: leftTitle, style: .default, handler: leftHandler)
            alertController.addAction(leftAction)
        }
        if let rightTitle = rightTitle {
            let rightAction = UIAlertAction(title: rightTitle, style: .default, handler: rightHandler)
            alertController.addAction(rightAction)
        }
        self.present(alertController, animated: true)
    }

    private func isAssistantSceneRootVC() -> Bool {
        guard #available(iOS 13.0, *) else {
            return false
        }
        if let scene = self.currentScene(),
           let window = scene.rootWindow(),
           !scene.sceneInfo.isMainScene(),
           window.rootViewController == self.navigationController,
           (self.navigationController?.realViewControllers.first == self ||
            self.navigationController?.realViewControllers.first == self.parent) {
            return true
        }
        return false
    }

    private func closeCurrentScene() {
        SceneManager.shared.deactive(from: self)
    }
}

extension BaseUIViewController {
    @objc
    open func closeBtnTapped() {
        if self.isAssistantSceneRootVC() {
            closeCurrentScene()
        } else {
            self.dismiss(animated: true, completion: { [weak self] in
                self?.closeCallback?()
            })
        }
    }

    @objc
    open func backItemTapped() {
        self.backCallback?()
        self.navigationController?.popViewController(animated: true)
    }
}

extension BaseUIViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        var targetImage: UIImage?
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            targetImage = image
        } else if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            targetImage = image
        }
        if targetImage != nil {
            self.chooseImageCallback?(targetImage!, targetImage!.lu.defaultResize(), picker)
        } else {
            // https://bits.bytedance.net/meego/larksuite/issue/detail/209915#detail
            // 当开启闪光灯拍照过程中推到后台，再进入前台，选择「使用照片」会卡死，Debug发现此时取到的targetImage是nil(没有editedImage与originalImage，猜测是拍照被中断)
            // 兜底处理为回调cancel方法(因为此处获取不到更多其他时机来兜底处理)
            imagePickerControllerDidCancel(picker)
        }
    }

    open func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: {
            self.chooseImageCancelCallback?()
            self.chooseImageCancelCallback = nil
        })
    }
}

extension BaseUIViewController {
    private func createAvoidKeyboardBottom() -> ConstraintRelatableTarget {
        // 创建布局对象
        let guide = UILayoutGuide()
        self.view.addLayoutGuide(guide)
        guide.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }

        // iPad 键盘类型太多(浮动键盘、分离键盘、普通键盘)，且VC状态不同（全屏、半屏、悬浮）需要单独处理，目前先处理iPhone
        if Display.pad {
            return guide.snp.top
        }

        // 添加键盘显示消失事件监听
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillChangeFrameNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (notification) in
                if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    self?.updateAvoidKeyboardBottom(guide, with: frame)
                }
            }).disposed(by: disposeBag)

        return guide.snp.top
    }

    /// 更新布局对象的layout
    private func updateAvoidKeyboardBottom(_ guide: UILayoutGuide, with keyboardFrame: CGRect) {
        let offset = keyboardFrame.minY - UIScreen.main.bounds.height

        guide.snp.remakeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            if offset < 0 {
                maker.top.equalTo(self.view.snp.bottom).offset(offset)
            } else {
                maker.top.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            }
            maker.bottom.equalToSuperview()
        }

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
}
