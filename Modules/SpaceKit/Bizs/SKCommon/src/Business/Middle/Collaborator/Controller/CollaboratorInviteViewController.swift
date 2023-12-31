//
//  CollaboratorInviteViewController.swift
//  SKCommon
//
//  Created by liweiye on 2020/8/24.
//
// swiftlint:disable file_length

import UIKit
import SwiftyJSON
import LarkLocalizations
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignToast
import RxSwift
import RxCocoa
import LarkUIKit
import EENavigator
import LarkFeatureGating
import UniverseDesignColor
import LarkAlertController
import UniverseDesignDialog
import UniverseDesignLoading
import SKInfra
import LarkContainer

private extension ShareDocsType {
    var inviteHintText: String {
        switch self {
        case .bitableSub(let sub):
            switch sub {
            case .form:
                return BundleI18n.SKResource.Bitable_Form_SendFormLink
            case .view, .record, .dashboard, .dashboard_redirect, .addRecord:
                return BundleI18n.SKResource.Bitable_Share_SendSharingLink_Checkbox
            }
        default:
            return BundleI18n.SKResource.Doc_Permission_SendLarkNotification
        }
    }
}

protocol CollaboratorInviteViewControllerDelegate: AnyObject {
    func collaboardInvite(_ collaboardInvite: CollaboratorInviteViewController, didUpdateWithItems items: [Collaborator])
    func dissmissSharePanel(animated: Bool, completion: (() -> Void)?)
}

protocol OrganizationInviteNotifyDelegate: AnyObject {
    func dismissSharePanelAndNotify(completion: (() -> Void)?)
    func dismissInviteCompletion(completion: (() -> Void)?)
}

// 进入协作者邀请VC的来源，方便后续做视图层级的处理
public enum CollaboratorInviteSource {
    case sharePanel
    case collaboratorEdit
    case sendLink
    case diyTemplate
}

/// 文件、文件夹、共享文件夹 添加协作者。 需要特别注意，创建新共享文件夹时，可以添加协助者，此时 fileEntry为空
class CollaboratorInviteViewController: BaseViewController {

    let disposeBag: DisposeBag = DisposeBag()
    weak var delegate: CollaboratorInviteViewControllerDelegate?
    weak var organizationDelegate: OrganizationInviteNotifyDelegate?
    var isInviteExternal: Bool = false
    private var loadingView = UDLoading.loadingImageView()
    //是否显示邀请外部协作者Ask Owner面板
    private lazy var shouldAskOwnerInviteExternal: Bool = {
        if self.fileModel.isOwner { return false }
        guard let publicPermissionConfig = self.publicPermissionConfig else { return false }
        //权限设置添加协作者选项为：组织内所有可阅读或编辑此文档的用户（仅可邀请组织内用户） 或 只有我可以时，若邀请的协作者中存在外部用户，需要ask owner
        return publicPermissionConfig.shouldAskOwnerWhenInviteExternal
    }()
    ///无邀请外部协作者的权限时，邀请失败的外部协作者列表
   private lazy var inviteFailExternalCollaborator: [Collaborator] = {
    //过滤出当前邀请的协助者中的外部协作者
    return items.filter {
        if $0.type == .group { return $0.isCrossTenant }
        return $0.isExternal
    }
   }()
    //记录是否需要在pop分享面板后提示仅授权，不会通知组织架构弹窗
    var shouldShowBlockNotifyCollaboratorTips = false
    
    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    
    public struct PermissionPlaceHolderContext {
        public let sheet: DocsAlertController
        public let sender: CollaboratorInviteMenuButton
        public let isSelected: Bool
        public let canBeSelected: Bool
        public let collaborator: Collaborator
        public let titleFont: UIFont
        public let needSubtitle: Bool
    }
    
    public struct RemovePermissionPlaceHolderContext {
        public let sheet: DocsAlertController
        public let sender: CollaboratorInviteMenuButton
        public let indexPath: IndexPath
        public let title: String
        public let collaborator: Collaborator
        public let titleFont: UIFont
        public let isCreate: Bool
        public let needReport: Bool
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }

    var datas: [CollaboratorSearchResultCellItem] = []
    var items: [Collaborator] {
        didSet {
            self.datas = self.items.map {
                if $0.isExternal {
                    isInviteExternal = true
                }
                return CollaboratorSearchResultCellItem(collaboratorID: $0.userID,
                                                        selectType: .none,
                                                        imageURL: $0.avatarURL,
                                                        imageKey: $0.imageKey,
                                                        title: $0.name,
                                                        detail: $0.detail,
                                                        isExternal: $0.isExternal,
                                                        blockExternal: $0.blockExternal,
                                                        isCrossTenanet: $0.isCrossTenant,
                                                        roleType: $0.type,
                                                        userCount: $0.userCount,
                                                        organizationTagValue: $0.organizationTagValue)
            }
            self.delegate?.collaboardInvite(self, didUpdateWithItems: self.items)
            if !oldValue.isEmpty && self.items.isEmpty {
                self.backBarButtonItemAction()
            } else {
                self.reloadTopTipView()
            }
        }
    }
    // 是否有邮箱协作者
    var hasEmailCollaborator: Bool {
        return items.contains(where: { $0.type == .email })
    }
    // 是否只有邮箱协作者
    var onlyEmailCollaborator: Bool {
        return !items.contains(where: { $0.type != .email })
    }

    let childPageEnableKey = "childPageEnableKey"
    var isChildPageEnable: Bool {
        get {
            let userId = Container.shared.getCurrentUserResolver().userID
            return CCMKeyValue.userDefault(userId).bool(forKey: childPageEnableKey, defaultValue: true)
        }
        set {
            let userId = Container.shared.getCurrentUserResolver().userID
            CCMKeyValue.userDefault(userId).set(newValue, forKey: childPageEnableKey)
        }
    }
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        return view
    }()
    private let cellReuseIdentifier: String = "CollaboratorSearchResultCell"
    private lazy var collaboratorInvitationTableView: UITableView = {
        let tableView = UITableView()
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 0.1))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 0.1))
        tableView.allowsSelection = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UDColor.bgBody
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.register(CollaboratorSearchResultCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        return tableView
    }()
    lazy var collaboratorBottomView: CollaboratorBottomView = {
        let view = CollaboratorBottomView()
        view.delegate = self
        return view
    }()
    let keyboard = Keyboard() // 监听 keyboard 事件
    // 用于挡住 optionBar 在iPhone X下方空白去的投影
    private lazy var buttonEmptyView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        return view
    }()
    ///
    private lazy var notificationPermissionTipView: PermissionTopTipView = {
        let tipView = PermissionTopTipView()
        return tipView
    }()
    ///提示：分享给外部，顶部安全提示
    private lazy var crossTenantTipView: PermissionTopTipView = {
        let tipView = PermissionTopTipView()
        return tipView
    }()

    /// 提示：你邀请的协作者只能访问当前页面
    private lazy var singlePageTipView: PermissionTopTipView = {
        let tipView = PermissionTopTipView()
        return tipView
    }()

    var askOwnerRequest: DocsRequest<Any>?
    var fileInviteRequest: DocsRequest<JSON>?
    var folderInviteRequest: DocsRequest<(Bool, JSON?)>?
    var userPermissions: UserPermissionAbility?
    let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!

    private var publicPermissionConfig: PublicPermissionMeta? {
        let augToken = permissionManager.augmentedToken(of: fileModel.objToken)
        return permissionManager.publicPermissionStore.publicPermissionMeta(for: augToken)
    }


    private(set) var inviteVM: CollaboratorInviteVCDependency
    var fileModel: CollaboratorFileModel {
        return self.inviteVM.fileModel
    }

    init(vm: CollaboratorInviteVCDependency) {
        self.inviteVM = vm
        self.items = vm.items
        self.userPermissions = vm.userPermisson
        if userPermissions == nil {
            DocsLogger.warning("user permissions should not be nil")
        }
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let items = self.items
        self.items = items
        self.collaboratorInvitationTableView.reloadData()
        self.inviteVM.statistics?.reportShowCollaborateSettingPage()
        keyboard.start()
    }
    
    override func popNeedAnimated() -> Bool {
        guard SKDisplay.phone else {
            return true
        }
        return UIApplication.shared.statusBarOrientation.isLandscape ? false: true
    }
    
    func loading() {
        if loadingView.superview == nil {
            view.addSubview(loadingView)
            loadingView.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        }
        loadingView.isHidden = false
    }
    
    func hideLoadingView() {
        loadingView.isHidden = true
    }
    
    @objc
    func orientationDidChange() {
        updateContentSize()
    }
}

extension CollaboratorInviteViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        fetchUserPermissions()
        setupNav()
        setupTitle()
        view.backgroundColor = .clear
        view.addSubview(contentView)
        contentView.addSubview(collaboratorInvitationTableView)
        contentView.addSubview(collaboratorBottomView)
        contentView.addSubview(buttonEmptyView)

        //布局顶部通知tip
        contentView.addSubview(notificationPermissionTipView)
        contentView.addSubview(crossTenantTipView)
        contentView.addSubview(singlePageTipView)
        
        updateContentSize()

        collaboratorInvitationTableView.snp.makeConstraints { (make) in
            make.top.equalTo(singlePageTipView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(collaboratorBottomView.snp.top)
        }
        configCollaboratorBottomView()

        view.bringSubviewToFront(self.navigationBar)

        collaboratorBottomView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        collaboratorBottomView.confirmButtonTappedBlock = { [weak self] _ in
            guard let self = self else { return }
            let text = self.collaboratorBottomView.textView.text
            self.reportInviteClick(candidates: Set(self.items))
            switch self.inviteVM.modeConfig.mode {
                case .manage:
                    if self.needShowOrganizationAlert() {
                        self.showOrganizationAlert { [weak self] in
                            self?.inviteCollaborators(larkIMText: text)  //邀请用户
                        }
                    } else if self.needShowGroupNotificationAlert() {
                        self.showGroupNotificationAlert { [weak self] in
                            self?.inviteCollaborators(larkIMText: text)  //邀请用户
                        }
                    } else if self.needShowEmailNotificationAlert() {
                        self.showEmailNotificationAlert() { [weak self] in
                            self?.inviteCollaborators(larkIMText: text)  //邀请用户
                        }
                    } else {
                        self.inviteCollaborators(larkIMText: text)  //邀请用户
                    }
                case .sendLink:
                    self.inviteCollaboratorsBySendLink(larkIMText: text) //发送链接
                case .askOwner:
                    self.inviteCollaboratorsByAskOwner(larkIMText: text, dispalyName: self.fileModel.displayName) //请求所有者共享
            }
        }
        collaboratorBottomView.textView.rx.text.changed
            .debounce(DispatchQueueConst.MilliSeconds_100, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.layoutPhoneSearchTips()
            }).disposed(by: disposeBag)
        buttonEmptyView.snp.makeConstraints { (make) in
            make.top.equalTo(collaboratorBottomView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        reportOpenPageStatis()
        reportPermissionInviteCollaboratorView(candidates: Set(self.items))
        setupKeyboardMonitor()
    }

    override func viewWillLayoutSubviews() {
        //布局顶部通知tip
        reloadTopTipView()
    }
    
    private func setupNav() {
        if SKDisplay.phone {
            navigationBar.layer.cornerRadius = 12
            navigationBar.layer.maskedCorners = .top
        }
    }
    
    private func updateContentSize() {
        if SKDisplay.phone, UIApplication.shared.statusBarOrientation.isLandscape {
            navigationBar.snp.remakeConstraints { (make) in
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).inset(14)
                make.centerX.equalToSuperview()
                make.width.equalTo(contentView.snp.width)
            }
            contentView.snp.remakeConstraints { (make) in
                make.width.equalToSuperview().multipliedBy(0.7)
                make.centerX.bottom.equalToSuperview()
                make.top.equalTo(navigationBar.snp.bottom)
            }
        } else {
            navigationBar.snp.remakeConstraints { (make) in
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                make.leading.trailing.equalToSuperview()
            }
            contentView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }
    
    private func reloadTopTipView() {
        layoutTopNotificationTips()
        layoutPhoneSearchTips()
        layoutCrossTenantTips()
        layoutSinglePageTips()
    }

    private func setupKeyboardMonitor() {
        keyboard.on(events: Keyboard.KeyboardEvent.allCases) { [weak self] (options) in
            guard let self = self else { return }
            guard let view = self.view else { return }
            let viewWindowBounds = view.convert(view.bounds, to: nil)
            
            var endFrame = options.endFrame.minY
            // 开启减弱动态效果/首选交叉淡出过渡效果,endFrame返回0.0,导致offset计算有问题
            if endFrame <= 0 {
                endFrame = viewWindowBounds.maxY
            }
            var offset = viewWindowBounds.maxY - endFrame - self.view.layoutMargins.bottom

            if self.isMyWindowRegularSizeInPad {
                var endFrameY = (options.endFrame.minY - self.view.frame.height) / 2
                endFrameY = endFrameY > 44 ? endFrameY : 44
                let moveOffest = self.view.convert(self.view.bounds, to: nil).minY - endFrameY
                offset -= moveOffest
            }
            self.collaboratorBottomView.snp.updateConstraints({ (make) in
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(min(-offset, 0))
            })
            
            let animationCurve = UIView.AnimationOptions(rawValue: UInt(options.animationCurve.rawValue))
            UIView.animate(withDuration: options.animationDuration, delay: 0, options: animationCurve, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }

    private func setupTitle() {
        var naviBarTitle = BundleI18n.SKResource.LarkCCM_Docs_InviteCollaborators_Menu_Mob
        switch inviteVM.modeConfig.mode {
        case .sendLink:
            naviBarTitle = BundleI18n.SKResource.Doc_Permission_SendLink
        case .askOwner:
            naviBarTitle = BundleI18n.SKResource.Doc_Permission_AskOwnerShare
        case .manage:
            if inviteVM.source == .diyTemplate {
                naviBarTitle = BundleI18n.SKResource.Doc_List_ShareTemplTitle
            }
        }

        if fileModel.isForm {
            naviBarTitle = BundleI18n.SKResource.Bitable_Form_AddCollaborator
        } else if fileModel.isBitableSubShare {
            naviBarTitle = BundleI18n.SKResource.Bitable_Share_AddViewers_Title
        }

        self.title = naviBarTitle
    }

    private func layoutTopNotificationTips() {
        notificationPermissionTipView.setLevel(.info)
        self.notificationPermissionTipView.attributeTitle = notificationTips.0
        if let range = notificationTips.1 {
            notificationPermissionTipView.linkCheckEnable = true
            notificationPermissionTipView.addTapRange(range)
            notificationPermissionTipView.delegate = self
        } else {
            notificationPermissionTipView.linkCheckEnable = false
        }
        notificationPermissionTipView.snp.remakeConstraints { (make) in
            make.top.equalTo(self.navigationBar.snp.bottom).offset(1)
            make.left.trailing.equalToSuperview()
            let height = self.notificationPermissionTipView.height(superViewW: self.view.frame.width)
            make.height.equalTo(shouldShowNotificationTips ? height : 0)
        }
    }

    private func layoutPhoneSearchTips() {
        collaboratorBottomView.setTextViewHint(isShow: false)
    }

    private func layoutSinglePageTips() {
        singlePageTipView.setLevel(.info)
        let title = BundleI18n.SKResource.CreationMobile_Wiki_SharePanel_Invite_desc

        let paraph = NSMutableParagraphStyle()
        paraph.lineSpacing = 4
        let attributes = [NSAttributedString.Key.paragraphStyle: paraph]
        self.singlePageTipView.attributeTitle = NSAttributedString(string: title, attributes: attributes)

        singlePageTipView.snp.remakeConstraints { (make) in
            make.top.equalTo(self.crossTenantTipView.snp.bottom).offset(1)
            make.left.trailing.equalToSuperview()
            let height = self.singlePageTipView.height(superViewW: self.view.frame.width)
            make.height.equalTo(showSinglePageTips ? height : 0)
        }
    }

    private func layoutCrossTenantTips() {
        crossTenantTipView.setLevel(.warn)
        var title = ""
        if fileModel.isSameTenantWithOwner && CollaboratorUtils.containsExternalCollaborators(self.items) {
            let typeString: String = (fileModel.docsType == .minutes) ? BundleI18n.SKResource.CreationMobile_Minutes_name : fileModel.docsType.i18Name
            title = BundleI18n.SKResource.CreatinoMobile_Minutes_share_mixed_dialog(typeString)
        } else if !fileModel.isSameTenantWithOwner && CollaboratorUtils.containsInternalGroupCollaborators(self.items) {
            if fileModel.docsType.isBizDoc {
                title = BundleI18n.SKResource.Doc_Permission_ExternalOwnerShareTips(BundleI18n.SKResource.Doc_List_TypeSimpleNameDoc)
            } else {
                title = BundleI18n.SKResource.Doc_Permission_ExternalOwnerShareTips(BundleI18n.SKResource.Doc_List_TypeSimpleNameFolder)
            }
        } else {
            title = ""
        }
        let paraph = NSMutableParagraphStyle()
        paraph.lineSpacing = 4
        let attributes = [NSAttributedString.Key.paragraphStyle: paraph]
        self.crossTenantTipView.attributeTitle = NSAttributedString(string: title, attributes: attributes)
        crossTenantTipView.snp.remakeConstraints { (make) in
            make.top.equalTo(self.notificationPermissionTipView.snp.bottom).offset(1)
            make.left.trailing.equalToSuperview()
            let height = self.crossTenantTipView.height(superViewW: self.view.frame.width)
            make.height.equalTo(shouldShowCrossTenantTips ? height : 0)
        }
    }

    private func configCollaboratorBottomView() {
        var config = CollaboratorBottomViewLayoutConfig()
        let mode = inviteVM.modeConfig.mode
        switch mode {
        case .manage:
            config.showNotification = true
            // 只要有一个可以发通知，按钮就能点
            config.isNotificationEnable = inviteVM.items.contains(where: \.canSendNotification)
            // Forms 用户组也支持发送通知
            if UserScopeNoChangeFG.WJS.baseFormShareNotificationV2, fileModel.isForm { config.isNotificationEnable = true }
            config.showHintLabel = true
            config.hintLabelText = fileModel.docsType.inviteHintText
            config.inviteButtonText = BundleI18n.SKResource.Doc_Share_CollaboratorInvite
            if inviteVM.source == .diyTemplate {
                config.showTextView = false
                config.inviteButtonText = BundleI18n.SKResource.Doc_List_Share
            }
            ///提示：允许协作者同时访问子页面
            if showSinglePageSelectView {
                config.showSinglePageView = true
                config.isChildPageEnable = isChildPageEnable
            }
        case .sendLink:
            config.showNotification = false
            config.showHintLabel = true
            config.hintLabelText = BundleI18n.SKResource.Doc_Permission_AskOwnerShare
            config.inviteButtonText = BundleI18n.SKResource.Doc_Permission_SendLink
            config.hintlabelTapEnable = true
        case .askOwner:
            config.showNotification = false
            config.showHintLabel = false
            config.hintLabelText = ""
            config.inviteButtonText = BundleI18n.SKResource.Doc_Permission_SendApply
            config.textViewPlaceHolder = BundleI18n.SKResource.Doc_Permission_AskOwner_placeholder(fileModel.displayName)
        }

        if inviteVM.needShowOptionBar == false {
            config.showNotification = false
            config.showHintLabel = false
            config.showTextView = false
        }

        // Bitable 不显示备注
        if fileModel.isFormV1 || fileModel.isBitableSubShare {
            config.showTextView = false
        }
        // Bitable 仪表盘下不显示发送链接
        if fileModel.isBitableSubShare {
            config.showHintLabel = false
            config.showNotification = false
        }
        // 邮箱协作者
        if hasEmailCollaborator {
            config.forceSelectNotification = true
        }
        if onlyEmailCollaborator {
            config.onlySinglePage = true
        }
        config.textViewHintText = BundleI18n.SKResource.Doc_Permission_PhoneNumberAddNoteTip
        self.collaboratorBottomView.setupUI(config)
        
        if hasOrganization && !hasEmailCollaborator {
            collaboratorBottomView.updateNotificationSelectState(isSelect: false)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        keyboard.stop()
    }
    
    ///有邀请协作者权限，无邀请外部协作者权限Ask Owner
    private func inviteExternal(callaborator: [Collaborator]) {
        //ask owner页面显示时退出后面的页面
        guard let fromVC = view.window?.rootViewController else {
            return
        }

        let vc = AskOwnerForInviteCollaboratorViewController(items: callaborator,
                                                    fileModel: fileModel,
                                                    layoutConfig: inviteVM.modeConfig,
                                                    statistics: inviteVM.statistics,
                                                    permStatistics: inviteVM.permStatistics)

        let isMyWindowRegularSize = self.isMyWindowRegularSize() && SKDisplay.pad
        let presentAskOwnerViewControllerBlock = {
            if isMyWindowRegularSize {
                vc.modalPresentationStyle = .formSheet
                vc.preferredContentSize = CGSize(width: 540, height: vc.getPopoverHeight())
                Navigator.shared.present(vc, from: fromVC, animated: false)
            } else {
                let nav = LkNavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .overFullScreen
                nav.update(style: .clear)
                Navigator.shared.present(nav, from: fromVC, animated: false)
            }
        }
        self.navigationController?.dismiss(animated: false, completion: {
            if SKDisplay.pad {
                presentAskOwnerViewControllerBlock()
            }
        })
        self.delegate?.dissmissSharePanel(animated: false, completion: {
            presentAskOwnerViewControllerBlock()
        })
    }

    ///是否显示 顶部单页面提示 “你邀请的协作者仅可访问当前页面”
    private var showSinglePageTips: Bool {
        if fileModel.isSyncedBlock {
            return false
        }
        return useSinglePagePermisson
    }

    ///是否显示提示 “允许协作者同时访问子页面”
    private var showSinglePageSelectView: Bool {
        guard fileModel.wikiV2SingleContainer,
           userPermissions?.canInviteCanView() == true else {
            return false
        }
        return true
    }

    /// 使用单页面权限进行判断
    private var useSinglePagePermisson: Bool {
        // 同步块固定用单页面权限
        if fileModel.isSyncedBlock {
            return true
        }
        /// wiki2.0 单页面需求： 展示了“允许协作者同时访问子页面”，但未勾选
        /// wiki2.0 单页面需求：仅有单页面权限，无容器权限, 不展示了“允许协作者同时访问子页面”
        var flag1 = false
        var flag2 = false
        if showSinglePageSelectView, !collaboratorBottomView.singlePageSelected {
            flag1 = true
        }
        if fileModel.wikiV2SingleContainer,
           self.userPermissions?.canInviteCanView() == false,
           self.userPermissions?.canSinglePageInviteCanView() == true {
            flag2 = true
        }
        return flag1 || flag2
    }


    // 是否显示顶部通知提示
    private var shouldShowNotificationTips: Bool {
        // 这里线上安卓iOS不一样，7.8版本和PM对齐，表单场景不显示顶部tips
        if UserScopeNoChangeFG.WJS.baseFormShareNotificationV2, fileModel.isForm { return false }
        guard !items.isEmpty else { return false }
        let mode = inviteVM.modeConfig.mode
        switch mode {
        case .manage:
            // 是否勾选发送通知的按钮
            let isSelect = collaboratorBottomView.isSelect
            // 协作者含有组织架构并且勾选了发送通知，需要提示
            if isSelect && hasOrganization {
                return true
            } else {
                return false
            }
        default:
            // 无分享权限时，为其它用户申请权限的Tips
            return fileModel.docsType.isBizDoc
        }
    }

    // 分享给外部时，顶部显示安全提示
    private var shouldShowCrossTenantTips: Bool {
        // 表单不显示
        if fileModel.isFormV1 || fileModel.isBitableSubShare { return false }
        // 自定义模板分享不考虑跨租户的情况
        if inviteVM.source == .diyTemplate { return false }
        // 小B不显示
        if User.current.info?.isToNewC == true {
            return false
        }
        // 无分享权限不显示
        if fileModel.docsType.isBizDoc && inviteVM.modeConfig.sharePermissionEnable == false {
            return false
        }
        // 和 owner 同租户分享给外部用户
        // 和 owner 不同租户分享文档给内部群
        if fileModel.isSameTenantWithOwner && CollaboratorUtils.containsExternalCollaborators(self.items) {
            return true
        } else if !fileModel.isSameTenantWithOwner && CollaboratorUtils.containsInternalGroupCollaborators(self.items) {
            return true
        } else {
            return false
        }
    }

    // 顶部提示内容, 以及需要被点击响应的 range
    private var notificationTips: (NSAttributedString, NSRange?) {
        let typeString: String = (fileModel.docsType == .minutes) ? BundleI18n.SKResource.CreationMobile_Minutes_name : BundleI18n.SKResource.Doc_Facade_Document
        let botName: String = (fileModel.docsType == .minutes) ? BundleI18n.SKResource.CreationMobile_Common_MinutesBot : BundleI18n.SKResource.CreatinoMobile_Minutes_bot_DocsAssist
        let ownerName = fileModel.displayName
        let mode = inviteVM.modeConfig.mode
        let paraph = NSMutableParagraphStyle()
        paraph.lineSpacing = 4
        let attributes = [NSAttributedString.Key.paragraphStyle: paraph]
        switch mode {
        case .manage:
            if collaboratorBottomView.isSelect {
                return (NSAttributedString(string: BundleI18n.SKResource.CreatinoMobile_Minutes_share_notification(botName), attributes: attributes), nil)
            } else {
                return (NSAttributedString(string: BundleI18n.SKResource.Doc_Permission_PhoneNumberNotificationTip, attributes: attributes), nil)
            }
        case .sendLink:
            if hasOrganization {
                return (NSAttributedString(string: BundleI18n.SKResource.Doc_Permission_SendLinkWithDepTips_AddVariable(typeString, botName), attributes: attributes), nil)
            } else {
                return (NSAttributedString(string: BundleI18n.SKResource.Doc_Permission_SendLinkTips_AddVariable(typeString), attributes: attributes), nil)
            }
        case .askOwner:
            let text = hasOrganization ? BundleI18n.SKResource.CreatinoMobile_Minutes_share_depart_dialog(typeString, "@" + ownerName, botName)
                :  BundleI18n.SKResource.Doc_Permission_AskOwnerToShare_AddVariable("@" + ownerName, typeString)
            let attributeString = NSMutableAttributedString(string: text, attributes: attributes)
            if let range = text.range(of: ownerName) {
                var nsRange = text.toNSRange(range)
                nsRange = NSRange(location: nsRange.location - 1, length: nsRange.length + 1)
                attributeString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.ud.colorfulBlue, range: nsRange)
                return (attributeString, nsRange)
            }
            return (attributeString, nil)
        }
    }

    // 协作者是否包含组织架构类型
    private var hasOrganization: Bool {
        return CollaboratorUtils.containsOrganizationCollaborators(self.items)
    }

    // 协作者是否包含多个组织架构类型
    private var hasMultiOrganization: Bool {
        return CollaboratorUtils.containsMultiOrganizationCollaborators(self.items)
    }

    // 协作者包含500人以上的大群
    private var hasLargeGroup: Bool {
        return CollaboratorUtils.containsLargeGroupCollaborators(self.items)
    }

    //邀请协作者失败toast
    func handleInviteCollaboratorsError(json: JSON) {
        /// cac管控: 这里是全部失败的情况
        let result = CollaboratorBlockStatusManager.getInviteResultsByCacBlocked(json: json)
        if result != .noFail {
            DocsLogger.info("inviteForBiz blocked by cac")
            self.showCacBlockedTips(result: result)
            return
        }

        let code = json["code"].intValue
        if let errorCode = ExplorerErrorCode(rawValue: code) {
            let errorEntity = ErrorEntity(code: errorCode, folderName: fileModel.displayName)
            self.showToast(text: errorEntity.wording, type: .failure)
            return
        }

        if code == 4,
           let names = CollaboratorBlockStatusManager.getAllNotPartnerTenantCollaboratorNames(json: json) {
            let tips: String
            if fileModel.isFolder {
                tips = BundleI18n.SKResource.CreationMobile_ECM_Security_Conflict_Confirm_Scenario7(names)
            } else {
                tips = BundleI18n.SKResource.CreationMobile_ECM_Security_Conflict_Confirm_Scenario4(names)
            }
            self.showToast(text: tips, type: .failure)
        }

        //需要显示ask owner面板 且 错误码为10005
        if shouldAskOwnerInviteExternal &&
            code == CollaboratorBlockStatusManager.ResponseCode.failForOwnerCloseShare.rawValue &&
            !inviteFailExternalCollaborator.isEmpty {
            //若邀请失败的外部协作者数量不为0，则弹出ask owner页面
            inviteExternal(callaborator: inviteFailExternalCollaborator)
            return
        }
        let manager = CollaboratorBlockStatusManager(requestType: .inviteCollaboratorsForFolder,
                                                     fromView: UIViewController.docs.topMost(of: self)?.view,
                                                     statistics: inviteVM.statistics)
        manager.showInviteCollaboratorsForBizFailedToast(json)
    }

    /// cell右侧显示删除图标
    private var shouldShowDeleteAccessoryViewAtCell: Bool {
        return inviteVM.modeConfig.mode == .sendLink || fileModel.isFormV1 || fileModel.isBitableSubShare
    }
}

extension CollaboratorInviteViewController {
    override func backBarButtonItemAction() {
        // 非栈顶，不能返回
        if let navigationController = self.navigationController,
           let index = index(of: self, in: navigationController),
           index != navigationController.viewControllers.count - 1 {
            DocsLogger.info("not at stack top")
            return
        }

        if self.fileInviteRequest?.state() == .completed || self.folderInviteRequest?.state() == .completed ||
            self.askOwnerRequest?.state() == .completed {
            backWhileRequestCompleted()
        } else if self.items.isEmpty {
            backWhileDeleteAllCollaborators()
        } else {
            reportBackClick()
            super.backBarButtonItemAction()
        }
    }

    private func backWhileRequestCompleted() {
        //请求完成
        checkIfNeedRemoveRepeatInviteVC()
        if isMyWindowRegularSizeInPad {
            dismiss(animated: true, completion: {[weak self] in
                guard let self = self, self.shouldShowBlockNotifyCollaboratorTips else { return }
                self.organizationDelegate?.dismissInviteCompletion(completion: {
                    self.inviteVM.permStatistics?.reportBlockNotifyAlertClick()
                })
            })
        } else {
            switch inviteVM.source {
            case .sharePanel, .sendLink:
                handleBackFromSharePanel()
            case .collaboratorEdit, .diyTemplate:
                handleBackFromCollaboratorEdit()
            }
        }
    }

    private func handleBackFromSharePanel() {
        let fromVC = view.window?.rootViewController
        let blockNotifyCollaboratorTips = { [weak self] in
            guard let fromVC = fromVC, let self = self else {
                return
            }
            let title = BundleI18n.SKResource.LarkCCM_Workspace_InviteOrg_MuteNotice_Content_Header
            let content = BundleI18n.SKResource.LarkCCM_Workspace_InviteOrg_MuteNotice_Content_Popup
            let buttonTitle = BundleI18n.SKResource.LarkCCM_Workspace_InviteOrg_MuteNotice_GotIt_Button
            let dialog = UDDialog()
            dialog.setTitle(text: title)
            dialog.setContent(text: content)
            dialog.addPrimaryButton(text: buttonTitle,
                             dismissCompletion: {
                dialog.dismiss(animated: false)
                self.inviteVM.permStatistics?.reportBlockNotifyAlertClick()
            })
            self.inviteVM.permStatistics?.reportBlockNotifyAlertView()
            Navigator.shared.present(dialog, from: fromVC)
        }
        if shouldShowBlockNotifyCollaboratorTips {
            organizationDelegate?.dismissSharePanelAndNotify(completion: blockNotifyCollaboratorTips)
        } else {
            delegate?.dissmissSharePanel(animated: false, completion: nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }

    private func handleBackFromCollaboratorEdit() {
        // 从协作者管理页面进来
        // 1. 如果是个人文件夹，需要把 SharePanel 也 Dismiss 掉
        // 2. 非个人文件夹，把目前整个 NavigationController pop 掉
        // 3. 如果邀请组织架构人数超过上限，需要dismiss SharePanel
        if fileModel.isCommonFolder {
            self.delegate?.dissmissSharePanel(animated: false, completion: nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
            self.navigationController?.dismiss(animated: true, completion: {[weak self] in
                guard let self = self, self.shouldShowBlockNotifyCollaboratorTips else {
                    return
                }
                self.organizationDelegate?.dismissInviteCompletion(completion: {
                    self.reportPermissionOrganizationAuthorizeSendNoticeClick(isCancel: false,
                                                                              candidates: Set(self.items))
                })
            })
        }
    }

    private var getCollaboratorSearchVCLastIndex: Int? {
        guard let vcs = self.navigationController?.viewControllers else { return nil }
        guard let searchVCIndex = vcs.firstIndex(where: { (vc) -> Bool in
            return vc is CollaboratorSearchViewController
        }) else { return nil }
        let lastVCIndex = searchVCIndex - 1
        guard lastVCIndex >= 0 else { return nil }
        return lastVCIndex
    }

    private func backWhileDeleteAllCollaborators() {
        //移除协作者
        checkIfNeedRemoveRepeatInviteVC()
        // 直接使用backBarButtonItemAction会把navigationController dismiss掉
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: popNeedAnimated())
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    private func index(of target: UIViewController, in navigation: UINavigationController) -> Int? {
        var target = target
        while !navigation.viewControllers.contains(target) {
            guard let parent = target.parent else {
                return nil
            }
            target = parent
        }
        return navigation.viewControllers.firstIndex(of: target)
    }

    private func removePreviousRepeatVC(of target: UIViewController, in navigation: UINavigationController) {
        if let index = index(of: self, in: navigation),
           index - 1 < navigation.viewControllers.count,
           navigation.viewControllers[index - 1] as? CollaboratorInviteViewController != nil {
            var viewControllers = navigation.viewControllers
            viewControllers.remove(at: index - 1)
            navigation.viewControllers = viewControllers
        }
    }
    
    private func removeOrganizationSearchVC(of target: UIViewController, in navigation: UINavigationController) {
        if let index = index(of: self, in: navigation),
           index - 1 < navigation.viewControllers.count,
           navigation.viewControllers[index - 1] as? OrganizationSearchViewController != nil {
            var viewControllers = navigation.viewControllers
            viewControllers.remove(at: index - 1)
            navigation.viewControllers = viewControllers
        }
    }

    private func checkIfNeedRemoveRepeatInviteVC() {
        guard inviteVM.modeConfig.isFromSendLink, let navigationController = self.navigationController  else {
            return
        }
        // nav堆栈层级  xx -> 发送链接界面 -> 邀请协作者界面
        // 从 发送链接页面 进入 邀请协作者界面
        // 1、邀请协作者成功返回 2、邀请协作者界面 移除协作者
        //移除中间一层 发送链接界面
        removePreviousRepeatVC(of: self, in: navigationController)
        if inviteVM.modeConfig.mode == .sendLink {
            removeOrganizationSearchVC(of: self, in: navigationController)
        }
    }

}

extension CollaboratorInviteViewController {
    func needShowOrganizationAlert() -> Bool {
        let notify = self.collaboratorBottomView.isSelect
        return notify && hasOrganization
    }
    func needShowEmailNotificationAlert() -> Bool {
        return items.contains(where: { $0.type == .email })
    }
    func showOrganizationAlert(completion: (() -> Void)? = nil) {
        self.inviteVM.permStatistics?.reportPermissionOrganizationAuthorizeSendNoticeView()
        let title = BundleI18n.SKResource.CreationMobile_Docs_AddCollaborator_department_notice_title
        let organizationItems = self.items.filter { $0.type == .organization }
        var name = ""
        if !organizationItems.isEmpty {
            let first = organizationItems.first
            name = first?.name ?? ""
        }
        var content: String = BundleI18n.SKResource.CreationMobile_Docs_AddCollaborator_department_notice_content_singular(name)
        if hasMultiOrganization {
            content = BundleI18n.SKResource.CreationMobile_Docs_AddCollaborator_department_notice_content_plural(organizationItems.count, name)
        }
        let dialog = UDDialog()
        dialog.setTitle(text: title)
        dialog.setContent(text: content)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion:  { [weak self] in
            guard let self = self else { return }
            self.reportPermissionOrganizationAuthorizeSendNoticeClick(isCancel: true, candidates: Set(self.items))
        })
        dialog.addDestructiveButton(text: BundleI18n.SKResource.CreationMobile_Docs_AddCollaborator_department_notice_confirm_btn, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            completion?()
            self.reportPermissionOrganizationAuthorizeSendNoticeClick(isCancel: false, candidates: Set(self.items))
        })
        present(dialog, animated: true, completion: nil)
    }

    func needShowGroupNotificationAlert() -> Bool {
        let notify = self.collaboratorBottomView.isSelect
        return notify && hasLargeGroup
    }
    func showGroupNotificationAlert(completion: (() -> Void)? = nil) {
        self.inviteVM.permStatistics?.reportPermissionOrganizationAuthorizeSendNoticeView()
        let title = BundleI18n.SKResource.CreationMobile_Docs_AddCollaborator_department_notice_title
        let content: String = BundleI18n.SKResource.CreationMobile_Docs_AddCollaborator_LargeGroup_notice_content

        let dialog = UDDialog()
        dialog.setTitle(text: title)
        dialog.setContent(text: content)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion:  { [weak self] in
            guard let self = self else { return }
            self.reportPermissionOrganizationAuthorizeSendNoticeClick(isCancel: true, candidates: Set(self.items))
        })
        dialog.addDestructiveButton(text: BundleI18n.SKResource.CreationMobile_Docs_AddCollaborator_department_notice_confirm_btn, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            completion?()
            self.reportPermissionOrganizationAuthorizeSendNoticeClick(isCancel: false, candidates: Set(self.items))
        })
        present(dialog, animated: true, completion: nil)
    }
    func showEmailNotificationAlert(completion: (() -> Void)? = nil) {
        let title: String
        
        let totalEmails = items.filter({ $0.type == .email }).map { item in
            return item.name
        }
        let emails = totalEmails.prefix(2).joined(separator: ",")
        let contentLabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 16)
            label.textColor = UIColor.ud.textTitle
            label.numberOfLines = 0
            return label
        }()
        

        let dialog = UDDialog()
        if fileModel.wikiV2SingleContainer && !useSinglePagePermisson {
            dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Docs_InviteEmail_Note_Header)
            let content: String
            if totalEmails.count > 1 {
                content = BundleI18n.SKResource.LarkCCM_Docs_InviteEmail_Note_PageViewOnly_Descrip(emails, totalEmails.count)
            } else {
                content = BundleI18n.SKResource.LarkCCM_Docs_Invite2Emails_Note_PageViewOnly_Descrip(emails)
            }
            dialog.setContent(text: content, alignment: .center)
        } else {
            dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Docs_InviteEmail_ConfirmInvite_Header())
            let content: String
            if totalEmails.count > 1 {
                content = BundleI18n.SKResource.LarkCCM_Docs_InviteEmail_ConfirmInvite_SendTo_Descrip(emails, totalEmails.count)
            } else {
                content = BundleI18n.SKResource.LarkCCM_Docs_Invite2Email_ConfirmInvite_SendTo_Descrip(emails)
            }
            dialog.setContent(text: content, caption: BundleI18n.SKResource.LarkCCM_Docs_InviteEmail_ConfirmInvite_Caution_Descrip)
        }
        dialog.addSecondaryButton(text: BundleI18n.SKResource.LarkCCM_Docs_InviteEmail_ConfirmInvite_Cancel_Button) { [weak self] in
            guard let self = self else { return }
            
        }
        dialog.addPrimaryButton(text: BundleI18n.SKResource.LarkCCM_Docs_InviteEmail_ConfirmInvite_Invite_Button, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            completion?()
        })
        present(dialog, animated: true, completion: nil)
    }

    // 无分享权限、链接分享 On 发送链接
    func inviteCollaboratorsBySendLink(larkIMText: String? = nil) {
        sendLinkForInviteCollaborator(larkIMText: larkIMText)
    }

    // 无分享权限、链接分享 Off 请求所有者共享
    func inviteCollaboratorsByAskOwner(larkIMText: String? = nil, dispalyName: String) {
        askOwnerForInviteCollaborator(larkIMText: larkIMText, dispalyName: dispalyName)
    }

    func inviteCollaborators(larkIMText: String? = nil) {
        handleInviteCollaboratos(larkIMText: larkIMText)
    }

    private func handleInviteCollaboratos(larkIMText: String? = nil) {
        if fileModel.isFormV1 || fileModel.isBitableSubShare {  //表单
            inviteForBitable()
        } else if fileModel.docsType.isBizDoc {
            var collaboratorSource: CollaboratorSource = .defaultType
            if fileModel.wikiV2SingleContainer {
                collaboratorSource = useSinglePagePermisson ? .singlePage : .container
            }
            inviteForBiz(collaboratorSource: collaboratorSource,
                         larkIMText: larkIMText)  //文档
        } else if fileModel.docsType == .folder { //文件夹、旧共享文件夹
            inviteForFolder(shouldContainPermssion: true)
        } else {
            spaceAssertionFailure()
            DocsLogger.error("不明确能否协作文档类型")
        }
    }

    /// 所有不发送通知的协作者 name字符串
    func getAllNotNotiCollaboratorNames(users: Any) -> String? {
        let json = JSON(users).arrayValue
        if json.isEmpty { return nil }

        let seperator = LanguageManager.currentLanguage == .en_US ? "," : "、"

        return json.map { (user) -> String in
            return user["name"].stringValue
        }.reduce("") { (result, name) -> String in
            return "\(result)\(seperator)\(name)"
        }.mySubString(from: 1)
    }
}

extension CollaboratorInviteViewController {
    @objc
    private func menuButtonAction(sender: CollaboratorInviteMenuButton) {
        guard let cell = sender.superview as? UITableViewCell,
              let indexPath = self.collaboratorInvitationTableView.indexPath(for: cell) else {
            return
        }

        if shouldShowDeleteAccessoryViewAtCell {
            self.items.remove(at: indexPath.row)
            self.collaboratorInvitationTableView.deleteRows(at: [indexPath], with: .automatic)
            self.inviteVM.permStatistics?.reportPermissionSendLinkClick(click: .delete, target: .noneTargetView)
            return
        }

        guard indexPath.row >= 0, indexPath.row < self.items.count else { return }
        let item = self.items[indexPath.row]
        let titleFont = UIFont.systemFont(ofSize: 16, weight: .regular)

        /*
         /// 文件、文件夹、共享文件夹 添加协作者。
         */
        reportPermissionShareAskOwnerTypeView(collaborateType: item.rawValue, objectUid: item.userID)

        /// 当前选中的权限
        let isSelectedFullAccessable = item.userPermissions.canManageMeta()
        let isSelectedEdit = !isSelectedFullAccessable && item.userPermissions.canEdit()
        let isSelectedView = !isSelectedFullAccessable && !isSelectedEdit && item.userPermissions.canView()

        /// 可被选择的权限
        var canSelectEdit = self.userPermissions?.canInviteCanEdit() ?? false
        var canSelectFullAccess = self.userPermissions?.canInviteFullAccess() ?? false

        /// wiki2.0 单页面需求： 展示了“允许协作者同时访问子页面”，但未勾选
        /// wiki2.0 单页面需求：仅有单页面权限，无容器权限
        if useSinglePagePermisson {
             canSelectEdit = self.userPermissions?.canSinglePageInviteCanEdit() ?? false
             canSelectFullAccess = self.userPermissions?.canSinglePageInviteFullAccess() ?? false
        }

        ///askowner特化
        if inviteVM.modeConfig.mode == .askOwner {
            canSelectEdit = true
        }

        let sheet = DocsAlertController()
        if SKDisplay.pad, view.isMyWindowRegularSize() {
            sheet.modalPresentationStyle = .popover
            sheet.popoverPresentationController?.sourceView = sender
            sheet.popoverPresentationController?.sourceRect = sender.bounds
            sheet.popoverPresentationController?.permittedArrowDirections = .right
        }
        sheet.watermarkConfig.needAddWatermark = watermarkConfig.needAddWatermark
        sheet.supportOrientations = self.supportedInterfaceOrientations
        sheet.setTitleColor(UDColor.textTitle)
        let contextFullAccess: PermissionPlaceHolderContext
        let contextEditAction: PermissionPlaceHolderContext
        let contextReadAction: PermissionPlaceHolderContext
        let contextRemoveAction: RemovePermissionPlaceHolderContext
        let type = fileModel.docsType
        if type.isBizDoc { //文件
            contextFullAccess = PermissionPlaceHolderContext(sheet: sheet, sender: sender, isSelected: isSelectedFullAccessable, canBeSelected: canSelectFullAccess, collaborator: item, titleFont: titleFont, needSubtitle: true)
            contextEditAction = PermissionPlaceHolderContext(sheet: sheet, sender: sender, isSelected: isSelectedEdit, canBeSelected: canSelectEdit, collaborator: item, titleFont: titleFont, needSubtitle: false)
            contextReadAction = PermissionPlaceHolderContext(sheet: sheet, sender: sender, isSelected: isSelectedView, canBeSelected: true, collaborator: item, titleFont: titleFont, needSubtitle: false)
            contextRemoveAction = RemovePermissionPlaceHolderContext(sheet: sheet, sender: sender, indexPath: indexPath, title: BundleI18n.SKResource.Doc_Facade_Delete, collaborator: item, titleFont: titleFont, isCreate: false, needReport: false)
            addFullAccessActionIfNeed(context: contextFullAccess)
            addEditActionIfNeed(context: contextEditAction)
            addReadActionIfNeed(context: contextReadAction)
            addRemoveActionIfNeed(context: contextRemoveAction)

        } else if fileModel.isFolder {//普通文件夹，老共享
            if fileModel.spaceSingleContainer && fileModel.isFolder {
                contextFullAccess = PermissionPlaceHolderContext(sheet: sheet, sender: sender, isSelected: isSelectedFullAccessable, canBeSelected: self.userPermissions?.canInviteFullAccess() ?? false, collaborator: item, titleFont: titleFont, needSubtitle: true)
                contextEditAction = PermissionPlaceHolderContext(sheet: sheet, sender: sender, isSelected: isSelectedEdit, canBeSelected: self.userPermissions?.canInviteCanEdit() ?? false, collaborator: item, titleFont: titleFont, needSubtitle: false)
                contextReadAction = PermissionPlaceHolderContext(sheet: sheet, sender: sender, isSelected: isSelectedView, canBeSelected: true, collaborator: item, titleFont: titleFont, needSubtitle: false)
                contextRemoveAction = RemovePermissionPlaceHolderContext(sheet: sheet, sender: sender, indexPath: indexPath, title: BundleI18n.SKResource.Doc_List_Remove, collaborator: item, titleFont: titleFont, isCreate: false, needReport: false)
                addFullAccessActionIfNeed(context: contextFullAccess)
                addEditActionIfNeed(context: contextEditAction)
                addReadActionIfNeed(context: contextReadAction)
                addRemoveActionIfNeed(context: contextRemoveAction)
            } else {
                contextEditAction = PermissionPlaceHolderContext(sheet: sheet, sender: sender, isSelected: isSelectedEdit, canBeSelected: canSelectEdit, collaborator: item, titleFont: titleFont, needSubtitle: true)
                contextReadAction = PermissionPlaceHolderContext(sheet: sheet, sender: sender, isSelected: isSelectedView, canBeSelected: true, collaborator: item, titleFont: titleFont, needSubtitle: true)
                contextRemoveAction = RemovePermissionPlaceHolderContext(sheet: sheet, sender: sender, indexPath: indexPath, title: BundleI18n.SKResource.Doc_List_Remove, collaborator: item, titleFont: titleFont, isCreate: false, needReport: false)
                addEditActionIfNeed(context: contextEditAction)
                addReadActionIfNeed(context: contextReadAction)
                addRemoveActionIfNeed(context: contextRemoveAction)
            }
        } else {
            spaceAssertionFailure()
            DocsLogger.error("不明确能否协作文档类型")
        }

        sheet.setHeaderView({
            let view = CollaboratorInviteWidgetHeaderView()
            view.frame.size.height = 86
            view.frame.size.width = self.contentView.bounds.width
            view.updateInfo(item: item)
            return view
            }()
        )
        present(sheet, animated: true, completion: nil)
    }
    
    private func shouldShowExternalLabel(item: Collaborator) -> Bool {
        // 1. 外部或跨租户的文档 2. 套件大B用户
        if (item.isExternal || item.isCrossTenant) && EnvConfig.CanShowExternalTag.value {
            return true
        } else {
            return false
        }
    }
    
    private func addFullAccessActionIfNeed(context: PermissionPlaceHolderContext) {
        if context.collaborator.type == .email {
            return
        }
        /// askowner 不支持 fullAccess
        if inviteVM.modeConfig.mode == .askOwner {
            return
        }
        if !fileModel.wikiV2SingleContainer && !fileModel.spaceSingleContainer {
            return
        }
        let fullAccessAction = AlertAction(title: BundleI18n.SKResource.CreationMobile_Wiki_Permission_FullAccess_Options,
                                           style: .option,
                                           horizontalAlignment: .left,
                                           isSelected: context.isSelected,
                                           canBeSelected: context.canBeSelected,
                                           handler: { [weak self] in
                                            guard let self = self else { return }
            context.sender.setTitle(BundleI18n.SKResource.CreationMobile_Wiki_Permission_FullAccess_Options, for: .normal)
            context.collaborator.userPermissions = context.collaborator.userPermissions.updatePermRoleType(permRoleType: .fullAccess)
                                            self.collaboratorInvitationTableView.reloadData()
                                            self.layoutTopNotificationTips()
                                           })
        fullAccessAction.titleFont = context.titleFont
        if context.needSubtitle {
            if fileModel.isSyncedBlock {
                fullAccessAction.subtitle = BundleI18n.SKResource.LarkCCM_Docs_SyncBlock_Collab_Manage_Descrip
            } else if fileModel.wikiV2SingleContainer {
                fullAccessAction.subtitle = BundleI18n.SKResource.CreationMobile_Wiki_Permission_FullAccessPermission_Tooltip
            } else {
                fullAccessAction.subtitle = BundleI18n.SKResource.CreationMobile_ECM_AllPermissionDesc
            }
        }
        context.sheet.add(fullAccessAction)
    }
    
    private func addReadActionIfNeed(context: PermissionPlaceHolderContext) {
        let readableAction = AlertAction(title: BundleI18n.SKResource.Doc_Share_Readable,
                                         style: .option,
                                         horizontalAlignment: .left,
                                         isSelected: context.isSelected,
                                         canBeSelected: context.canBeSelected,
                                         needSeparateLine: true,
                                         handler: { [weak self] in
            self?.reportPermissionChangeClick(click: .read, collaborateType: context.collaborator.rawValue, objectUid: context.collaborator.userID)
            context.sender.setTitle(BundleI18n.SKResource.Doc_Share_Readable, for: .normal)
            context.collaborator.userPermissions = context.collaborator.userPermissions.updatePermRoleType(permRoleType: .viewer)
                                            self?.collaboratorInvitationTableView.reloadData()
                                            self?.layoutTopNotificationTips()
        })
        readableAction.titleFont = context.titleFont
        if context.needSubtitle {
            readableAction.subtitle = BundleI18n.SKResource.Doc_Share_ViewFiles
        }
        context.sheet.add(readableAction)
    }

    private func addEditActionIfNeed(context: PermissionPlaceHolderContext) {
        if context.collaborator.type == .email {
            return
        }
        let editableAction = AlertAction(title: BundleI18n.SKResource.Doc_Share_Editable,
                                         style: .option,
                                         horizontalAlignment: .left,
                                         isSelected: context.isSelected,
                                         canBeSelected: context.canBeSelected,
                                         handler: { [weak self] in
            self?.reportPermissionChangeClick(click: .edit, collaborateType: context.collaborator.rawValue, objectUid: context.collaborator.userID)
            context.sender.setTitle(BundleI18n.SKResource.Doc_Share_Editable, for: .normal)
            context.collaborator.userPermissions = context.collaborator.userPermissions.updatePermRoleType(permRoleType: .editor)
                                            self?.collaboratorInvitationTableView.reloadData()
                                            self?.layoutTopNotificationTips()
        })
        editableAction.titleFont = context.titleFont
        if context.needSubtitle {
            editableAction.subtitle = BundleI18n.SKResource.Doc_Share_AddAndEditFile
        }
        context.sheet.add(editableAction)
    }

    private func addRemoveActionIfNeed(context: RemovePermissionPlaceHolderContext) {
        let removePermissionsAction = AlertAction(title: context.title,
                                                  style: .destructive,
                                                  horizontalAlignment: .left,
                                                  isSelected: false,
                                                  canBeSelected: true,
                                                  handler: { [weak self] in
            guard let self = self else { return }
            guard context.indexPath.row >= 0, context.indexPath.row < self.items.count else { return }
            self.reportPermissionChangeClick(click: .delete, collaborateType: context.collaborator.rawValue, objectUid: context.collaborator.userID)
            self.items.remove(at: context.indexPath.row)
            self.collaboratorInvitationTableView.deleteRows(at: [context.indexPath], with: .automatic)
            if context.needReport {
                self.inviteVM.statistics?.clickEditRoleType(actionType: .delete, isCreate: false, objToken: self.fileModel.objToken, collaborator: context.collaborator)
            }
            self.layoutTopNotificationTips()
            self.configCollaboratorBottomView()
        })
        removePermissionsAction.titleFont = context.titleFont
        context.sheet.add(removePermissionsAction)
    }
}

extension CollaboratorInviteViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datas.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: CollaboratorSearchResultCell
        if let tempCell = (tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as? CollaboratorSearchResultCell) {
            cell = tempCell
        } else {
            cell = CollaboratorSearchResultCell(style: .subtitle, reuseIdentifier: cellReuseIdentifier)
        }
        guard indexPath.row >= 0, indexPath.row < datas.count else { return UITableViewCell() }
        cell.update(item: datas[indexPath.row])
        cell.backgroundColor = UDColor.bgBody
        cell.hideSeperator = true
        return cell
    }
}

extension CollaboratorInviteViewController: UITableViewDelegate {
    private func addPermissonEditButton(willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if inviteVM.source == .diyTemplate {
            // 如果是从自定义模板过来的，就不显示权限编辑项目
            return
        }
        let button = CollaboratorInviteMenuButton()
        button.addTarget(self, action: #selector(menuButtonAction(sender:)), for: .touchUpInside)
        let type = fileModel.docsType
        if type.isBizDoc {// suite
            button.setTitle(self.items[indexPath.row].userPermissions.permRoleType.titleText, for: .normal)
            button.setImage(BundleResources.SKResource.Common.Collaborator.permission_optionArrow.ud.withTintColor(UDColor.iconN2), for: .normal)
        } else if fileModel.isCommonFolder || fileModel.isShareFolder {//普通文件夹 & 老共享文件夹
            button.setTitle(self.items[indexPath.row].userPermissions.permRoleType.titleText, for: .normal)
            button.setImage(BundleResources.SKResource.Common.Collaborator.permission_optionArrow.ud.withTintColor(UDColor.iconN2), for: .normal)
        } else {
            spaceAssertionFailure()
            DocsLogger.error("不明确能否协作文档类型")
        }

        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.sizeToFit()
        button.docs.addStandardHighlight()
        cell.accessoryView = button
    }

    private func addDeleteButton(willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let button = CollaboratorInviteMenuButton()
        if fileModel.isFormV1 || fileModel.isBitableSubShare {
            button.setImage(BundleResources.SKResource.Common.Collaborator.collaborators_form_remove.ud.withTintColor(UDColor.iconN2), for: .normal)
        } else {
            button.setImage(BundleResources.SKResource.Common.Collaborator.collaborators_remove.ud.withTintColor(UDColor.iconN2), for: .normal)
        }
        button.addTarget(self, action: #selector(menuButtonAction(sender:)), for: .touchUpInside)
        button.sizeToFit()
        button.docs.addStandardHighlight()
        cell.accessoryView = button
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row >= 0 && indexPath.row < self.items.count else {
            return
        }
        if shouldShowDeleteAccessoryViewAtCell {
            addDeleteButton(willDisplay: cell, forRowAt: indexPath)
        } else {
            addPermissonEditButton(willDisplay: cell, forRowAt: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row >= 0 && indexPath.row < self.items.count else { return 0 }
        let currentItem = datas[indexPath.row]
        return currentItem.roleType == .email ? 86 : 66
    }
}

extension CollaboratorInviteViewController {
    func getParamsForSelectItems() -> [String: String] {
        var params = [String: String]()
        guard !items.isEmpty else { return [:] }
        let item = items[0]
        guard item.tenantID != nil else { return [:] }
        params["collab_tenant_id"] = DocsTracker.encrypt(id: item.tenantID ?? "")
        params["collab_is_cross_tenant"] = (item.tenantID != User.current.info?.tenantID) ? "true" : "false"
        for item in items where item.isExternal {
            params["collab_tenant_id"] = DocsTracker.encrypt(id: item.tenantID ?? "")
            params["collab_is_cross_tenant"] = (item.tenantID != User.current.info?.tenantID) ? "true" : "false"
            break
        }
        return params
    }
    func getTenantParams() -> [String: String] {
        var params = [String: String]()
        let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
        if let fileTenantID = dataCenterAPI?.userInfo(for: fileModel.ownerID)?.tenantID {
            params["file_tenant_id"] = DocsTracker.encrypt(id: fileTenantID)
            let isCrossTenant = fileTenantID == User.current.info?.tenantID ? "false" : "true"
            params["file_is_cross_tenant"] = isCrossTenant
        }
        return params
    }
}

extension CollaboratorInviteViewController: CollaboratorInviteViewControllerDelegate {
    func dissmissSharePanel(animated: Bool, completion: (() -> Void)?) {
        self.delegate?.dissmissSharePanel(animated: animated, completion: completion)
    }

    func collaboardInvite(_ collaboardInvite: CollaboratorInviteViewController, didUpdateWithItems items: [Collaborator]) {
        self.items = items
        self.collaboratorInvitationTableView.reloadData()
    }
}

extension CollaboratorInviteViewController: CollaboratorBottomViewDelegate {
    func handleSinglePageSelectViewClicked(_ bottomView: CollaboratorBottomView, isSelect: Bool) {
        isChildPageEnable = isSelect
    }

    func handleButtonClicked(_ bottomView: CollaboratorBottomView, isSelect: Bool) {
        layoutTopNotificationTips()
    }
    
    func handleForceSelectNotificationIcon(_ bottomView: CollaboratorBottomView) {
        if bottomView.userGroupDisAble {
            showToast(text: BundleI18n.SKResource.LarkCCM_Workspace_AddUserGroup_CantSendInvite_Tooltip, type: .tips)
            return
        }
        showToast(text: BundleI18n.SKResource.LarkCCM_Docs_InviteEmail_SendNote_Required_Tooltip, type: .tips)
    }
    
    func handleForceSelectSinglePageIcon(_ bottomView: CollaboratorBottomView) {
        showToast(text: BundleI18n.SKResource.LarkCCM_Wiki_InviteEmail_CurrentPageOnly_Descrip, type: .tips)
    }
    
    func updateCollaboratorBottomViewConstraints(_ bottomView: CollaboratorBottomView) {
        if collaboratorBottomView.isSelect && inviteVM.needShowOptionBar {
        } else {
            // 取消选择时收起键盘
            if collaboratorBottomView.textView.isFirstResponder {
                collaboratorBottomView.textView.resignFirstResponder()
            }
        }
        view.layoutIfNeeded()
    }

    func handleHintLabelClicked(_ view: CollaboratorBottomView) {
        let layoutConfig = inviteVM.modeConfig
        var config = CollaboratorInviteModeConfig(mode: layoutConfig.mode,
                                                      linkShareEnable: layoutConfig.linkShareEnable,
                                                      sharePermissionEnable: layoutConfig.sharePermissionEnable)
        config.updateLayoutType(.askOwner)
        let vm = CollaboratorInviteVCDependency(fileModel: fileModel,
                                             items: self.items,
                                             layoutConfig: config,
                                             needShowOptionBar: true,
                                             source: .sendLink,
                                             statistics: inviteVM.statistics,
                                             permStatistics: inviteVM.permStatistics,
                                             userPermisson: userPermissions)
        let vc = CollaboratorInviteViewController(vm: vm)
        vc.watermarkConfig.needAddWatermark = self.watermarkConfig.needAddWatermark
        vc.delegate = self
        vc.supportOrientations = self.supportedInterfaceOrientations
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension CollaboratorInviteViewController: UIScrollViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // 滚动时收起键盘
        if collaboratorBottomView.textView.isFirstResponder {
            collaboratorBottomView.textView.resignFirstResponder()
        }
    }
}

extension CollaboratorInviteViewController: PermissionTopTipViewDelegate {
    func handleTitleLabelClicked(_ tipView: PermissionTopTipView, index: Int, range: NSRange) {
        guard fileModel.ownerID.isEmpty == false else {
            DocsLogger.info("userId is nil")
            return
        }
        let params = ["type": fileModel.docsType.rawValue]
        HostAppBridge.shared.call(ShowUserProfileService(userId: fileModel.ownerID, fileName: fileModel.displayName, fromVC: self, params: params))
    }
}

extension CollaboratorInviteViewController {
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        guard let view = (self.view.window ?? Navigator.shared.mainSceneWindow) else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type)
    }
}
