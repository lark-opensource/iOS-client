//
//  MineMainViewController.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2017/4/10.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import LarkFoundation
import SnapKit
import RxSwift
import RxCocoa
import LarkModel
import LKCommonsLogging
import LarkGuide
import LarkGuideUI
import LarkTag
import Reachability
import UniverseDesignToast
import LarkSDKInterface
import LarkNavigation
import LarkExtensions
import UniverseDesignDialog
import EENavigator
import LarkReleaseConfig
import LarkSetting
import LarkAppConfig
import LarkContainer
import RustPB
import UniverseDesignDrawer
import LarkAccountInterface
import LarkFocus
import LarkVersion

extension MineMainViewController {
    enum CellType: Hashable {
        /// my profile
        case profile(UIImage, String)
        /// 钱包
        case wallet(UIImage, String)
        /// 收藏
        case favorite(UIImage, String)
        /// 我的资料
        case accountAndDevice(UIImage, String)
        /// 远端下发的Sidebar
        case remoteSidebar(RustPB.Passport_V1_GetUserSidebarResponse.SidebarInfo)
        /// 系统设置
        case sysSetting(UIImage, String)
        /// 反馈
        case feedback(UIImage, String)
        /// 团队转化
        case teamConversion(UIImage, String)

        public var rawValue: String {
            switch self {
            case .profile: return "profile_detail"
            case .wallet: return "wallet"
            case .favorite: return "favorite"
            case .accountAndDevice: return "accountAndDevice"
            case .remoteSidebar(let bar): return "remoteSidebar_\(bar.sidebarType.rawValue)"
            case .sysSetting: return "sysSetting"
            case .feedback: return "feedback"
            case .teamConversion: return "teamConversion"
            }
        }

        public static func == (lhs: CellType, rhs: CellType) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }

        public func hash(into hasher: inout Hasher) {
          hasher.combine(rawValue)
        }
    }
}

final class MineMainViewController: BaseUIViewController, SideBarAbility, UITableViewDataSource, UITableViewDelegate {

    private static let logger = Logger.log(MineMainViewController.self, category: "Module.Mine")

    private let disposeBag = DisposeBag()

    private var tipType: MineTipType = .noneTip

    private lazy var kvoDisposeBag = KVODisposeBag()

    private var footerView: UIView?

    private var customerServiceView: MineMainCustomerServiceView?

    // 避免访问lazy属性导致初始化
    private weak var _poweredByView: MineMainPoweredByView?
    private lazy var poweredByView: MineMainPoweredByView = { [weak self] () -> MineMainPoweredByView in
        let poweredByView = MineMainPoweredByView()
        _poweredByView = poweredByView
        self?.footerView?.addSubview(poweredByView)
        return poweredByView
    }()

    /// 展示数据源
    private var titleDataSource: [CellType] = []
    private var tableView: UITableView?
    private var headerView: ProfileHeaderView?
    /// 是否需要提示新版本
    private var shouldNotice: Bool = false

    private var loginDevices: [LoginDevice] = [] {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.tableView?.reloadData()
            }
        }
    }

    private var oncalls: [Oncall] = []

    var router: MineMainRouter?

    private let viewModel: MineMainViewModel

    init(viewModel: MineMainViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.commonInit()
        self.createSubviews()
        /// get description from local
        self.updateUserDescription()

        self.viewModel.bind()
        self.customerServiceView?.setOncalls(oncalls: self.oncalls)

        self.viewModel.validSessionsDriver.drive(onNext: { [weak self] (sessions) in
            self?.loginDevices = sessions
        }).disposed(by: disposeBag)

        let reach = Reachability()
        self.viewModel
            .getHomePageOncalls(fromLocal: reach?.connection == Reachability.Connection.none)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (oncalls) in
                guard let `self` = self else { return }
                if !oncalls.isEmpty, self.customerServiceView?.isHidden == false {
                    self.layoutBottomView(true)
                    self.customerServiceView?.sizeToFit()
                    self.customerServiceView?.setOncalls(oncalls: oncalls)
                }
            })
            .disposed(by: self.disposeBag)

        /// get description from remote
        self.updateWorkDescription()

        /// 监听 Chatter
        self.viewModel.currentChatterObservable.subscribe(onNext: { [weak self] (currentChatter) in
            guard let `self` = self else { return }
            // 请假中标签
            self.headerView?.setWorkStatus(currentChatter.workStatus, deleteBlock: { [weak self] in
                self?.deleteWorkStatus()
            })
            // 个人状态
            self.headerView?.setFocusStatus(currentChatter.focusStatusList)
            // 名字
            self.headerView?.setName(currentChatter.nameWithAnotherName, chatID: currentChatter.id, avatarKey: currentChatter.avatarKey, medalKey: currentChatter.medalKey)
            MineMainViewController.logger.info("get information from push chatter：\(currentChatter.description_p.text.md5())")
            self.replaceWithInline(description: currentChatter.description_p.text, descriptionType: currentChatter.description_p.type)
        }).disposed(by: self.disposeBag)

        Observable.combineLatest(self.viewModel.currentUserObservable, self.viewModel.fetchLocalAndServerAuthState())
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_, authState) in
                guard let `self` = self else { return }
                /// c端用户不显示租户名
                let tenantName = self.viewModel.isCustomer ? "" : self.viewModel.passportUserService.userTenant.localizedTenantName
                let hasAuth = authState.0
                let isAuth = authState.1
                let authUrlString = authState.2
                self.headerView?.setTenatLabel(tenantName: tenantName,
                                               authUrlString: authUrlString,
                                               hasAuth: hasAuth,
                                               isAuth: isAuth)
            }).disposed(by: self.disposeBag)

        self.viewModel.isNotifyDriver.drive(onNext: { [weak self] _ in
            self?.tableView?.reloadData()
        }).disposed(by: self.disposeBag)

        /// 监听 badge 变化
        self.viewModel.updateBadgeRelay.asDriver().drive(onNext: { [weak self] _ in
            self?.tableView?.reloadData()
        }).disposed(by: self.disposeBag)

        /// 侧边栏和首页"有新版"icon一样的消除逻辑
        self.viewModel.versionUpdateService.shouldNoticeNewVerison.asDriver(onErrorJustReturn: false).drive(onNext: { [weak self] (status) in
            guard let `self` = self else { return }
            self.shouldNotice = status
            self.tipType = MineGuideHelper.checkTipType(status, self.viewModel.guideService)
            self.tableView?.reloadData()
        }).disposed(by: self.disposeBag)

        /// 监听精简模式
        self.viewModel.leanModeStatus
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (status) in
                self?.headerView?.setLeanModeStatus(status: status)
            })
            .disposed(by: self.disposeBag)
        /// 监听远端下发Sidebar变化
        self.viewModel.mineSidebarService.sidebarDriver.drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.titleDataSource = self.createTitleDataSource()
            self.tableView?.reloadData()
        }).disposed(by: self.disposeBag)

        // Inline更新
        self.viewModel.inlineService.subscribePush(handler: { [weak self] push in
            guard let self = self, let entry = push[self.viewModel.user.id] else { return }
            let description = self.viewModel.user.description_p
            // md5相等时才替换，否则可能仍然使用的是旧的签名
            if description.text.md5() == entry.textMD5 {
                DispatchQueue.main.async {
                    self.viewModel.replaceWithInline(
                        description: description.text,
                        completion: { [weak self] descriptionAttr, urlRangeMap, textUrlRangeMap in
                            self?.headerView?.set(description: descriptionAttr,
                                                  descriptionType: description.type,
                                                  urlRangeMap: urlRangeMap,
                                                  textUrlRangeMap: textUrlRangeMap)
                        },
                        isFromPush: true
                    )
                }
            }
        })

        NotificationCenter.default.rx.notification(
            MineNotification.DidShowSettingUpdateGuide)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.tableView?.reloadData()
            }).disposed(by: disposeBag)

        layoutBottomView(false)
        SettingTracker.Main.View()
    }

    private func layoutBottomView(_ isCustomerServiceShow: Bool) {

        // flag
        var showPoweredByView = false
        var showCustomerView = false
        // Record current Bottom, 记录当前Bottom
        var bottom: ConstraintRelatableTarget = self.footerView?.snp.bottom ?? self.view.snp.bottom
        if self.viewModel.fgValueBy(key: .suitePoweredBy) {
            _poweredByView?.isHidden = true
        } else {
            poweredByView.snp.remakeConstraints { (maker: ConstraintMaker) in
                maker.height.equalTo(18)
                maker.left.equalTo(20)
                maker.right.equalToSuperview()
                maker.bottom.equalTo(-16)
            }
            poweredByView.isHidden = false

            // Record new Bottom
            bottom = poweredByView.snp.top
            showPoweredByView = true
        }

        if self.viewModel.isCustomer {
            self.customerServiceView?.isHidden = true
        }

        if isCustomerServiceShow, let customerServiceView = customerServiceView {
            customerServiceView.snp.remakeConstraints({ (make) in
                make.left.right.equalToSuperview()
                make.bottom.equalTo(bottom)
            })

            // Record new Bottom
            bottom = customerServiceView.snp.top
            showCustomerView = true
        }

        // 两个都不展示时，iPad Popover 场景下面需要留 24px 空白
        let needExtraPadding = !showPoweredByView && !showCustomerView

        self.footerView?.snp.remakeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalTo(bottom).offset(needExtraPadding ? -24 : 0)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.viewModel.user.workStatus.hasStatus {
            self.checkShowWorkDayGuideIfNeed()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.trackTabMe()
        self.configHeaderView()
        self.viewModel.fetchValidSession()
        // 由于自动结束的状态没有推送，所以每次进入界面时刷新个人状态
        headerView?.focusView.refresh()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    private func commonInit() {
        view.backgroundColor = UIColor.ud.bgBody
    }

    private func configHeaderView() {
        let user = self.viewModel.user
        headerView?.setName(user.nameWithAnotherName, chatID: user.id, avatarKey: user.avatarKey, medalKey: user.medalKey)
    }

    /// 创建要显示的数据源
    private func createTitleDataSource() -> [CellType] {
        var titleDataSource: [CellType] = []
        // 我的profle页
        titleDataSource.append(.profile(Resources.icon_member_outlinedprofile, BundleI18n.LarkMine.Lark_Profile_MyProfileNew))
        // 红包是否支持跨租户
        if viewModel.walletEnable {
            titleDataSource.append(.wallet(Resources.wallet, BundleI18n.LarkMine.Lark_Legacy_Wallet))
        }
        // 收藏
        if viewModel.favoriteEnable {
            titleDataSource.append(.favorite(Resources.favorite_icon, BundleI18n.LarkMine.Lark_Legacy_SaveFavoriteItems))
        }
        // 加入或创建团队
        let isExcludeLogin = self.viewModel.passportUserService.user.isExcludeLogin ?? false // 某些 KA 不允许账户同登，此时屏蔽加入团队入口
        if self.viewModel.fgValueBy(key: .suiteJoinFunction) && !isExcludeLogin {
            titleDataSource.append(.teamConversion(Resources.join_team, viewModel.teamConversionTitle))
        }
        // 帮助与客服
        if !self.viewModel.isCustomer, self.viewModel.fgValueBy(key: .suiteHelpService) {
            titleDataSource.append(.feedback(Resources.customer_service, BundleI18n.LarkMine.Lark_HelpDesk_SidebarEntry))
        }
        // 设备登陆
        titleDataSource.append(.accountAndDevice(Resources.account, BundleI18n.LarkMine.Lark_Settings_DevicesEntry))
        // 系统设置
        titleDataSource.append(.sysSetting(Resources.setting, BundleI18n.LarkMine.Lark_Legacy_SystemSetting))
        // 远端下发的Sidebar，排除不显示的Sidebar
        let showSidebars = self.viewModel.mineSidebarService.sidebars.filter({ $0.sidebarIsshow })
        for barItem in showSidebars {
            titleDataSource.append(.remoteSidebar(barItem))
        }
        return titleDataSource
    }

    private func createSubviews() {

        let headerView = ProfileHeaderView(userResolver: self.viewModel.userResolver, tenantNameService: viewModel.tenantNameService)
        let user = self.viewModel.user
        headerView.setName(user.nameWithAnotherName, chatID: user.id, avatarKey: user.avatarKey, medalKey: user.medalKey)
        headerView.chatterStatusLabel.tapBlock = { [weak self] in
            self?.tappedOnWorkDescriptionView()
            SettingTracker.Main.Click.Status()
            return false
        }
        headerView.setWorkStatus(user.workStatus) { [weak self] in
            self?.deleteWorkStatus()
            SettingTracker.Main.Click.Status()
        }
        headerView.pushInformation = { [weak self] (click, clickField) in
            guard let `self` = self else { return }
            // 到个人信息页
            self.router?.openPersonalInformationController(self, chatter: self.viewModel.user, completion: { [weak self] signature in
                self?.replaceWithInline(description: signature, descriptionType: .onDefault)
            })
            let verifiedStatus = "\(self.viewModel.certificateStatus.rawValue)"
            MineTracker.trackEditProfile(click: click, clickField: clickField, extraParams: ["verified_status": verifiedStatus])
            SettingTracker.Main.Click.PersonalLink()
        }
        headerView.openFocusList = { [weak self] sourceView in
            SettingTracker.Main.Click.FocusList()
            self?.didTapFocusList(sourceView)
        }

        self.view.addSubview(headerView)
        headerView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        self.headerView = headerView
        headerView.setContentHuggingPriority(.required, for: .vertical)
        headerView.setContentCompressionResistancePriority(.required, for: .vertical)
        self.headerView?.tenantContainerView.openUrlBlock = { [weak self] url in
            guard let `self` = self else { return }
            self.router?.openLink(self, linkURL: url, isShowDetail: true)
        }

        let footerView = UIView()
        self.view.addSubview(footerView)
        footerView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalTo(footerView.snp.bottom)
        }
        self.footerView = footerView

        // tableView
        let tableView = UITableView(frame: self.view.bounds, style: UITableView.Style.plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets.zero
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = false
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.backgroundColor = UIColor.clear
        tableView.lu.register(cellSelf: MineMainInfoViewCell.self)
        self.view.addSubview(tableView)

        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(footerView.snp.top)
        }
        tableView.setContentHuggingPriority(.required, for: .vertical)
        tableView.setContentCompressionResistancePriority(.required, for: .vertical)
        self.tableView = tableView

        let customerServiceView = MineMainCustomerServiceView()
        footerView.addSubview(customerServiceView)
        customerServiceView.router = self
        self.customerServiceView = customerServiceView

        if Display.pad {
            headerView.layer.observe(\.bounds, options: [.new, .old], changeHandler: { [weak self] _, change in
                if change.oldValue != change.newValue {
                    self?.updatePreferredContentSize()
                }
            }).disposed(by: kvoDisposeBag)
            footerView.layer.observe(\.bounds, options: [.new, .old], changeHandler: { [weak self] _, change in
                if change.oldValue != change.newValue {
                    self?.updatePreferredContentSize()
                }
            }).disposed(by: kvoDisposeBag)
            tableView.observe(\.contentSize, options: [.new, .old], changeHandler: { [weak self] _, change in
                if change.oldValue != change.newValue {
                    self?.updatePreferredContentSize()
                }
            }).disposed(by: kvoDisposeBag)
        }
    }

    private func updatePreferredContentSize() {
        let profileHeight: CGFloat = headerView?.bounds.height ?? 0
        let tableHeight: CGFloat = tableView?.contentSize.height ?? 0
        let footerHeight: CGFloat = footerView?.bounds.height ?? 0
        let newHeight = profileHeight + tableHeight + footerHeight
        if newHeight != preferredContentSize.height {
            preferredContentSize = CGSize(width: 300, height: newHeight)
            Self.logger.debug("MinePopover MineMainVC preferredContentSize height" +
                              " detail: \(profileHeight), \(tableHeight), \(footerHeight)")
        }
    }

    func deleteWorkStatus() {
        MineTracker.trackDeleteWorkDay()
        let alertController = UDDialog()
        alertController.setTitle(text: BundleI18n.LarkMine.Lark_Legacy_DeleteTip)
        alertController.setContent(text: BundleI18n.LarkMine.Lark_Legacy_WorkStatusDeleteTip)
        alertController.addCancelButton()
        alertController.addPrimaryButton(text: BundleI18n.LarkMine.Lark_Legacy_Sure, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            self.viewModel.chatterAPI.deleteChatterWorkStatus()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.headerView?.workStatusLabel.isHidden = true
                }, onError: { [weak self] (error) in
                    guard let window = self?.view.window else { return }
                    MineMainViewController.logger.error("delete workstatus failed", error: error)
                    UDToast.showFailure(
                        with: BundleI18n.LarkMine.Lark_Legacy_MineMessageSettingSetupFailed,
                        on: window,
                        error: error
                    )
                }).disposed(by: self.disposeBag)
        })
        self.viewModel.userResolver.navigator.present(alertController, from: self)
    }

    private func updateUserDescription() {
        let result = self.viewModel.updateUserDescription()
        let descriptionTypeValue = result.descriptionTypeValue
        if let descriptionTypeValue, let description = result.description,
            let descriptionType = Chatter.DescriptionType(rawValue: descriptionTypeValue) {
            MineMainViewController.logger.info("get information from local：\(description.md5())")
            self.replaceWithInline(description: description, descriptionType: descriptionType)
        }
    }

    func checkShowWorkDayGuideIfNeed() {
        showNewWorkDayGuide()
    }

    private func tappedOnWorkDescriptionView() {
        self.router?.openWorkDescription(self, completion: { [weak self] status in
            guard let self = self else { return }
            self.viewModel.user.description_p.text = status
            self.replaceWithInline(description: status, descriptionType: .onDefault)
        })
    }

    private func didTapFocusList(_ view: FocusDisplayView) {
        router?.openFocusListController(self, sourceView: view)
    }

    private func updateWorkDescription() {
        self.viewModel.requestProfileInformation { [weak self] (description, descriptionType) in
            MineMainViewController.logger.info("get information from remote：\(description.md5())")
            self?.replaceWithInline(description: description, descriptionType: descriptionType)
        }
    }

    private func replaceWithInline(description: String, descriptionType: Chatter.DescriptionType) {
        self.viewModel.replaceWithInline(description: description, completion: { [weak self] description, urlRangeMap, textUrlRangeMap in
            self?.headerView?.set(description: description, descriptionType: descriptionType, urlRangeMap: urlRangeMap, textUrlRangeMap: textUrlRangeMap)
        })
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleDataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: MineMainInfoViewCell = tableView.dequeueReusableCell(withIdentifier: MineMainInfoViewCell.lu.reuseIdentifier) as? MineMainInfoViewCell else { return .init() }

        switch titleDataSource[indexPath.row] {
        case .accountAndDevice(let icon, let title):
            if !loginDevices.isEmpty {
                cell.set(icon: icon, title: title, addtionText: String(loginDevices.count), addtionImage: Resources.device)
            } else {
                cell.set(icon: icon, title: title)
            }
        /// 系统设置需要显示是否有新版本
        case .sysSetting(let icon, let title):
            cell.set(icon: icon, title: title, badgeId: MineUGBadgeID.setting.rawValue, dependency: self.viewModel.badgeDependency)
        case .profile(let icon, let title),
             .wallet(let icon, let title),
             .feedback(let icon, let title),
             .favorite(let icon, let title):
            cell.set(icon: icon, title: title)
        case .teamConversion(let icon, let title):
            cell.set(icon: icon, title: title, showRedDot: viewModel.canShowUpgradeTeamBadge)
        case .remoteSidebar(let sidebar):
            let info = self.viewModel.mineSidebarService.getInfo(type: sidebar.sidebarType)
            cell.set(icon: info.0, title: info.1)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        switch titleDataSource[indexPath.row] {
        case .profile:
            // 到个人信息页
            self.router?.openProfileDetailController(self, chatter: self.viewModel.user)
            SettingTracker.Main.Click.ProfileDetail()
        case .wallet:
            self.router?.openWalletController(self, walletUrl: self.viewModel.walletUrl)
            SettingTracker.Main.Click.Wallet()
        case .favorite:
            self.router?.openFavoriteController(self)
            SettingTracker.Main.Click.Favorite()
        case .accountAndDevice:
            self.router?.openDataController(self)
            SettingTracker.Main.Click.Device()
        case .sysSetting:
            self.router?.openSettingController(self)
            /// 点击系统设置，消失首页和侧边栏"有新版"提示
            self.viewModel.versionUpdateService.tryToCleanUpNotice()
            SettingTracker.Main.Click.Setting()
        case .feedback:
            self.router?.openCustomServiceChat(self)
            SettingTracker.Main.Click.Help()
        case .teamConversion:
            if !viewModel.passportUserService.user.type.isStandard {
                viewModel.canShowUpgradeTeamBadge = false
            }
            self.router?.openTeamConversionController(self)
            SettingTracker.Main.Click.JoinCreateTeam()
        case .remoteSidebar(let sidebar):
            self.router?.openLink(self, linkURL: self.viewModel.mineSidebarService.getURL(type: sidebar.sidebarType), isShowDetail: false)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension MineMainViewController: MineMainCustomerServiceViewRouter {

    func openCustomServiceChatById(id: String, phoneNumber: String, reportLocation: Bool) {
        if let reach = Reachability(), reach.connection != .none {
            self.router?.openCustomServiceChatById(self, id: id, reportLocation: reportLocation)
        } else {
            if !phoneNumber.isEmpty {
                self.showAlert(title: "\(phoneNumber)", message: "", sureHandler: { (_) in
                    LarkFoundation.Utils.telecall(phoneNumber: phoneNumber)
                }, cancelHandler: nil)
            }
        }
    }
}

/// Guide
extension MineMainViewController: GuideSingleBubbleDelegate {

    func showNewWorkDayGuide() {
        let guideKey = WorkDayGuideInfo.key
        guard let workStatusLabel = self.headerView?.workStatusLabel else { return }

        let bubbleConfig = BubbleItemConfig(
            guideAnchor: TargetAnchor(targetSourceType: .targetView(workStatusLabel)),
            textConfig: TextInfoConfig(detail: BundleI18n.LarkMine.Lark_Profile_OnLeaveLabelOnboardTip),
            bottomConfig: BottomConfig(rightBtnInfo: ButtonInfo(title: BundleI18n.LarkMine.Lark_Notification_ClassifySingleAlertButton))
        )
        let singleBubbleConfig = SingleBubbleConfig(
            delegate: self,
            bubbleConfig: bubbleConfig,
            maskConfig: MaskConfig()
        )
        self.viewModel.guideService.showBubbleGuideIfNeeded(guideKey: guideKey,
                                bubbleType: .single(singleBubbleConfig),
                                dismissHandler: nil)
    }

    public func didClickRightButton(bubbleView: GuideBubbleView) {
        self.viewModel.guideService.closeCurrentGuideUIIfNeeded()
    }
}
