//
//  SearchPickerViewController.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/2/23.
//

import UIKit
import RxSwift
import LarkSDKInterface
import LarkModel
import LarkUIKit
import LarkContainer
import LarkAccountInterface
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignButton

final public class SearchPickerViewController: UIViewController, SearchPickerControllerType {
    public weak var pickerDelegate: SearchPickerDelegate? {
        didSet {
            self.controller.delegate = pickerDelegate
        }
    }
    // MARK: - Service
    let tracker = PickerTracker()
    let router: PickerRouter
    let controller: SearchPickerController

    var context: PickerContext
    public var featureConfig: PickerFeatureConfig = PickerFeatureConfig() {
        didSet {
            // 大搜样式下, 不支持多选
//            featureConfig?.multiSelection.isOpen = false
            self.context.featureConfig = featureConfig
            tracker.scene = featureConfig.scene.rawValue
        }
    }
    public var defaultView: PickerDefaultViewType? {
        didSet {
            self.controller.defaultView = defaultView
        }
    }
    /// 自定义头部视图, 展示在多选列表上方, 需要在PickerVC调起前设置
    public var headerView: UIView? {
        didSet {
            self.controller.headerView = headerView
        }
    }
    /// 自定义顶部视图, 展示在多选列表下方, 需要在PickerVC调起前设置
    public var topView: UIView? {
        didSet {
            self.controller.topView = topView
        }
    }
    public var searchConfig = PickerSearchConfig() {
        didSet {
            self.controller.searchConfig = searchConfig
        }
    }

    private let userResolver: UserResolver
    private let disposeBag = DisposeBag()
    private lazy var navigationBarStore: PickerNavigationBarStore = {
        return PickerNavigationBarStore(featureConfig: self.featureConfig)
    }()

    weak var ownerVc: SearchPickerControllerType? {
        didSet { self.controller.ownerVc = ownerVc }
    }

    public convenience init(resolver: UserResolver) {
        self.init(resolver: resolver, context: PickerContext())
    }

    public convenience init(userId: String) throws {
        try self.init(userId: userId, context: PickerContext())
    }

    init(resolver: UserResolver, context: PickerContext) {
        self.userResolver = resolver
        self.context = context
        do {
            let userService = try resolver.resolve(assert: PassportUserService.self)
            self.context.tenantId = userService.userTenant.tenantID
            self.context.userId = userService.user.userID
        } catch {
            PickerLogger.shared.error(module: PickerLogger.Module.view, event: "get user service error", parameters: error.localizedDescription)
        }
        self.router = PickerRouter(resolver: userResolver)
        self.router.tracker = tracker
        self.controller = SearchPickerController(resolver: resolver, context: context, router: self.router)
        super.init(nibName: nil, bundle: nil)
        self.ownerVc = self
        self.controller.ownerVc = self
    }

    convenience init(userId: String, context: PickerContext) throws {
        let resolver = try Container.shared.getUserResolver(userID: userId)
        self.init(resolver: resolver, context: context)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        PickerLogger.shared.info(module: PickerLogger.Module.view, event: "SearchPickerViewController deinit")
    }

    private var ownerNavigationBarHidden = false
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if context.style == .search {
            ownerNavigationBarHidden = navigationController?.isNavigationBarHidden ?? false
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if context.style == .search {
            if ownerNavigationBarHidden { return }
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody

        controller.add(to: self)
        self.controller.didClosePickerHandler = { [weak self] in
            self?.closePicker()
        }

        if self.navigationController is SearchPickerNavigationController {
            configNaivationBar()
            self.navigationController?.presentationController?.delegate = self
        }
    }

    public func reload(search: Bool, recommend: Bool) {
        self.controller.reload(search: search, recommend: recommend)
    }

    public func reload() {
        self.reload(search: true, recommend: true)
    }

    // 手动关闭Picker
    func handleClosePicker() {
        if let ownerVc = self.ownerVc,
           let canClose = pickerDelegate?.pickerDidCancel(pickerVc: ownerVc),
           canClose == false {
            return
        }
        closePicker()
    }

    func closePicker() {
        if let nav = ownerVc?.navigationController {
            if nav.viewControllers.first == ownerVc {
                nav.dismiss(animated: true)
            } else {
                nav.popViewController(animated: true)
            }
        } else {
            ownerVc?.dismiss(animated: true)
        }
    }

    // MARK: - Action
    @objc
    func didConfirm() {
        let selected = controller.picker?.selected ?? []
        let items = selected.map {
            return PickerItemFactory.shared.makeItem(option: $0, currentTenantId: context.tenantId)
        }
        guard let ownerVc = self.ownerVc else { return }
        let canClose = pickerDelegate?.pickerDidFinish(pickerVc: ownerVc, items: items) ?? true
        if canClose {
            closePicker()
        }
    }

    @objc
    func onSwitchToMultiSelect() {
        controller.picker?.isMultiple = true
        navigationBarStore.switchToMulti()
        updateNavigationBar()
    }

    @objc
    func onSwitchToSingleSelect() {
        controller.picker?.isMultiple = false
        navigationBarStore.switchToSingle()
        updateNavigationBar()
    }
    @objc
    func closeBtnTapped() {
        handleClosePicker()
    }
    // MARK: - UI
    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(didConfirm), for: .touchUpInside)
        button.setTitleColor(UIColor.ud.primaryContentDefault.withAlphaComponent(0.6), for: .highlighted)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.contentHorizontalAlignment = .right
        return button
    }()
    private lazy var confirmBarItem: UIBarButtonItem = {
        return UIBarButtonItem(customView: self.confirmButton)
    }()
    private lazy var multiBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: BundleI18n.LarkSearchCore.Lark_Legacy_Select, style: .plain, target: self, action: #selector(onSwitchToMultiSelect))
        item.tintColor = UIColor.ud.iconN1
        return item
    }()
    private lazy var cancelBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: BundleI18n.LarkSearchCore.Lark_Legacy_Cancel, style: .plain, target: self, action: #selector(onSwitchToSingleSelect))
        item.tintColor = UIColor.ud.iconN1
        return item
    }()
    private lazy var closeBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem(image: UDIcon.closeSmallOutlined, style: .plain, target: self, action: #selector(closeBtnTapped))
        item.tintColor = UIColor.ud.iconN1
        return item
    }()

    private func configNaivationBar() {
        let appearance = context.featureConfig.navigationBar
        self.navigationController?.navigationBar.backgroundColor = UIColor.ud.bgBody
        configNavigationTitle()
        // right
        if appearance.showSure {
            let rightBarItem = UIBarButtonItem(customView: self.confirmButton)
            self.navigationItem.rightBarButtonItem = rightBarItem
        }
//        barItem.tintColor = UIColor.ud.textTitle
        let sureText = appearance.sureText
        let isSureWithCount = appearance.isSureWithCount
        self.confirmButton.setTitle(sureText, for: .normal)
        updateNavigationBar()
        checkSureButtonEnable(false)

        self.controller.picker?.selectedObservable
            .subscribe(onNext: { [weak self] items in
                guard let self = self else { return }
                self.checkSureButtonEnable(!items.isEmpty)
                var title = sureText
                if isSureWithCount && !items.isEmpty {
                    title = sureText + "(\(items.count))"
                }
                self.confirmButton.setTitle(title, for: .normal)
                self.confirmButton.sizeToFit()
            }).disposed(by: self.disposeBag)
    }

    private func configNavigationTitle() {
        let appearance = context.featureConfig.navigationBar
        if let subtitle = appearance.subtitle, !subtitle.isEmpty {
            self.navigationItem.titleView = SearchPickerNavigationTitleView(title: appearance.title, subtitle: subtitle)
        } else {
            // title
            self.title = appearance.title
            self.navigationItem.titleView?.tintColor = UIColor.ud.textTitle
        }
    }

    private func updateNavigationBar() {
        let store = self.navigationBarStore
        let appearance = context.featureConfig.navigationBar

        // color
        if let closeColor = appearance.closeColor {
            self.closeBarItem.tintColor = closeColor
            self.cancelBarItem.tintColor = closeColor
        }
        if let tintColor = appearance.sureColor {
            confirmButton.setTitleColor(tintColor.withAlphaComponent(0.6), for: .highlighted)
            confirmButton.setTitleColor(tintColor, for: .normal)
        }

        switch store.state.left.style {
        case .cancle:
            self.navigationItem.leftBarButtonItem = self.cancelBarItem
        case .close:
            self.navigationItem.leftBarButtonItem = self.closeBarItem
        default: break
        }
        switch store.state.right.style {
        case .multi:
            self.navigationItem.rightBarButtonItem = self.multiBarItem
        case .sure:
            if appearance.showSure {
                self.navigationItem.rightBarButtonItem = self.confirmBarItem
            }
        default: break
        }
    }

    private func checkSureButtonEnable(_ isEnable: Bool) {
        if !self.context.featureConfig.navigationBar.canSelectEmptyResult {
            self.confirmButton.isEnabled = isEnable
        }
    }
}
extension SearchPickerViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if let ownerVc {
            pickerDelegate?.pickerDidDismiss(pickerVc: ownerVc)
        }
    }
}
