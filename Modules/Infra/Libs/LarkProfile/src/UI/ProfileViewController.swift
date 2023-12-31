//
//  ProfileViewController.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/6/20.
//

import Foundation
import UIKit
import RxSwift
import RichLabel
import LarkUIKit
import UniverseDesignIcon
import EENavigator
import LarkFocus
import Homeric
import LKCommonsTracker
import LarkBizAvatar
import LarkContainer
import LarkMessengerInterface

public protocol ProfileData { }

public protocol ProfileDataProvider: AnyObject {
    static var identifier: String { get }
    static func createDataProvider(by data: ProfileData, resolver: LarkContainer.UserResolver, factory: ProfileFactory?) -> ProfileDataProvider?
    var isBlocked: Bool { get }
    var isHideAddContactButtonOnProfile: Bool { get }
    var shouldUpdateDefaultIndex: Bool { get }
    var needToPushSetInformationViewController: Bool { get }
    var status: Observable<ProfileStatus> { get }
    var relationship: Observable<ProfileRelationship> { get }
    var profileVC: ProfileViewController? { get set }
    var communicationPermission: Observable<ProfileCommunicationPermission> { get }
    func reloadData()
    func numberOfTabs() -> Int
    func titleOfTabs() -> [String]
    func identifierOfTabs() -> [String]
    func getIndexBy(identifier: String) -> Int?
    func getTabBy(index: Int) -> ProfileTab
    func getAvtarView() -> UIView?
    func getNavigationBarAvatarView() -> UIView?
    func getBackgroundView() -> UIImageView?
    func getUserInfo() -> ProfileUserInfo
    func getCTA() -> [ProfileCTAItem]
    func getNavigationButton() -> [UIButton]
    func changeRelationship(_ relationship: ProfileRelationship)
    func changeCommunicationPermission(_ permission: ProfileCommunicationPermission)
    func pushSetInformationViewController()
    func loadUserInfo()
    func medalViewTapped()
    func backgroundViewTapped()
    func replaceDescriptionWithInlineTrySDK(by text: String, completion: @escaping TextToInlineService.Completion)
}

public class ProfileViewController: BaseUIViewController, UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver

    private var shouldUpdateDefaultIndex: Bool {
        return self.dataProvider.shouldUpdateDefaultIndex
    }

//    lazy var profileView: ProfileView = { ProfileView() }()
    var isProfileViewInitialized: Bool = false
    var profileView: ProfileView!

    lazy var naviHeight: CGFloat = {
        let barHeight = ProfileNaviBar.Cons.barHeight
        if Display.pad {
            return barHeight
        } else {
            return UIApplication.shared.statusBarFrame.height + barHeight
        }
    }()

    public override var navigationBarStyle: NavigationBarStyle {
        return .none
    }

    var dataProvider: ProfileDataProvider

    let disposeBag = DisposeBag()

    private var isNaviBarHidden: Bool = true

    var currentStatusBarStyle: UIStatusBarStyle = .lightContent {
        didSet {
            guard currentStatusBarStyle != oldValue else { return }
            profileView.navigationBar.setNaviButtonStyle(currentStatusBarStyle)
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    private var defaultId: String = ""

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        Display.pad ? .default : currentStatusBarStyle
    }

    public init(resolver: UserResolver, provider: ProfileDataProvider) {
        self.userResolver = resolver
        self.dataProvider = provider
        super.init(nibName: nil, bundle: nil)
        self.dataProvider.profileVC = self
        // 隐藏原有导航栏，使用 Profile 自定义导航栏
        self.isNavigationBarHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindingData()
        self.deviceWillChangeStatusBarOrientatio()
        trackAiProfileViewEventIfNeeded()
    }

    func deviceWillChangeStatusBarOrientatio() {
        NotificationCenter.default.addObserver(forName: UIApplication.willChangeStatusBarOrientationNotification,
                                               object: nil,
                                               queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.profileView.segmentedView.reloadData()
        }
    }

    func setupProfileView() {
        profileView = ProfileView(userResolver: userResolver)
        isProfileViewInitialized = true
    }
    
    func setupUI() {
        setupProfileView()
        view.addSubview(profileView)
        profileView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        ProfileReciableTrack.userProfileFirstRenderViewCostTrack()
        profileView.segmentedView.delegate = self
        profileView.segmentedView.hoverHeight = naviHeight
        profileView.segmentedView.setHeaderView(profileView.headerView)
        profileView.navigationBar.backButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        profileView.addContactView.tapHandler = { [weak self] relationship in
            self?.dataProvider.changeRelationship(relationship)
        }
        profileView.applyCommunicationView.tapHandler = { [weak self] communicationPermission in
            guard let self = self else { return }
            self.dataProvider.changeCommunicationPermission(communicationPermission)
        }
        profileView.navigationBar.barTapHandle = { [weak self] in
            guard let self = self else { return }
            self.dataProvider.backgroundViewTapped()
        }
        let icon = UDIcon.getIconByKey(.leftOutlined)
            .ud.resized(to: ProfileNaviBar.Cons.iconSize)
            .withRenderingMode(.alwaysTemplate)
        profileView.navigationBar.backButton.setImage(icon, for: .normal)

        if Display.pad {
            self.preferredContentSize = ProfileView.Cons.iPadViewSize
            self.modalPresentationControl.dismissEnable = true
            self.modalPresentationStyle = .formSheet
        }

        // 导航栏初始状态
        profileView.navigationBar.setAppearance(byProgress: 0)
        profileView.navigationBar.setNaviButtonStyle(.lightContent)
        // 用户数据绑定
        dataProvider.status.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (status) in
            guard let self = self else { return }
            self.loadContent()
            self.profileView.setInfoStatus(status) {
                self.dataProvider.reloadData()
            }
            if status == .error {
                // error页面右上角不展示任何button
                self.profileView.setBarButtons([])
            }
        }).disposed(by: disposeBag)

        // 添加联系人
        profileView.addContactView.state = .none
        profileView.addContactView.isBlocked = false
        dataProvider.relationship.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self, weak dataProvider] relationship in
            guard let self = self else { return }
            guard let dataProvider = dataProvider else { return }
            self.profileView.addContactView.hideAddConnectButton = dataProvider.isHideAddContactButtonOnProfile
            self.profileView.addContactView.state = relationship
            self.profileView.addContactView.isBlocked = dataProvider.isBlocked
        }).disposed(by: disposeBag)

        profileView.focusView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapFocusView(_:))))
        if dataProvider.needToPushSetInformationViewController {
            self.dataProvider.pushSetInformationViewController()
        }
    }

    private func bindingData() {
        profileView.applyCommunicationView.state = .unown
        dataProvider.communicationPermission.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] communicationPermission in
            guard let self = self else { return }
            NewProfileViewController.logger.info("get current communication permission: \(communicationPermission)")
            self.profileView.applyCommunicationView.state = communicationPermission
        }).disposed(by: disposeBag)
    }

    public func setDefaultSelected(identifier: String) {
        self.defaultId = identifier
    }

    func loadContent() {
        // Bind data
        profileView.setUserInfo(dataProvider.getUserInfo())
        profileView.setAvatarView(dataProvider.getAvtarView)
        profileView.setNavigationBarAvatarView(dataProvider.getNavigationBarAvatarView)
        profileView.setCTAButtons(dataProvider.getCTA())
        profileView.addContactView.hideAddConnectButton = dataProvider.isHideAddContactButtonOnProfile
        profileView.addContactView.isBlocked = dataProvider.isBlocked
        profileView.setBackgroundImageView(dataProvider.getBackgroundView())
        
        self.reloadData()
        
        // NaviBar 右侧按钮（转发、更多）
        profileView.setBarButtons(dataProvider.getNavigationButton())
        profileView.navigationBar.setNaviButtonStyle(currentStatusBarStyle)
        
        profileView.segmentedView.setHeaderView(profileView.headerView)
        profileView.setupConstraints()
        
        profileView.segmentedView.updateHeaderViewFrame()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.profileView.segmentedView.updateHeaderViewFrame()
        }
    }

    func reloadData() {
        var defaultIndex = 0
        if let index = self.dataProvider.getIndexBy(identifier: defaultId) {
            defaultIndex = index
        } else if let lastSelectIndex = profileView.segmentedView.lastSelectedIndexOfTabsView {
            defaultIndex = lastSelectIndex
        }
        if shouldUpdateDefaultIndex {
            profileView.segmentedView.setDefaultSelected(index: defaultIndex)
        }
        profileView.segmentedView.reloadData()
    }

    @objc
    func close() {
        dismissSelf()
    }

    @objc
    func didTapFocusView(_ gesture: UITapGestureRecognizer) {
        if dataProvider.getUserInfo().isSelf {
            let focusListVC = FocusListController(userResolver: userResolver)
            focusListVC.onFocusStatusChanged = { [weak self] in
                guard let self = self else { return }
                self.dataProvider.reloadData()
            }
            self.userResolver.navigator.present(focusListVC, from: self)
            // Analytics
            Tracker.post(TeaEvent(Homeric.PROFILE_MAIN_CLICK, params: [
                "click": "personal_status",
                "target": "setting_personal_status_view"
            ]))
        } else {
            // guard let tapView = gesture.view else { return }
            // 显示不全的状态，点击后弹框展示
            guard profileView.focusView.titleLabel.isTruncated else { return }
            if let status = dataProvider.getUserInfo().focusList.topActive {
                let preview = FocusPreviewDialog()
                preview.setFocusStatus(status)
                self.userResolver.navigator.present(preview, from: self)
            }
        }
    }
}

extension ProfileViewController: SegmentedTableViewDelegate {
    public func numberOfTabs(in segmentedView: SegmentedTableView) -> Int {
        self.dataProvider.numberOfTabs()
    }

    public func titleOfTabs(in segmentedView: SegmentedTableView) -> [String] {
        self.dataProvider.titleOfTabs()
    }

    public func identifierOfTabs(in segmentedView: SegmentedTableView) -> [String] {
        self.dataProvider.identifierOfTabs()
    }

    public func segmentedView(_ segmentedView: SegmentedTableView, contentableForIndex index: Int) -> SegmentedTableViewContentable {
        let vc = self.dataProvider.getTabBy(index: index)
        if vc.profileVC == nil {
            vc.profileVC = self
        }
        return vc
    }

    /// SegmentedView 滚动代理
    public func segmentedViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        // Header Image 吸顶效果
        profileView.backgroundImageView.snp.updateConstraints { update in
            update.top.equalToSuperview().offset(min(0, offsetY))
        }

        // 根据下滑进度改变导航栏样式
        let minThreshold = profileView.avatarWrapperView.frame.minY - naviHeight
        let maxThreshold = profileView.avatarWrapperView.frame.maxY - naviHeight
        var progress = (offsetY - minThreshold) / (maxThreshold - minThreshold)
        progress = min(max(0, progress), 1)
        currentStatusBarStyle = progress < 0.5 ? .lightContent : .default
        profileView.navigationBar.setAppearance(byProgress: progress)
    }

    func dismissSelf() {
        if hasBackPage {
            navigationController?.popViewController(animated: true)
        } else if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        }
    }
}

extension ProfileViewController {

    func trackAiProfileViewEventIfNeeded() {
        guard let provider = dataProvider as? LarkProfileDataProvider, provider.isAIProfile else { return }
        Tracker.post(TeaEvent("profile_ai_main_view", params: [
            "shadow_id": provider.aiShadowID,
            "contact_type": provider.isMyAIProfile ? "self" : "none_self"
        ]))
    }
}
