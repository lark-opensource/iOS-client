//
//  File.swift
//  SpaceKit
//
//  Created by Webster on 2019/3/7.
//  swiftlint:disable file_length

import SKFoundation
import SwiftyJSON
import LarkUIKit
import SKResource
import SnapKit
import SKUIKit
import UniverseDesignToast
import UniverseDesignColor
import RxSwift
import UIKit
import UniverseDesignNotice
import LarkReleaseConfig
import EENavigator
import SpaceInterface

private extension ShareDocsType {
    var sharePanelTitle: String {
        switch self {
        case .form:
            return BundleI18n.SKResource.Bitable_Form_ShareForm
        case .bitableSub(let subType):
            switch subType {
            case .form:
                return BundleI18n.SKResource.Bitable_Form_ShareForm
            case .view:
                return BundleI18n.SKResource.Bitable_Share_ShareThisView_Title
            case .record:
                return BundleI18n.SKResource.Bitable_Share_ShareThisRecord_Title
            case .dashboard, .dashboard_redirect:
                return BundleI18n.SKResource.Bitable_Share_ShareThisDashboard_Title
            case .addRecord:
                return BundleI18n.SKResource.Bitable_QuickAdd_ShareThisPage_Button
            }
        default:
            return BundleI18n.SKResource.LarkCCM_Docs_SendToChat_Button_Mob
        }
    }
    
    var inviteMemberTitle: String {
        switch self {
        case .form:
            return BundleI18n.SKResource.Bitable_Form_InviteCollaborator
        case .bitableSub(let subType):
            switch subType {
            case .form:
                return BundleI18n.SKResource.Bitable_Form_InviteCollaborator
            case .view, .record, .dashboard_redirect, .dashboard, .addRecord:
                return BundleI18n.SKResource.Bitable_Share_InviteViewers_Title
            }
        default:
            return BundleI18n.SKResource.LarkCCM_Docs_InviteCollaborators_Menu_Mob
        }
    }
    
    var membersDisplayTitle: String {
        switch self {
        case .form:
            return BundleI18n.SKResource.Bitable_Form_ManageCollaborator
        case .bitableSub(let subType):
            switch subType {
            case .form:
                return BundleI18n.SKResource.Bitable_Form_ManageCollaborator
            case .view, .record, .dashboard_redirect, .dashboard, .addRecord:
                return BundleI18n.SKResource.Bitable_Share_Viewers_Description
            }
        case .sync:
            return BundleI18n.SKResource.Doc_Permission_CollaboratorManagement
        default:
            return BundleI18n.SKResource.Doc_Share_Collaborators
        }
    }
}

protocol CollaborationAssistViewDelegate: AnyObject {
    func openCollaboratorEditViewController(view: CollaborationAssistView,
                                            collaborators: [Collaborator],
                                            containerCollaborators: [Collaborator],
                                            singlePageCollaborators: [Collaborator])
    func openCollaboratorSearchViewController(view: CollaborationAssistView,
                                                     collaborators: [Collaborator]?,
                                                     lastPageLabel: String?,
                                                     needActivateKeyboard: Bool,
                                                     source: CollaboratorInviteSource)
    func onRemindNotificationViewClick()
    func requestExportSnapShot(view: CollaborationAssistView)
    func requestSlideExport(view: CollaborationAssistView)
    func requestShareToOtherApp(view: CollaborationAssistView, activityViewController: UIViewController?)
    func shouldDisplaySnapShotItem() -> Bool
    func shouldDisplaySlideExport() -> Bool
    func openShareLinkEditViewController(view: UIView, chosenType: ShareLinkChoice?)
    func openPublicPermissionViewController(view: CollaborationAssistView)
    func shouldDisplayCopyLinkAlertSheet(view: UIView, iphoneAlert: UIViewController, ipaAlert: UIViewController)
    func didClickShareLinkToExternal(view: UIView, completion: (() -> Void)?)

    func sharePanelConfigInfo(view: CollaborationAssistView) -> SharePanelConfigInfoProtocol?
    func requestDisplayUserProfile(userId: String, fileName: String?)
    func didClickRecoverButton(view: CollaborationAssistView)
    func didClickShareToByteDanceMoments(_ url: URL)
    func requestHostViewController() -> UIViewController?
    func requestFollowAPIDelegate() -> BrowserVCFollowDelegate?
    func requestShareToLarkServiceFromViewController() -> UIViewController?

    /// bitable switch 被点击
    func didClickBitablePanelAccessSwitch(flag: Bool, callback: @escaping () -> ())
    func didClickBitableAdPermPanel()

    func didClickClose()
    
    func didClickCopyLink()

    func didClickCopyPasswordLink(enablePasswordShare: Bool)
    
    func didClicked(type: ShareAssistType)
    
    func currentPresentationStyle() -> UIModalPresentationStyle
    func didClickLearnMoreButton()
}

/// 分享页面唤起的view 之前叫ShareView
/// 从功能上来看这块主要是进行协作编辑相关的辅助操作，在此命名成为CollaborationAssistView更加接近实际功能一些
/// 包含两个入口 CollaboratorManagerEntryPanel 和 ShareAssistPanel
/// TODO: Refactor
class CollaborationAssistView: UIView, UDNoticeDelegate, RemindNotificationViewDelegate {
    
    var isNewFormV2: Bool {
        shareEntity.formsShareModel != nil
    }
    
    lazy var shareToLabel: UIView = {
        let contain = UIView()
        
        let top = UIView()
        
        let view = UILabel()
        view.font = .systemFont(ofSize: 14)
        view.textColor = UDColor.textCaption
        view.text = BundleI18n.SKResource.Bitable_NewSurvey_Settings_ShareTo_Title
        
        contain.addSubview(top)
        contain.addSubview(view)
        
        top.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(12)
        }
        
        view.snp.makeConstraints { make in
            make.top.equalTo(top.snp.bottom)
            make.bottom.left.right.equalToSuperview()
        }
        
        return contain
    }()
    
    lazy var invitePeopleLabel: UIView = {
        let contain = UIView()
        
        let top = UIView()
        
        let view = UILabel()
        view.font = .systemFont(ofSize: 14)
        view.textColor = UDColor.textCaption
        view.text = BundleI18n.SKResource.Bitable_NewSurvey_Settings_InviteRespondents_Title
        
        contain.addSubview(top)
        contain.addSubview(view)
        
        top.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(12)
        }
        
        view.snp.makeConstraints { make in
            make.top.equalTo(top.snp.bottom)
            make.bottom.left.right.equalToSuperview()
        }
        
        return contain
    }()
    
    private(set) var shareEntity: SKShareEntity
    /// delegate
    weak var delegate: CollaborationAssistViewDelegate?
    /// 分享辅助面板高度
    
    /// 给lark动态注入的view🤣🤣🤣
    private var accessory: UIView?
    
    /// 判断是否有消息提醒 view
    private var hasAccessoryView = false
    /// 不需要重用的 bag
    private let disposeBag = DisposeBag()
    
    private(set) var publicPermissions: PublicPermissionMeta?
    private var unlockPermissionRequest: DocsRequest<Bool>?
    
    public var viewModel: SKShareViewModel
    ///请求用户权限完成
    private var fetchUserPermCompleted: Bool = false
    
    private lazy var panelHeaderView: SKPanelHeaderView = {
        let view = SKPanelHeaderView()
        let newForm = isNewForm || isNewFormUser
        var title = shareEntity.type.sharePanelTitle
        if newForm {
            if isNewFormUser {
                title = BundleI18n.SKResource.Bitable_NewSurvey_General_Share_Button
            } else {
                title = BundleI18n.SKResource.Bitable_NewSurvey_General_Publish_Button
            }
        }
        if isNewFormV2 {
            title = shareEntity.formsShareModel?.panelTitle ?? ""
        }
        if shareEntity.isSyncedBlock {
            title = BundleI18n.SKResource.LarkCCM_Docs_SyncBlock_ManageCollaborators_Title
        }
        view.setTitle(title)
        view.setCloseButtonAction(#selector(didClickHeaderPanelCloseButton), target: self)
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var tipView: UDNotice = {
        let notice = UDNotice(config: .init(type: .info, attributedText: .init(string: "")))
        notice.isHidden = true
        notice.delegate = self
        return notice
    }()
    public func handleLeadingButtonEvent(_ button: UIButton) {
        // 目前仅表单分享场景有这个按钮，如新增场景请做判断
        delegate?.didClickLearnMoreButton()
    }
    public func handleTrailingButtonEvent(_ button: UIButton) {}
    public func handleTextButtonEvent(URL: URL, characterRange: NSRange) {}

    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private lazy var closeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = .clear
        btn.setTitle(BundleI18n.SKResource.Doc_Facade_Cancel, for: .normal)
        btn.setTitleColor(UDColor.textTitle, for: .normal)
        btn.addTarget(self, action: #selector(didClickHeaderPanelCloseButton), for: .touchUpInside)
        return btn
    }()
    
    private lazy var sepratelineView: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    // 分享面板整体是一个 stackView
    // 非 bitable 表单场景:
    // [unlockView]-0-[spacingView]-16-[collaboratorsSection]-16-[linkShareSection]-16-[shareAssistPanel]
    //
    // bitable 场景:
    // [spacingView]-16-[bitableShareSection]-16-[collaboratorsSection]-16-[shareAssistPanel]
    private lazy var sectionStackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.alignment = .center
        view.distribution = .fill
        view.spacing = 16
        return view
    }()

    // Space 2.0 的文件夹内的文档，权限被限制的场景
    private lazy var permissionUnlockView: PermissionUnlockView = {
        let view = PermissionUnlockView()
        view.backgroundColor = UDColor.B100
        view.isHidden = true
        view.recoverButtonCallback = { [weak self] in
            guard let self = self else { return }
            self.delegate?.didClickRecoverButton(view: self)
        }
        return view
    }()

    private lazy var bitableSwitchPanel: ShareBitablePanel = {
        let view = ShareBitablePanel()
        view.accessSwitch.setOn(false, animated: false)
        if UserScopeNoChangeFG.ZYS.dashboardShare {
            if shareEntity.isFormV1, let meta = shareEntity.formShareFormMeta {
                view.updateBy(meta)
            } else if shareEntity.isBitableSubShare, let subType = shareEntity.bitableSubType {
                let state = shareEntity.bitableShareEntity?.isShareOn ?? false
                view.update(subType: subType, switchEnable: state)
            }
        }
        return view
    }()
    
    lazy var formsNotifyMeView: FormsNotifyMeView = {
        let view = FormsNotifyMeView()
        view.accessSwitch.isOn = shareEntity.formsShareModel?.noticeMe == true
        view.accessSwitch.clickCallback = { [weak self] (switchView: UISwitch) in
            switchView.isOn = !switchView.isOn
            self?.shareEntity.formsCallbackBlocks.noticeMeClick?(switchView.isOn)
        }
        return view
    }()

    // 底部分享渠道列表
    private lazy var sharePanel: ShareAssistPanel = {
        let view = ShareAssistPanel(shareEntity,
                                    delegate: self,
                                    source: source,
                                    viewModel: viewModel)
        view.reporter = reporter
        return view
    }()
    
    private var shareLinkSectionView = UIStackView()

    // 链接分享状态、开关
    private lazy var shareLinkEntrance: ShareLinkEntrancePanel = {
        let view = ShareLinkEntrancePanel(shareEntity, delegate: self)
        view.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
        let showShowBottomSplit = !shareEntity.isFormV1 && !shareEntity.isBitableSubShare
        view.showSplitBottom(show: showShowBottomSplit)
        return view
    }()

    // 权限设置入口
    private lazy var permissionSettingsPanel: SharePermissionPanel = {
        let view = SharePermissionPanel()
        view.delegate = self
        view.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
        view.arrowImageView.isHidden = shareEntity.isSyncedBlock
        return view
    }()
    
    // Bitable 权限设置入口
    private lazy var baseAdPermPanel: BitableAdPermPanel = {
        let vi = BitableAdPermPanel()
        vi.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
        vi.addTarget(self, action: #selector(onBaseAdPermClick(_:)), for: .touchUpInside)
        return vi
    }()

    // 邀请协作者入口
    private lazy var inviteCollaboratorsPanel: InviteCollaboratorsPanel = {
        let panel = InviteCollaboratorsPanel(frame: .zero)
        panel.delegate = self
        panel.titleLabel.text = shareEntity.type.inviteMemberTitle
        panel.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
        return panel
    }()

    // 协作者管理入口、协作者列表
    private lazy var collaboratorPanel: CollaboratorManagerEntryPanel = {
        let view = CollaboratorManagerEntryPanel(shareEntity)
        view.titleLabel.text = shareEntity.type.membersDisplayTitle
        view.delegate = self
        view.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
        return view
    }()
    
    private lazy var remindNotificationView: RemindNotificationView = {
        let view = RemindNotificationView()
        view.delegate = self
        view.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
        return view
    }()
    
    func onRemindNotificationViewClick() {
        delegate?.onRemindNotificationViewClick()
    }

    // Bitable链接分享关闭时，点击其他位置需要 toast 提醒
    private lazy var bitableMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapBitableMaskView)))
        return view
    }()

    private lazy var reporter: CollaboratorStatistics = {
        let info = CollaboratorAnalyticsFileInfo(fileType: shareEntity.type.name, fileId: shareEntity.objToken)
        let obj = CollaboratorStatistics(docInfo: info, module: source.rawValue)
        return obj
    }()
    
    private var source: ShareSource = .list
    
    var collaboratorSection: UIStackView?
    
    private let headerHeight: CGFloat = 48
    
    var isNewForm: Bool {
        viewModel.isNewForm
    }
    var isNewFormUser: Bool {
        viewModel.isNewFormUser
    }
    var formEditable: Bool? {
        viewModel.formEditable
    }

    init(_ shareEntity: SKShareEntity,
         accessory: UIView? = nil,
         delegate: CollaborationAssistViewDelegate? = nil,
         source: ShareSource,
         viewModel: SKShareViewModel) {
        self.viewModel = viewModel
        self.shareEntity = shareEntity
        super.init(frame: .zero)
        self.delegate = delegate
        self.accessory = accessory
        self.source = source
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        return CGSize(width: targetSize.width, height: sectionStackView.systemLayoutSizeFitting(targetSize).height + headerHeight + safeAreaInsets.bottom + 16)
    }

    public func setupView() {
        addShareHeaderPanel()
        addSubview(scrollView)
        scrollView.addSubview(sectionStackView)
        scrollView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            if panelHeaderView.isHidden == false {
                make.top.equalTo(panelHeaderView.snp.bottom)
                make.bottom.equalTo(safeAreaLayoutGuide).offset(-16)
            } else {
                make.top.equalTo(self.hidenCloseButton() ? 32 : 8)
                make.bottom.equalTo(safeAreaLayoutGuide).offset(self.hidenCloseButton() ? -20 : 0)
            }
        }
        sectionStackView.snp.remakeConstraints { make in
            make.top.left.top.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }
        if let model = shareEntity.formsShareModel {
            setupUIFormNewVormV2(model: model)
            return
        }
        if shareEntity.isFormV1 || shareEntity.isBitableSubShare {
            setupUIForBitableSubShare()
        } else {
            setupUI()
        }
        setupAccessoryView()
        setupSharePanel()
        setupCloseBtn()
        setupBitableMask()
    }
    
    public func setScrollContentSize() {
        scrollView.contentSize = CGSize(width: scrollView.frame.width, height: sectionStackView.bounds.size.height)
    }

    private func addShareHeaderPanel() {
        addSubview(panelHeaderView)
        panelHeaderView.isHidden = viewModel.isDocVersion
        panelHeaderView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(headerHeight)
        }
    }
    
    private func setupCloseBtn() {
        addSubview(closeButton)
        addSubview(sepratelineView)
        closeButton.isHidden = self.hidenCloseButton()
        sepratelineView.isHidden = closeButton.isHidden
        closeButton.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(scrollView.frame.maxY).offset(130)
            make.height.equalTo(30)
        }
        sepratelineView.snp.makeConstraints { (make) in
            make.bottom.equalTo(closeButton).offset(-40)
            make.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    
    private func hidenCloseButton() -> Bool {
        let presentStyle = self.delegate?.currentPresentationStyle() ?? .fullScreen
        return (!viewModel.isDocVersion || SKDisplay.pad && presentStyle == .popover)
    }
    
    private func setupBitableMask() {
        guard shareEntity.isFormV1 || shareEntity.isBitableSubShare, !isNewForm else {
            return
        }
        let maskEqualSharePanel = (shareEntity.bitableShareEntity?.isRecordShareV2 == true || shareEntity.bitableShareEntity?.isAddRecordShare == true)
        addSubview(bitableMaskView)
        bitableMaskView.snp.remakeConstraints { (make) in
            if maskEqualSharePanel {
                make.edges.equalTo(sharePanel)
            } else {
                make.top.equalTo(bitableSwitchPanel.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
        }
        showBitableMaskView(isHidden: false)
    }
    
    func setupUIFormNewVormV2(model: FormsShareModel) {
        
        setupCloseBtn()
        
        sectionStackView.addArrangedSubview(tipView)
        tipView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }
        
        let panelComponents = model.panelComponents
        
        if panelComponents.contains("externalShare") {
            sectionStackView.addArrangedSubview(shareToLabel)
            shareToLabel.snp.makeConstraints { make in
                make.right.equalToSuperview()
                make.left.equalToSuperview().offset(16)
            }
            
            sectionStackView.addArrangedSubview(sharePanel)
            sharePanel.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
            }
        }
        
        if panelComponents.contains("memberSetting") {
            sectionStackView.addArrangedSubview(invitePeopleLabel)
            invitePeopleLabel.snp.makeConstraints { make in
                make.right.equalToSuperview()
                make.left.equalToSuperview().offset(16)
            }
            
            let collaboratorSectionView = setupCollaboratorsSection()
            collaboratorSection = collaboratorSectionView
            sectionStackView.addArrangedSubview(collaboratorSectionView)
            collaboratorSectionView.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(16)
            }
        }
        
        if panelComponents.contains("notice") {
            sectionStackView.addArrangedSubview(formsNotifyMeView)
            formsNotifyMeView.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(16)
            }
        }
        
    }

    private func setupUIForBitableSubShare() {
        if shareEntity.bitableShareEntity?.isRecordShareV2 == true {
            // 独立记录分享面板只有 sharePanel，不需要开关和添加协作者部分
            return
        }
        if shareEntity.bitableShareEntity?.isAddRecordShare == true {
            // 快捷新建记录分享面板只有 sharePanel，不需要开关和添加协作者部分
            return
        }
        // bitable 表单场景:
        // [spacingView]-sectionStackView-[tipView]-16-[bitableShareSection]-16-[collaboratorsSection]-16-[shareAssistPanel]
        
        sectionStackView.addArrangedSubview(tipView)
        tipView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }
        if formEditable != false {
            let shareSectionView = setupBitableShareSection()
            sectionStackView.addArrangedSubview(shareSectionView)
            shareSectionView.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(16)
                // tipView 隐藏时，保留 16pt 的顶部 inset
                make.top.greaterThanOrEqualToSuperview().offset(16)
            }
        }

        let collaboratorSectionView = setupCollaboratorsSection()
        collaboratorSection = collaboratorSectionView
        sectionStackView.addArrangedSubview(collaboratorSectionView)
        collaboratorSectionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
        }
    }

    private func setupUI() {
        // 非 bitable 表单场景:
        // [unlockView]-0-[spacingView]-16-[collaboratorsSection]-16-[linkShareSection]-16-[shareAssistPanel]
        sectionStackView.addArrangedSubview(permissionUnlockView)
        permissionUnlockView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }
        permissionUnlockView.isHidden = true

        let collaboratorSectionView = setupCollaboratorsSection()
        sectionStackView.addArrangedSubview(collaboratorSectionView)
        collaboratorSectionView.snp.makeConstraints { make in
            // permissionUnlockView 隐藏时，保留 16pt 的顶部 inset
            make.top.greaterThanOrEqualToSuperview().offset(16)
            make.left.right.equalToSuperview().inset(16)
        }

        shareLinkSectionView = setupLinkShareSection()
        updateBitableAdPermPanel()
        sectionStackView.addArrangedSubview(shareLinkSectionView)
        shareLinkSectionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
        }
    }

    // 表单的链接分享 section
    private func setupBitableShareSection() -> UIStackView {
        let views: [UIView]
        if isNewForm {
            views = [shareLinkEntrance]
        } else {
            views = [bitableSwitchPanel, shareLinkEntrance]
        }
        let shareSectionView = UIStackView(arrangedSubviews: views)
        shareSectionView.spacing = 0
        shareSectionView.axis = .vertical
        shareSectionView.alignment = .fill
        shareSectionView.distribution = .fill
        shareSectionView.layer.cornerRadius = 10
        shareSectionView.clipsToBounds = true
        if UserScopeNoChangeFG.ZYS.baseRecordShareV2 {
            bitableSwitchPanel.accessSwitch.clickCallback = { [weak self] (switchView: UISwitch) in
                self?.bitablePanelAccessSwitchChanged(sw: switchView)
            }
        } else {
            bitableSwitchPanel.accessSwitch.addTarget(self, action: #selector(bitablePanelAccessSwitchChanged(sw:)), for: .valueChanged)
        }
        let showShowBottomSplit = !shareEntity.isFormV1 && !shareEntity.isBitableSubShare
        shareLinkEntrance.showSplitBottom(show: showShowBottomSplit)
        return shareSectionView
    }

    // 邀请协作者、管理协作者 section
    private func setupCollaboratorsSection() -> UIStackView {
        let shareSectionView = UIStackView(arrangedSubviews: [inviteCollaboratorsPanel, collaboratorPanel])
        if UserScopeNoChangeFG.WJS.baseLarkFormRemindInviterEnable, isNewFormV2 {
            shareSectionView.addArrangedSubview(remindNotificationView)
        }
        shareSectionView.spacing = 0
        shareSectionView.axis = .vertical
        shareSectionView.alignment = .fill
        shareSectionView.distribution = .fill
        shareSectionView.layer.cornerRadius = 10
        shareSectionView.clipsToBounds = true

        let showCollaboratorsEntrance = viewModel.showCollaboratorsEntrance()
        shareSectionView.isHidden = !showCollaboratorsEntrance
        return shareSectionView
    }

    private func setupLinkShareSection() -> UIStackView {
        let linkShareSectionView = UIStackView(arrangedSubviews: [shareLinkEntrance, permissionSettingsPanel])
        linkShareSectionView.spacing = 0
        linkShareSectionView.axis = .vertical
        linkShareSectionView.alignment = .fill
        linkShareSectionView.distribution = .fill
        linkShareSectionView.layer.cornerRadius = 10
        linkShareSectionView.clipsToBounds = true

        let showEditLinkSettingEntrance = viewModel.showEditLinkSettingEntrance()
        //shareLinkEntrance.isHidden = !showEditLinkSettingEntrance

        let showPermissionSettingEntrance = viewModel.showPermissionSettingEntrance()
        permissionSettingsPanel.isHidden = true
        shareLinkEntrance.showSplitBottom(show: showPermissionSettingEntrance)
        let sectionIsHidden = !showEditLinkSettingEntrance && !showPermissionSettingEntrance
        linkShareSectionView.isHidden = sectionIsHidden
        return linkShareSectionView
    }

    private func setupAccessoryView() {
        guard let accessoryView = accessory else { return }
        hasAccessoryView = true
        let containerView = UIView()
        containerView.backgroundColor = UDColor.bgFloat
        containerView.layer.cornerRadius = 10
        containerView.clipsToBounds = true
        containerView.addSubview(accessoryView)
        accessoryView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.equalTo(accessoryView.frame.size.height)
        }
        accessoryView.backgroundColor = .clear
        sectionStackView.addArrangedSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
        }
    }

    private func setupSharePanel() {
        sectionStackView.addArrangedSubview(sharePanel)
        sharePanel.snp.makeConstraints { make in
            if shareEntity.onlyShowSocialShareComponent {
                make.top.greaterThanOrEqualToSuperview().offset(16)
            }
            make.left.right.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updatePermissionUnlockView(publicPermissions: PublicPermissionMeta?, userPermisson: UserPermissionAbility?) {
        guard let userPermisson = userPermisson, userPermisson.canManageCollaborator() else {
            return
        }
        guard let publicPermissions = publicPermissions else {
            return
        }
        permissionUnlockView.recoverButtonHidden = !publicPermissions.canUnlock
        // DocX 版本、同步块场景不显示加锁 banner
        permissionUnlockView.isHidden = (!publicPermissions.lockState || viewModel.isDocVersion || shareEntity.isSyncedBlock)
        if publicPermissions.lockState {
            if shareEntity.isFolder {
                permissionUnlockView.title = BundleI18n.SKResource.CreationMobile_ECM_PermissionRestrictionDesc
            } else {
                permissionUnlockView.title = BundleI18n.SKResource.CreationMobile_Wiki_Permission_NoLongerInherit_Placeholder
            }
        }
    }

    func didChangeStatusBarOrientation(to newOrentation: UIInterfaceOrientation) {
        scrollView.isScrollEnabled = newOrentation.isLandscape ? true : false
        self.updateUI()
    }
    
    
    
    func updateUI() {
        guard Display.phone else { return }
        if sectionStackView.arrangedSubviews.contains(sharePanel) {
            if UIApplication.shared.statusBarOrientation.isLandscape {
                sectionStackView.removeArrangedSubview(sharePanel)
                sectionStackView.insertArrangedSubview(sharePanel, at: 0)
            } else {
                sectionStackView.removeArrangedSubview(sharePanel)
                sectionStackView.addArrangedSubview(sharePanel)
            }
            sharePanel.snp.makeConstraints { make in
                make.top.greaterThanOrEqualToSuperview().offset(16)
                make.left.right.equalToSuperview()
            }
            sectionStackView.layoutIfNeeded()
        }
    }
    
    @objc
    func bitablePanelAccessSwitchChanged(sw: UISwitch) {
        if UserScopeNoChangeFG.ZYS.baseRecordShareV2 {
            // 新模式，默认不切换，等callback回来后再切换
            let target = !bitableSwitchPanel.accessSwitch.isOn
            UDToast.showLoading(with: BundleI18n.SKResource.Bitable_Common_Loading_Mobile, on: self)
            delegate?.didClickBitablePanelAccessSwitch(flag: target, callback: { [weak self] in
                // 这里已经是主线程了，直接移除 toast，callback 后面可能还会 showToast
                guard let self = self else {
                    return
                }
                UDToast.removeToast(on: self)
            })
        } else {
            // 旧模式，默认切换，即将删除的代码
            delegate?.didClickBitablePanelAccessSwitch(flag: sw.isOn, callback: {
            })
        }
        
    }

    @objc
    private func didClickHeaderPanelCloseButton() {
        delegate?.didClickClose()
    }
    @objc
    private func onBaseAdPermClick(_ sender: UIControl) {
        delegate?.didClickBitableAdPermPanel()
    }
}

extension CollaborationAssistView: CollaboratorManagerPanelDelegate {

    func requestOpenCollaboratorList() {
        delegate?.openCollaboratorEditViewController(view: self, collaborators: collaboratorPanel.collaborators,
                                                     containerCollaborators: collaboratorPanel.containerPageCollaborators,
                                                     singlePageCollaborators: collaboratorPanel.singlePageCollaborators )
    }

    func collaboratorInvitedEnableUpdated(enable: Bool) {
        let formEnable = shareEntity.isFormV1 ? shareEntity.formCanShare : true
        let bitableEnable = shareEntity.isBitableSubShare ? (shareEntity.bitableShareEntity?.isShareReady ?? false) : true
        let enable = collaboratorPanel.canInviteCollaborator && fetchUserPermCompleted && viewModel.requestUserPermissionsState == .success
        inviteCollaboratorsPanel.panelEnabled = enable && formEnable && bitableEnable
    }
    
    func requestDisplayUserProfile(userId: String, fileName: String?) {
        delegate?.requestDisplayUserProfile(userId: userId, fileName: fileName)
    }
    func notifyFetchUserPermCompleted() {
        fetchUserPermCompleted = true
        let formEnable = shareEntity.isFormV1 ? shareEntity.formCanShare : true
        let bitableEnable = shareEntity.isBitableSubShare ? (shareEntity.bitableShareEntity?.isShareReady ?? false) : true
        let enable = collaboratorPanel.canInviteCollaborator && fetchUserPermCompleted && viewModel.requestUserPermissionsState == .success
        inviteCollaboratorsPanel.panelEnabled = enable && formEnable && bitableEnable
    }
}

extension CollaborationAssistView {

    func updateManagerEntryPanelCollaborators(completion: ((ShareViewControllerState) -> Void)? = nil) {
        guard viewModel.shareEntity.bitableShareEntity?.isRecordShareV2 != true, viewModel.shareEntity.bitableShareEntity?.isAddRecordShare != true else {
            // 记录分享二期不需要再获取协作者，正常情况下不应该再走到这里，否则直接返回成功
            completion?(.fetchData)
            completion?(.setData)
            return
        }
        collaboratorPanel.reloadData(completion: completion)
    }
}

extension CollaborationAssistView: ShareAssistPanelDelegate {

    func didClickShareToByteDanceMoments(_ url: URL) {
        delegate?.didClickShareToByteDanceMoments(url)
    }
    
    func requestHostViewController() -> UIViewController? {
        return delegate?.requestHostViewController()
    }

    func requestweakFollowAPIDelegate() -> BrowserVCFollowDelegate? {
        return delegate?.requestFollowAPIDelegate()
    }

    func requestShareToLarkServiceFromViewController() -> UIViewController? {
        return delegate?.requestShareToLarkServiceFromViewController()
    }

    
    func didClicked(type: ShareAssistType, sharePanel: ShareAssistPanel) {
        delegate?.didClicked(type: type)
    }

    func didRequestExportSnapShot(sharePanel: ShareAssistPanel) {
        delegate?.requestExportSnapShot(view: self)
    }

    func didRequestSlideExport(sharePanel: ShareAssistPanel) {
        delegate?.requestSlideExport(view: self)
    }

    func shouldDisplaySnapShotItem() -> Bool {
        return delegate?.shouldDisplaySnapShotItem() ?? false
    }

    func shouldDisplaySlideExport() -> Bool {
        return delegate?.shouldDisplaySlideExport() ?? false
    }

    func didClickShareToOtherApp(sharePanel: ShareAssistPanel, activityViewController: UIViewController?) {
        delegate?.requestShareToOtherApp(view: self, activityViewController: activityViewController)
    }

    func shouldDisplayCopyLinkAlertSheet(view: UIView, iphoneAlert: UIViewController, ipaAlert: UIViewController) {
        delegate?.shouldDisplayCopyLinkAlertSheet(view: view, iphoneAlert: iphoneAlert, ipaAlert: ipaAlert)
    }
    
    func didClickShareLinkToExternal(view: UIView, completion: (() -> Void)?) {
        delegate?.didClickShareLinkToExternal(view: view, completion: completion)
    }

    func sharePanelConfigInfo() -> SharePanelConfigInfoProtocol? {
        return delegate?.sharePanelConfigInfo(view: self)
    }
    
    func didClickCopyLink(sharePanel: ShareAssistPanel) {
        delegate?.didClickCopyLink()
    }

    func didClickCopyPasswordLink(enablePasswordShare: Bool) {
        delegate?.didClickCopyPasswordLink(enablePasswordShare: enablePasswordShare)
    }
}

extension CollaborationAssistView: ShareLinkEntrancePanelDelegate {
    func didClickedShareEntrancePanel(panel: ShareLinkEntrancePanel,
                                      chosenType: ShareLinkChoice?) {
        if viewModel.requestUserPermissionsState == .requesting {
            DocsLogger.info("user permisson is requesting, return")
            return
        }

        guard viewModel.userPermissions != nil else {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Wiki_SeverError, on: self.window ?? self)
            return
        }
        
        delegate?.openShareLinkEditViewController(view: self, chosenType: chosenType)
    }
}

extension CollaborationAssistView: SharePermissionDelegate {
    func didOpenPermission(panel: SharePermissionPanel) {
        if viewModel.requestUserPermissionsState == .requesting {
            DocsLogger.info("user permisson is requesting, return")
            return
        }

        guard viewModel.userPermissions != nil else {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Wiki_SeverError, on: self.window ?? self)
            return
        }
        
        delegate?.openPublicPermissionViewController(view: self)
    }
}

extension CollaborationAssistView: InviteCollaboratorsPanelDelegate {

    func didTapSearchTextFiled(panel: InviteCollaboratorsPanel) {
        //1.0的文件夹，外部协作者不可邀请协作者，也不可以查看协作者，相当于没有分享权限，需要端上做前置处理。
        if shareEntity.isFolder, !shareEntity.spaceSingleContainer,
           !shareEntity.tenantID.isEmpty,
            let tenantID = User.current.info?.tenantID, shareEntity.tenantID != tenantID {
            UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_Permissions_NoExternalSharing_Toast, on: self.window ?? self)
            return
        }
        //1.0文件夹，共享文件夹- 子目录 不可以分享
        if shareEntity.isFolder, !shareEntity.spaceSingleContainer,
            shareEntity.isOldShareFolder, !shareEntity.isShareFolderRoot {
            return
        }

        if viewModel.requestUserPermissionsState == .requesting {
            DocsLogger.info("user permisson is requesting, return")
            return
        }
        // 无权限信息是要报错，但1.0的个人文件夹是个例外，这个文件夹本来就没这个信息的
        if viewModel.userPermissions == nil && !shareEntity.isCommonFolder {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Wiki_SeverError, on: self.window ?? self)
            return
        }

        if shareEntity.spaceSingleContainer && shareEntity.isFolder {
            guard viewModel.userPermissions?.canInviteCanView() == true else {
                UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_Permissions_NoExternalSharing_Toast, on: self.window ?? self)
                return
            }
        }
        guard collaboratorPanel.canSearchCollaborator else {
            UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_Permissions_NoExternalSharing_Toast, on: self.window ?? self)
            return
        }
        let needActivateKeyboard = SKDisplay.pad || UIApplication.shared.statusBarOrientation.isPortrait
        delegate?.openCollaboratorSearchViewController(view: self,
                                                              collaborators: collaboratorPanel.collaborators,
                                                              lastPageLabel: collaboratorPanel.lastPageLabel,
                                                              needActivateKeyboard: needActivateKeyboard,
                                                              source: .sharePanel)
    }
}
extension CollaborationAssistView {

    func updateFormPanel(_ formMeta: FormShareMeta) {
        bitableSwitchPanel.updateBy(formMeta)
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            if formMeta.flag, shareEntity.formsCallbackBlocks.formHasLinkField() {
                DocsLogger.info("open share and has link field, show notice")
                var noticeCfg = UDNoticeUIConfig(backgroundColor: UDColor.functionInfoFillSolid02, attributedText: NSAttributedString(string: BundleI18n.SKResource.Bitable_Form_RespondentCanViewReferencedData_Notice))
                noticeCfg.leadingButtonText = BundleI18n.SKResource.CreationDoc_Stats_Visits_desc_more
                tipView.updateConfigAndRefreshUI(noticeCfg)
                tipView.isHidden = false
            } else {
                DocsLogger.info("not open share or not has link field, don't show notice")
                tipView.isHidden = true
            }
            layoutIfNeeded()
        }
    }
    
    func updateBitablePanel(_ meta: BitableShareMeta) {
        guard shareEntity.isBitableSubShare else {
            return
        }
        guard shareEntity.bitableShareEntity?.isRecordShareV2 != true, shareEntity.bitableShareEntity?.isAddRecordShare != true else {
            let shareReady = shareEntity.bitableShareEntity?.meta?.isShareReady == true
            bitableMaskView.isHidden = shareReady
            sharePanel.panelEnabled = shareReady
            return
        }
        bitableSwitchPanel.update(subType: meta.shareType, switchEnable: meta.isShareOn)
        if meta.isPublicPermissionToBeSet {
            tipView.updateConfigAndRefreshUI(.init(type: .info, attributedText: .init(string: BundleI18n.SKResource.Bitable_Share_ShareDashboardOnboarding_ForOldUser_Description)))
            tipView.isHidden = false
            if bitableMaskView.superview != nil {
                bitableMaskView.snp.remakeConstraints { (make) in
                    make.left.right.bottom.equalToSuperview()
                    make.top.equalTo(shareLinkEntrance.snp.bottom)
                }
                bitableMaskView.isHidden = false
            }
            shareLinkEntrance.isEnabled = true
            inviteCollaboratorsPanel.panelEnabled = false
            collaboratorPanel.panelEnabled = false
            sharePanel.panelEnabled = false
        } else {
            tipView.isHidden = true
            if bitableMaskView.superview != nil {
                bitableMaskView.snp.remakeConstraints { (make) in
                    make.left.right.bottom.equalToSuperview()
                    make.top.equalTo(bitableSwitchPanel.snp.bottom)
                }
                bitableMaskView.isHidden = meta.isShareReady
            }
            shareLinkEntrance.isEnabled = meta.isShareReady
            inviteCollaboratorsPanel.panelEnabled = meta.isShareReady
            collaboratorPanel.panelEnabled = meta.isShareReady
            sharePanel.panelEnabled = meta.isShareReady
        }
        layoutIfNeeded()
    }
    
    func updateBitableAdPermBridgeData(_ data: BitableBridgeData) {
        guard UserScopeNoChangeFG.ZYS.baseAdPermRoleInheritance else {
            return
        }
        shareEntity.bitableAdPermInfo = data
        updateBitableAdPermPanel()
    }

    func showBitableMaskView(isHidden: Bool) {
        bitableMaskView.isHidden = isHidden
        guard shareEntity.isFormV1 || shareEntity.isBitableSubShare else { return }
        shareLinkEntrance.isEnabled = isHidden
        inviteCollaboratorsPanel.panelEnabled = isHidden
        collaboratorPanel.panelEnabled = isHidden
        sharePanel.panelEnabled = isHidden
    }
    
    private func updateBitableAdPermPanel() {
        guard UserScopeNoChangeFG.ZYS.baseAdPermRoleInheritance else {
            return
        }
        if let data = shareEntity.bitableAdPermInfo, data.isPro {
            baseAdPermPanel.isEnabled = viewModel.userPermissions?.isFA == true
            shareLinkEntrance.showSplitBottom(show: true)
            permissionSettingsPanel.showBottomSeperatorLine(true)
            shareLinkSectionView.addArrangedSubview(baseAdPermPanel)
        } else {
            shareLinkEntrance.showSplitBottom(show: viewModel.showPermissionSettingEntrance())
            permissionSettingsPanel.showBottomSeperatorLine(false)
            baseAdPermPanel.removeFromSuperview()
        }
    }

    @objc
    private func tapBitableMaskView() {
        if shareEntity.isForm {
            UDToast.docs.showMessage(
                BundleI18n.SKResource.Bitable_Form_PleaseTurnOnFormShare,
                on: self.window ?? self,
                msgType: .tips
            )
        } else if shareEntity.isBitableSubShare {
            if shareEntity.bitableShareEntity?.isRecordShareV2 == true || shareEntity.bitableShareEntity?.isAddRecordShare == true {
                // 记录分享时，shareToken 没有获取成功，不用给提示
                return
            }
            UDToast.docs.showMessage(
                BundleI18n.SKResource.Bitable_Share_SelectWhoCanView_Tooltip,
                on: self.window ?? self,
                msgType: .tips
            )
        }
    }
    
    func updateCloseButton(isHidden: Bool) {
        panelHeaderView.toggleCloseButton(isHidden: isHidden)
    }
}

extension CollaborationAssistView {
    public func updateUserAndPublicPermissions(userPermissions: UserPermissionAbility?,
                                               publicPermissions: PublicPermissionMeta?,
                                               completion: ((ShareViewControllerState) -> Void)? = nil) {
        let showEditLinkSettingEntrance = viewModel.showEditLinkSettingEntrance()
        shareLinkEntrance.isHidden = !showEditLinkSettingEntrance
        let showPermissionSettingEntrance = viewModel.showPermissionSettingEntrance()
        permissionSettingsPanel.isHidden = (!showPermissionSettingEntrance || viewModel.isDocVersion)
        permissionSettingsPanel.isSettingsEnabled = viewModel.isPermissionSettingEnabled()

        if !shareEntity.isFormV1, !shareEntity.isBitableSubShare,
           shareLinkEntrance.superview == permissionSettingsPanel.superview,
           let sectionView = shareLinkEntrance.superview {
            shareLinkEntrance.showSplitBottom(show: showPermissionSettingEntrance)
            let sectionIsHidden = !showEditLinkSettingEntrance && !showPermissionSettingEntrance
            sectionView.isHidden = sectionIsHidden
        }
        
        updateBitableAdPermPanel()
        
        if shareEntity.isBitableSubShare && !shareEntity.isForm {
            // 仪表盘 & 通用分享中，只有分享权限是 「仅受邀者可阅读」时，才展示「邀请阅读者」选项
            let hideCBSection = (publicPermissions?.linkShareEntity != .close)
            collaboratorSection?.isHidden = hideCBSection
        }
        self.shareLinkEntrance.updateUserAndPublicPermissions(userPermissions: userPermissions, publicPermissions: publicPermissions)

        self.updatePermissionUnlockView(publicPermissions: publicPermissions, userPermisson: userPermissions)
        self.collaboratorPanel.updateUserAndPublicPermissions(userPermissions: userPermissions,
                                                              publicPermissions: publicPermissions,
                                                              completion: completion)
        self.sharePanel.updateUserAndPublicPermissions(userPermissions: userPermissions, publicPermissions: publicPermissions)
    }
}
