//
//  WPHomeRootVC.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/12/16.
//
// swiftlint:disable file_length

import UIKit
import SnapKit
import RxSwift
import RxRelay
import Swinject
import EENavigator
import LarkOPInterface
import LarkTab
import LarkUIKit
import LarkSetting
import LarkContainer
import LarkNavigation
import LarkNavigator
import LarkLocalizations
import UniverseDesignDialog
import UniverseDesignToast
import LarkAccountInterface
import LKCommonsLogging

enum WPPortalChangeType: Int {
    case expired = 1
    case update = 2
}

enum WPPortalLoadFrom: Int {
    // enum case 名不应带下划线
    // swiftlint:disable identifier_name
    case cold_boot = 1
    case switch_portal = 2
    case portal_update = 3
    case portal_expired = 4
    case portal_appear = 5
    // swiftlint:enable identifier_name
}

enum WPLoadPortalErrorCode: Int {
    // enum case 名不应带下划线
    // swiftlint:disable identifier_name
    case request_fail = 1
    case empty_portal_list = 2
    case create_vc_fail = 3
    // swiftlint:enable identifier_name
}

final class WPHomeRootVC: WPBaseViewController {
    static let logger = Logger.log(WPHomeRootVC.self)

    // MARK: - private vars
    private lazy var disposeBag: DisposeBag = { DisposeBag() }()

    let context: WorkplaceContext
    private let navigationService: NavigationService
    private let rootDataManager: WPRootDataMgr
    private let badgeServiceContainer: WPBadgeServiceContainer
    private let dependency: WPDependency

    /// 当前展示的门户容器
    private(set) var currentContainerVC: WPHomeContainerVC?
    /// 当前加载的门户
    private var currentPortal: WPPortal?
    /// 下次进入工作台需要加载的门户（更新弹窗提示被用户「暂不升级」的门户，下次进工作台直接加载）
    private var pendingPortal: WPPortal?

    /// 是否支持使用内存中的数据来加载工作台
    private var enableUseDataFromMemory: Bool {
        return context.configService.fgValue(for: .enableUseDataFromMemory, realTime: true)
    }

    /// 网络异常状态栏 / 网络诊断入口
    lazy var netDiagnoseBar: WPNetDiagnoseBar = {
        return WPNetDiagnoseBar(
            dependency: dependency,
            configService: context.configService,
            pushCenter: context.userPushCenter
        )
    }()
    /// 网络异常状态栏-顶部&底部约束
    private(set) var netDiagnoseTopConstraint: Constraint?
    private(set) var netDiagnoseBottomConstraint: Constraint?

    // MARK: - public vars

    lazy var tracker: WPHomeTracker = { WPHomeTracker() }()

    let wpFirstScreenDataReady: BehaviorRelay<Bool> = BehaviorRelay(value: false)

    /// 门户切换列表视图
    lazy var portalMenuView: WPPortalListMenuView = {
        let vi = WPPortalListMenuView(frame: .zero)
        vi.delegate = self
        return vi
    }()

    private var hasCache: Bool = false

    // MARK: - life cycle

    init(
        context: WorkplaceContext,
        navigationService: NavigationService,
        rootDataManager: WPRootDataMgr,
        badgeServiceContainer: WPBadgeServiceContainer,
        dependency: WPDependency
    ) {
        self.context = context
        self.navigationService = navigationService
        self.rootDataManager = rootDataManager
        self.badgeServiceContainer = badgeServiceContainer
        self.dependency = dependency
        super.init(nibName: nil, bundle: nil)

        self.hasCache = rootDataManager.checkHasCache()
        monitorLaunchStart()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        subviewsInit()
        subscribeTabSwitch()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 门户第一个子视图的顶部至少应低于导航栏
        let containerTopInset = max(topNavH, topContainer.frame.height)
        currentContainerVC?.topInsetDidChanged(height: containerTopInset)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        if currentPortal == nil {
            dataInit()
        } else {
            dataUpdate(showLoading: false, portalLoadFrom: .portal_appear)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        switchPortalListMenuVisibility(visiable: false)
    }

    // MARK: - public funcs
    func switchPortalListMenuVisibility(visiable: Bool? = nil) {
        // 按指定参数设置，或者 toggle 可见性
        let showMenu = visiable ?? portalMenuView.isHidden
        Self.logger.info(
            "[portal] menu list switch hidden: \(showMenu), param: \(String(describing: visiable))"
        )
        if showMenu {
            guard portalMenuView.portalList.count > 1 else {
                // 如果门户 <= 1，不展示切换菜单
                Self.logger.info("[portal] list count <= 1, not show menu")
                return
            }
            // 展示切换菜单
            portalMenuView.isHidden = false
            changeTitleArrowPresentation(folded: false, animated: true)
        } else {
            // 隐藏切换菜单
            portalMenuView.isHidden = true
            changeTitleArrowPresentation(folded: true, animated: true)
        }
    }

    // MARK: - private funcs

    private func subviewsInit() {
        view.backgroundColor = UIColor.ud.bgBody

        netDiagnoseBar.delegate = self
        netDiagnoseBar.isHidden = true
        portalMenuView.isHidden = true
        topContainer.addSubview(netDiagnoseBar)
        view.addSubview(portalMenuView)

        netDiagnoseBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            netDiagnoseTopConstraint = make.top.equalToSuperview().offset(topNavH).constraint
            netDiagnoseBottomConstraint = make.bottom.equalToSuperview().constraint
        }
        // 默认情况下网络诊断栏不显示
        netDiagnoseTopConstraint?.deactivate()
        netDiagnoseBottomConstraint?.deactivate()

        portalMenuView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(self.topNavH)
            make.left.right.bottom.equalToSuperview()
        }
    }

    /// 数据初始化
    /// 如果支持使用内存中的数据来加载，并且内存中有门户数据，则用内存数据加载，再获取远端数据
    /// 否则先加载缓存，再获取远端数据
    private func dataInit() {
        Self.logger.info("[portal]data init", additionalData: [
            "enableUseDataFromMemory": "\(enableUseDataFromMemory)",
            "hasDataInMemory": "\(rootDataManager.currentPortal != nil)"
        ])
        stateView.state = .loading
        if enableUseDataFromMemory,
           let currentPortal = rootDataManager.currentPortal {
            /// 使用内存中的数据来加载门户
            Self.logger.info("[portal]read portal data from memory")
            stateView.state = .hidden
            hasCache = true
            loadPortal(currentPortal, portalLoadFrom: .cold_boot)
            dataUpdate(showLoading: false, portalLoadFrom: .cold_boot)
        } else {
            rootDataManager.fetchLastPortal(completion: { cache in
                if let cachePortal = cache {
                    self.stateView.state = .hidden
                    // 有缓存，先加载上次的门户
                    self.loadPortal(
                        cachePortal,
                        portalLoadFrom: .cold_boot
                    )
                }
                self.dataUpdate(showLoading: (cache == nil), portalLoadFrom: .cold_boot)
            })
        }
    }

    /// 数据刷新（直接获取远端数据）
    /// - Parameter showLoading: 是否显示 loading
    private func dataUpdate(showLoading: Bool, portalLoadFrom: WPPortalLoadFrom, isRetry: Bool = false) {
        if showLoading {
            stateView.state = .loading
        }
        // swiftlint:disable closure_body_length
        rootDataManager.fetchHomePortals { [weak self] result in
            guard let self = self else {
                Self.logger.warn("dataUpdate get response, but self released")
                return
            }
            switch result {
            case .success(let portals):
                if showLoading {
                    self.stateView.state = .hidden
                }
                self.updatePortalList(portals, portalLoadFrom: portalLoadFrom, isRetry: isRetry)
            case .failure:
                if self.currentPortal != nil {
                    // 如果当前有加载中的门户，不显示 Fail
                    self.stateView.state = .hidden
                } else {
                    self.monitorWorkplaceShowFail(isRetry: isRetry, errorCode: .request_fail)
                    switch self.stateView.state {
                    case .loadFail:
                        break
                    default:
                        self.stateView.state = .loadFail(
                            .create(
                                monitorCode: WPMCode.workplace_show_fail,
                                showReloadBtn: true,
                                action: { [weak self] in
                                    Self.logger.info("[portal] retry fetch remote data")
                                    self?.dataUpdate(
                                        showLoading: true,
                                        portalLoadFrom: portalLoadFrom,
                                        isRetry: true
                                    )
                                }
                            )
                        )
                    }
                }
            }
        }
        // swiftlint:enable closure_body_length
    }

    /// 更新门户列表
    /// - Parameter list: protal 列表
    private func updatePortalList(_ list: [WPPortal], portalLoadFrom: WPPortalLoadFrom, isRetry: Bool = false) {
        guard !list.isEmpty else {
            Self.logger.error("[portal] load empty portal list!!")
            monitorWorkplaceShowFail(isRetry: isRetry, errorCode: .empty_portal_list)
            assertionFailure()
            return
        }
        let existIndex = list.firstIndex(where: { currentPortal?.isSameID(with: $0) == true })
        // 在列表中，加载对应的门户；不在列表中，加载第一个
        let selectIndex = existIndex ?? 0
        Self.logger.info("[portal] list update, select: \(String(describing: existIndex))")
        // 更新门户列表，刷新导航栏样式（如门户列表下拉的箭头等）
        portalMenuView.updateData(list, selectedIndex: selectIndex)
        reloadNaviBar()
        let portal = list[selectIndex]
        guard let prePortal = currentPortal else {
            // 之前没有加载门户（缓存），直接加载
            Self.logger.info("[portal] load new portal")
            loadPortal(portal, portalLoadFrom: portalLoadFrom, isRetry: isRetry)
            return
        }
        if portal.isSameID(with: prePortal) {
            // 是同一个门户
            if portal == prePortal {
                // 门户内容完全一致：走 child 自己的刷新逻辑，容器不用替换，do nothing
                Self.logger.info("[portal] content not change")
            } else if portal.isSameCoreData(with: prePortal) {
                // 门户核心数据一致，但是其它数据不完全一致（如修改了门户标题、lowCode 模板文件链接等）
                // 更新下门户信息，无需重新加载
                Self.logger.info("[portal] content update")
                updatePortal(portal)
            } else {
                // 门户内容变化：弹窗提示门户内容有更新
                Self.logger.info("[portal] show portal update alert")
                monitorPortalChange(newPortal: portal, originPortal: prePortal, changeType: .update)
                showPortalUpdateAlert(portal: portal)
            }
        } else {
            // 不是同一个门户（当前加载的门户不在了）
            // 因模版化工作台停用or减小可用范围，使从模版化切换到其它门户，
            // 将不再弹窗提示"工作台已停用"/“工作台有更新”，而是立即更新
            // 注：H5 工作台属于模版化工作台的一种。
            switch prePortal.type {
            case .lowCode, .web:
                loadPortal(portal, portalLoadFrom: .portal_expired)
            case .normal:
                showPortalUpdateAlert(portal: portal)
            }
            monitorPortalChange(newPortal: portal, originPortal: prePortal, changeType: .expired)
        }
    }

    /// 加载指定的门户 方法过长，注意精简
    /// - Parameter portal: 客户端构建的「门户」抽象数据结构
    private func loadPortal(
        _ portal: WPPortal,
        portalLoadFrom: WPPortalLoadFrom,
        isRetry: Bool = false,
        path: String? = nil,
        queryItems: [URLQueryItem]? = nil
    ) {
        Self.logger.info("[portal] portal load start: \(portal)")

        let preProtal = currentPortal
        currentPortal = portal
        rootDataManager.updateCurrentPortal(portal)

        // reload badge
        badgeServiceContainer.reload(to: portal.badgeLoadType)
        rootDataManager.cacheLastPortal(portal)

        var vc: WPHomeContainerVC?
        switch portal.type {
        case .normal:
            if let data = WPHomeVCInitData.Normal(portal) {
                monitorWorkpalceShowPortal(isRetry: isRetry, portal: portal, triggerFrom: portalLoadFrom)
                let body = WorkplaceNativeBody(initData: data, rootDelegate: self)
                vc = context.navigator.response(for: body).resource as? WPHomeContainerVC
            } else {
                monitorWorkplaceShowFail(isRetry: isRetry, errorCode: .create_vc_fail)
            }
        case .lowCode:
            if let data = WPHomeVCInitData.LowCode(portal) {
                var firstLoadByCache = true
                if let preProtal = preProtal, !portal.isSameCoreData(with: preProtal) {
                    // 由于当前protal和要刷新的protal不一致，故需要直接刷新，
                    // 不再获取缓存，解决block加载两次的闪动问题
                    firstLoadByCache = false
                }
                monitorWorkpalceShowPortal(isRetry: isRetry, portal: portal, triggerFrom: portalLoadFrom)
                // 由于「firstLoadByCache」使用时机很靠前，只能在init时就注入
                let body = WorkplaceTemplateBody(
                    rootDelegate: self, initData: data, firstLoadCache: firstLoadByCache
                )
                vc = context.navigator.response(for: body).resource as? WPHomeContainerVC
            } else {
                monitorWorkplaceShowFail(isRetry: isRetry, errorCode: .create_vc_fail)
            }
        case .web:
            if let data = WPHomeVCInitData.Web(portal) {
                monitorWorkpalceShowPortal(isRetry: isRetry, portal: portal, triggerFrom: portalLoadFrom)
                let body = WorkplaceWebBody(
                    rootDelegate: self, initData: data, path: path, queryItems: queryItems
                )
                vc = context.navigator.response(for: body).resource as? WPHomeContainerVC
            } else {
                monitorWorkplaceShowFail(isRetry: isRetry, errorCode: .create_vc_fail)
            }
        }

        guard let vc = vc else {
            Self.logger.error("[portal] load invalid portal data: \(portal)")
            switch self.stateView.state {
            case .loadFail:
                break
            default:
                stateView.state = .loadFail(
                    .create(
                        monitorCode: WPMCode.workplace_show_fail,
                        showReloadBtn: true,
                        action: { [weak self] in
                            self?.dataUpdate(showLoading: true, portalLoadFrom: portalLoadFrom, isRetry: isRetry)
                        }
                    )
                )
            }
            assertionFailure()
            return
        }

        if let current = currentContainerVC {
            current.removeFromParent()
            current.view.removeFromSuperview()
        }

        addChild(vc)
        view.insertSubview(vc.view, belowSubview: stateView)
        view.bringSubviewToFront(stateView)
        view.bringSubviewToFront(topContainer)
        view.bringSubviewToFront(portalMenuView)

        vc.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        currentContainerVC = vc
        netDiagnoseBar.containerType = portal.type

        if let nav = naviBar, nav.isDescendant(of: view) {
            view.bringSubviewToFront(nav)
        }

        reloadNaviBar()
    }

    /// 更新门户信息
    /// - Parameter portal: 客户端构建的「门户」抽象数据结构
    private func updatePortal(_ portal: WPPortal) {
        guard let data = WPHomeVCInitData(portal) else {
            Self.logger.error("[portal] update invalid init data")
            assertionFailure()
            return
        }
        currentContainerVC?.updateInitData(data)
    }

    // MARK: - private funcs handle tap-switch
    /// 订阅 tab 的切换事件
    private func subscribeTabSwitch() {
        navigationService.tabDriver.drive { [weak self] (oldTab, newTab) in
            Self.logger.info("[portal] tab changed", additionalData: [
                "hasSelf": "\(self != nil)",
                "oldTab": "\(oldTab?.urlString ?? "")",
                "newTab": "\(newTab?.urlString ?? "")",
                "hasPendingPortal": "\(self?.pendingPortal != nil)"
            ])
            guard let old = oldTab, let new = newTab else { return }
            // 当通过 tab 切出 appCenter 时，静默更新
            if let pendingPortal = self?.pendingPortal,
                old == .appCenter, new != .appCenter {
                self?.loadPortal(pendingPortal, portalLoadFrom: .portal_update)
                self?.pendingPortal = nil
            }
        }.disposed(by: disposeBag)
    }

    // MARK: - private funcs update-alerts
    /// 展示弹窗
    /// - Parameter portal: 客户端构建的「门户」抽象数据结构
    private func showPortalUpdateAlert(portal: WPPortal) {
        switch portal.type {
        case .lowCode:
            Self.logger.info("[portal] lowCode workplace update")
            showCustomPortalUpdateAlert(portal: portal)
        case .normal, .web:
            Self.logger.info("[portal] normal / web workplace update")
            showStaticPortalUpdateAlert(portal: portal)
        }
    }

    /// 展示自定义更新提示弹窗 方法过长，注意优化
    /// - Parameter portal: 客户端构建的「门户」抽象数据结构
    private func showCustomPortalUpdateAlert(portal: WPPortal) {
        Self.logger.info(
            "[portal] showCustomPortalUpdateAlert",
            additionalData: [
                "isVisible": "\(isVisible())",
                "updateInfo.isNil": "\(portal.template?.updateInfo == nil)",
                "updateType": portal.template?.updateInfo?.updateType.rawValue ?? "nil",
                "updateTitle": portal.template?.updateInfo?.updateTitle ?? "nil",
                "updateRemark": portal.template?.updateInfo?.updateRemark ?? "nil"
            ]
        )
        guard isVisible() else {
            // 工作台页面不可见
            return
        }
        guard let updateInfo = portal.template?.updateInfo else {
            // 解析失败 -> 静默更新
            self.pendingPortal = portal
            return
        }
        if updateInfo.updateType == .silent {
            // 静默更新
            self.pendingPortal = portal
            return
        }
        let dialog = UDDialog()
        guard !updateInfo.updateTitle.isEmpty, !updateInfo.updateRemark.isEmpty else {
            // 静默更新
            self.pendingPortal = portal
            return
        }
        dialog.setTitle(text: updateInfo.updateTitle)
        dialog.setContent(view: buildContentView(text: updateInfo.updateRemark))
        switch updateInfo.updateType {
        case .force:
            dialog.addPrimaryButton(
                text: BundleI18n.LarkWorkplace.OpenPlatform_Workplace_UpdateNowBttn,
                dismissCompletion:  { [weak self] in
                    Self.logger.info("[portal] force update(now), \(self == nil)")
                    self?.context.tracker
                        .start(.openplatform_workspace_main_page_update_click)
                        .setClickValue(.update_now)             // 立即更新
                        .setTargetView(.none)                   // 该动作发生后到达的目标页面
                        .setValue("new", for: .version)         // 新工作台
                        .setUpdateType(.force)
                        .post()
                    self?.loadPortal(portal, portalLoadFrom: .portal_update)
                })
        case .prompt:
            dialog.addSecondaryButton(
                text: BundleI18n.LarkWorkplace.OpenPlatform_Workplace_NewUpdatesLaterBttn,
                dismissCompletion:  { [weak self] in
                    Self.logger.info("[portal] prompt update(later), \(self == nil)")
                    self?.context.tracker
                        .start(.openplatform_workspace_main_page_update_click)
                        .setClickValue(.update_next_time)           // 下次更新
                        .setTargetView(.none)                       // 该动作发生后到达的目标页面
                        .setUpdateType(.prompt)
                        .setValue("new", for: .version)             // 新工作台
                        .post()
                    self?.pendingPortal = portal
                })
            dialog.addPrimaryButton(
                text: BundleI18n.LarkWorkplace.OpenPlatform_Workplace_UpdateNowBttn,
                dismissCompletion:  { [weak self] in
                    Self.logger.info("[portal] prompt update(now), \(self == nil)")
                    self?.context.tracker
                        .start(.openplatform_workspace_main_page_update_click)
                        .setClickValue(.update_now)                 // 立即更新
                        .setTargetView(.none)                       // 该动作发生后到达的目标页面
                        .setUpdateType(.prompt)
                        .setValue("new", for: .version)             // 新工作台
                        .post()
                    self?.loadPortal(portal, portalLoadFrom: .portal_update)
                })
        case .silent:
            assert(false)
            Self.logger.error("[portal] should not be here! try updating silently")
        }
        self.present(dialog, animated: true) { [weak self] in
            self?.context.tracker
                .start(.openplatform_workspace_main_page_update_view)
                .setValue("new", for: .version)
                .setUpdateType(updateInfo.updateType)
                .post()
        }
    }

    /// 构建 dialog contentView
    /// - Parameter text: 文案
    /// - Returns: contentView
    private func buildContentView(text: String) -> UIView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.textContainer.lineFragmentPadding = 0
        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = true
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6.0
        paragraphStyle.alignment = .center
        var attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.ud.body2,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.ud.textTitle
        ]
        textView.attributedText = NSAttributedString(string: text, attributes: attributes)
        // UDDialog 中  UIEdgeInsets(top: 16, left: 20, bottom: 18, right: 20)
        // paragraphStyle = UDDialog 的宽度 - 2*contentSize的水平边距
        let textViewWidth = UDDialog.Layout.dialogWidth - 2 * 20
        let contentSize = textView.sizeThatFits(
            CGSize(
                width: textViewWidth,
                height: CGFloat.infinity
            )
        )
        // 尽量避免强解包
        // swiftlint:disable force_unwrapping
        let fontHeight = textView.font!.lineHeight
        // swiftlint:enable force_unwrapping
        let textSize = text.boundingRect(
            with: contentSize,
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
        ).size
        let lineNumber = lroundf(Float(textSize.height) / Float(fontHeight + 6.0))
        if lineNumber > 2 {
            paragraphStyle.alignment = .left
            attributes[.paragraphStyle] = paragraphStyle
            textView.attributedText = NSAttributedString(string: text, attributes: attributes)
        }
        let contentView = UIView()
        contentView.addSubview(textView)
        textView.snp.makeConstraints { make in
            // 绑定边界约束，得以将内部宽高的约束传递到外层，撑开 dialog 的 contentView
            make.edges.equalToSuperview()
            // 指定高度约束，宽度在 UDDialog 中已经确定
            make.height.equalTo(ceil(contentSize.height)).priority(.low)
        }
        return contentView
    }

    /// 展示静态更新提示弹窗 - 工作台有更新
    /// - Parameter portal: portal
    private func showStaticPortalUpdateAlert(portal: WPPortal) {
        Self.logger.info("[portal] show portal update alert")
        let alert = UIAlertController(
            title: BundleI18n.LarkWorkplace.OpenPlatform_Workplace_NewUpdatesTtl,
            message: BundleI18n.LarkWorkplace.OpenPlatform_Workplace_NewUpdatesMsg,
            preferredStyle: .alert
        )
        let notUpdate = BundleI18n.LarkWorkplace.OpenPlatform_Workplace_NewUpdatesLaterBttn
        let action1 = UIAlertAction(title: notUpdate, style: .default) { [weak self] (_) in
            Self.logger.info(
                "[portal] portal update alert action: update later, self==nil: \(self == nil)."
            )
            self?.pendingPortal = portal
        }
        let nowUpdate = BundleI18n.LarkWorkplace.OpenPlatform_Workplace_UpdateNowBttn
        let action2 = UIAlertAction(title: nowUpdate, style: .cancel) { [weak self] (_) in
            Self.logger.info(
                "[portal] portal update alert action: update now, self==nil: \(self == nil)."
            )
            self?.loadPortal(portal, portalLoadFrom: .portal_update)
        }
        alert.addAction(action1)
        alert.addAction(action2)
        self.present(alert, animated: true)
    }

    /// 展示静态更新提示弹窗 - 工作台已停用
    /// - Parameter availablePortal: portal
    private func showPortalExpiredAlert(availablePortal: WPPortal) {
        Self.logger.info("[portal] show portal expire alert")
        let alert = UIAlertController(
            title: BundleI18n.LarkWorkplace.OpenPlatform_WebPortal_DiscontinuedPortal,
            message: BundleI18n.LarkWorkplace.OpenPlatform_WebPortal_DiscontinuedPortalSwitch,
            preferredStyle: .alert
        )
        let title = BundleI18n.LarkWorkplace.OpenPlatform_WebPortal_GotItBttn
        let confirmAction = UIAlertAction(title: title, style: .default) { [weak self] (_) in
            Self.logger.info(
                "[portal] portal expire action: confirm, self==nil: \(self == nil)."
            )
            self?.loadPortal(availablePortal, portalLoadFrom: .portal_expired)
        }
        alert.addAction(confirmAction)
        self.present(alert, animated: true)
    }

    /// 当前 VC 是否可见
    /// - Returns: 可见性
    private func isVisible() -> Bool {
        return self.viewIfLoaded?.window != nil
    }
}

extension WPHomeRootVC: WPPortalListMenuViewDelegate {
    func menuView(_ menuView: WPPortalListMenuView, didSelectItem item: WPPortal?) {
        switchPortalListMenuVisibility()
        
        guard let portal = item else {
            Self.logger.info("[portal] list select cancel")
            return
        }
        Self.logger.info("[portal] select new portal: \(String(describing: item))")
        loadPortal(portal, portalLoadFrom: .switch_portal)
        // 这里重新刷新下门户列表，防止现有的门户已经被下线了
        dataUpdate(showLoading: true, portalLoadFrom: .switch_portal)
    }
    
    func menuView(
        _ menuView: WPPortalListMenuView,
        didChangeItem item: WPPortal?,
        path: String?,
        queryItems: [URLQueryItem]?
    ) {
        guard let portal = item else {
            Self.logger.info("[portal] cancel list change")
            return
        }
        Self.logger.info("[portal] automatically change to new portal", additionalData: [
            "id": item?.template?.id ?? ""
        ])
        loadPortal(
            portal,
            portalLoadFrom: .switch_portal,
            path: path,
            queryItems: queryItems
        )
    }
}

/// 埋点
extension WPHomeRootVC {

    private func monitorPortalChange(newPortal: WPPortal, originPortal: WPPortal, changeType: WPPortalChangeType) {
        context.monitor
            .start(.workplace_portal_change_result)
            .setPortalChange(originPortal: originPortal, newPortal: newPortal, changeType: changeType)
            .flush()
    }

    private func monitorLaunchStart() {
        context.monitor
            .start(.workplace_launch_start)
            .setValue(hasCache, for: .has_cache)
            .flush()
    }

    private func monitorWorkpalceShowPortal(isRetry: Bool, portal: WPPortal, triggerFrom: WPPortalLoadFrom) {
        context.monitor
            .start(.workplace_show_portal)
            .setValue(hasCache, for: .has_cache)
            .setValue(isRetry, for: .is_retry)
            .setPortalType(portal.type)
            .setPortalTriggerFrom(triggerFrom)
            .setValue(portal.template?.id, for: .portal_id)
            .flush()
    }

    private func monitorWorkplaceShowFail(isRetry: Bool, errorCode: WPLoadPortalErrorCode) {
        context.monitor
            .start(.workplace_show_fail)
            .setValue(hasCache, for: .has_cache)
            .setErrorCode(errorCode.rawValue)
            .setValue(isRetry, for: .is_retry)
            .flush()
    }
}

// MARK: - applink handler
extension WPHomeRootVC {
    func handleApplinkRoute(
        portalId: String?,
        path: String?,
        queryItems: [URLQueryItem]?
    ) {
        Self.logger.info("[wp] start handle app link route in home vc")
        let toastHolder: UIView = context.navigator.mainSceneWindow ?? view

        context.monitor
            .start(.workplace_handle_applink_start)
            .setValue(portalId, for: .id)
            .flush()
        
        guard let id = portalId, !id.isEmpty else {
            // 有其他query参数，但是没有id，则提示未配置id参数
            UDToast.showFailure(
                with: BundleI18n.LarkWorkplace.OpenPlatform_WpApplink_RedirectFailedErr, on: toastHolder
            )
            context.monitor
                .start(.workplace_handle_applink_fail)
                .setValue(portalId, for: .id)
                .setValue("1", for: .error_type)
                .flush()
            return
        }
        
        if let foundPortal = self.findSelectPortal(id, in: self.portalMenuView.portalList) {
            // 门户列表里已经有指定的门户
            Self.logger.info("[wp] handleApplinkRoute, find [ortal in current list")
            switchPortalIfNeeded(
                foundPortal: foundPortal,
                path: path,
                queryItems: queryItems
            )
            return
        }
        
        // swiftlint:disable closure_body_length
        rootDataManager.fetchHomePortals { [weak self] result in
            guard let self = self else {
                Self.logger.error("[wp] handleApplinkRoute, fetch handler fail, self is nil")
                return
            }
            switch result {
            case .success(let portals):
                if let foundPortal = self.findSelectPortal(id, in: portals),
                   let index = portals.firstIndex(of: foundPortal){
                    // 从后端获取到指定的门户，先更新门户列表，再加载门户
                    Self.logger.info("[wp] handleApplinkRoute, fetch success, found portal")
                    self.portalMenuView.updateData(portals, selectedIndex: index)
                    self.switchPortalIfNeeded(
                        foundPortal: foundPortal,
                        path: path,
                        queryItems: queryItems
                    )
                    return
                }

                // 没有找到指定的门户，提示id不合法
                // 包括id不存在、id非当前租户；未拉取到工作台id
                UDToast.showFailure(
                    with: BundleI18n.LarkWorkplace.OpenPlatform_WpApplink_LaunchFailedErr1, on: toastHolder
                )
                self.context.monitor
                    .start(.workplace_handle_applink_fail)
                    .setValue(id, for: .id)
                    .setValue("2", for: .error_type)
                    .flush()
                return
            case .failure:
                // 提示工作台请求失败
                UDToast.showFailure(
                    with: BundleI18n.LarkWorkplace.OpenPlatform_WpApplink_RequestFailedErr, on: toastHolder
                )
                self.context.monitor
                    .start(.workplace_handle_applink_fail)
                    .setValue(id, for: .id)
                    .setValue("3", for: .error_type)
                    .flush()
            }
        }
        // swiftlint:enable closure_body_length
    }
    
    private func switchPortalIfNeeded(
        foundPortal: WPPortal,
        path: String?,
        queryItems: [URLQueryItem]?
    ) {
        guard let foundPortalId = foundPortal.template?.id else {
            assertionFailure("[wp] switch portal id not exist")
            return
        }
        context.monitor
            .start(.workplace_handle_applink_success)
            .setValue(foundPortalId, for: .id)
            .flush()
        
        if foundPortalId == currentPortal?.template?.id {
            if foundPortal.type == .lowCode || path == nil || path.isEmpty {
                Self.logger.info("[wp] current portal is applink portal", additionalData: [
                    "portal_type": foundPortal.type.rawValue,
                    "portal_id": foundPortalId
                ])
                return
            }
            // isContentLoaded判断H5工作台内容是否第一次加载完。如果在加载中，会请求meta、pkg，获取到数据后跳转到首页，获取数据的时间不确定且没有回调时间，这种情况为了保证能跳转到指定的path，走重新加载逻辑
            if let webVC = currentContainerVC as? WPHomeWebVC,
               webVC.isContentLoaded(),
               let urlPath = path {
                webVC.loadURL(with: urlPath, queryItems: queryItems)
                return
            }
        }
        
        portalMenuView.selectPortal(
            foundPortal,
            path: path,
            queryItems: queryItems
        )
    }
    
    private func findSelectPortal(
        _ portalId: String,
        in list: [WPPortal]
    ) -> WPPortal? {
        return list.first(where: {
            $0.template?.id == portalId
        })
    }
}
// swiftlint:enable file_length
