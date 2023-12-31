//
//  BaseViewController.swift
//  ByteViewUI
//
//  Created by kiri on 2023/3/1.
//

import Foundation
import ByteViewCommon
import UniverseDesignColor
import UniverseDesignIcon

open class BaseViewController: UIViewController {
    public static var logger = Logger.ui
    open var logger: Logger { Logger.ui }
    private var isFirstWillAppear: Bool = true
    @RwAtomic
    public private(set) var isFirstDidAppear: Bool = true
    @RwAtomic
    public private(set) var isViewAppeared: Bool = false
    @RwAtomic
    public var isNavigationBarHidden: Bool = false
    @RwAtomic
    public var hidesBackButton: Bool = false {
        didSet {
            if hidesBackButton != oldValue {
                updateBackButton()
            }
        }
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        logger.info("init \(logDescription)")
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        logger.info("init \(logDescription)")
    }

    deinit {
        logger.info("deinit \(logDescription)")
        NotificationCenter.default.removeObserver(self)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        hidesBottomBarWhenPushed = true
        navigationItem.hidesBackButton = true
        view.backgroundColor = UIColor.ud.bgBody
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logger.info("\(logDescription): viewWillAppear, isFirst = \(isFirstWillAppear)")
        updateNavigationBar(animated)
        if isFirstWillAppear {
            isFirstWillAppear = false
            updateBackButton()
            viewWillFirstAppear(animated)
        }
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logger.info("\(logDescription): viewDidAppear, isFirst = \(isFirstDidAppear)")
        UIDependencyManager.dependency?.trackEnterViewController("ByteView.\(self.logDescription)")
        isViewAppeared = true
        if isFirstDidAppear {
            isFirstDidAppear = false
            viewDidFirstAppear(animated)
        }
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        logger.info("\(logDescription): viewWillDisappear")
        isViewAppeared = false
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Logger.ui.info("\(logDescription): viewDidDisappear")
        UIDependencyManager.dependency?.trackLeaveViewController("ByteView.\(self.logDescription)")
    }

    open func viewWillFirstAppear(_ animated: Bool) {}

    open func viewDidFirstAppear(_ animated: Bool) {}

    @objc open func doBack() {
        popOrDismiss(true)
    }

    public final func popOrDismiss(_ animated: Bool) {
        if let nav = self.navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: animated)
        } else {
            self.presentingViewController?.dismiss(animated: animated, completion: nil)
        }
    }

    open var preferredNavigationBarStyle: ByteViewNavigationBarStyle {
        return specializedNavigationBarStyle ?? .light
    }

    open var specializedNavigationBarStyle: ByteViewNavigationBarStyle? {
        didSet {
            updateNavigationBar(false)
            updateBackButton()
        }
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    open override var prefersStatusBarHidden: Bool {
        return false
    }

    open override var shouldAutorotate: Bool {
        return true
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return Display.pad ? .all : .portrait
    }

    private func updateNavigationBar(_ animated: Bool) {
        guard let nav = navigationController, nav == self.parent else {
            return
        }

        nav.setNavigationBarHidden(isNavigationBarHidden, animated: animated)
        nav.vc.updateBarStyle(preferredNavigationBarStyle)
    }

    private func updateBackButton() {
        guard let nav = navigationController, nav == self.parent else {
            return
        }

        if hidesBackButton {
            if navigationItem.leftBarButtonItem?.action == #selector(doBack) {
                navigationItem.leftBarButtonItem = nil
            }
        } else if navigationItem.leftBarButtonItem == nil {
            if nav.viewControllers.count > 1 {
                navigationItem.leftBarButtonItem = createBackButton(isClose: false)
            } else if self.presentingViewController != nil {
                navigationItem.leftBarButtonItem = createBackButton(isClose: true)
            }
        }
    }

    open func createBackButton(isClose: Bool) -> UIBarButtonItem {
        let color = preferredNavigationBarStyle.displayParams.buttonTintColor
        let highlighedColor = preferredNavigationBarStyle.displayParams.buttonHighlightTintColor
        let icon: UDIconType = isClose ? .closeSmallOutlined : .leftOutlined
        let actionButton = UIButton()
        actionButton.setImage(UDIcon.getIconByKey(icon, iconColor: color, size: CGSize(width: 24, height: 24)), for: .normal)
        actionButton.setImage(UDIcon.getIconByKey(icon, iconColor: highlighedColor, size: CGSize(width: 24, height: 24)), for: .highlighted)
        actionButton.addTarget(self, action: #selector(doBack), for: .touchUpInside)
        actionButton.addInteraction(type: .highlight, shape: .roundedRect(CGSize(width: 44, height: 36), 8.0))
        return UIBarButtonItemFactory.create(customView: actionButton, size: CGSize(width: 32, height: 44))
    }

    public private(set) lazy var logDescription = self.description

    /// 设置导航栏的背景色，根据Swift与系统版本分别调用不同的方式
    /// - Parameter bgColor: 导航栏背景色
    public final func setNavigationBarBgColor(_ bgColor: UIColor) {
        specializedNavigationBarStyle = ByteViewNavigationBarStyle.generateCustomStyle(preferredNavigationBarStyle, bgColor: bgColor)
    }

    /// 设置导航栏title字体及颜色
    public final func setNavigationItemTitle(text: String, color: UIColor, font: UIFont = .systemFont(ofSize: 17, weight: .medium)) {
        let titleLabel = UILabel()
        titleLabel.textColor = color
        titleLabel.font = font
        titleLabel.text = text
        navigationItem.titleView = titleLabel
    }
}
