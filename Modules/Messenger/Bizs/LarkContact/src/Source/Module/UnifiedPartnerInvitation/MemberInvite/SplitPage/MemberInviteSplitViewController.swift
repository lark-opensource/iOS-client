//
//  MemberInviteSplitViewController.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/1/1.
//

import Foundation
import LarkUIKit
import SnapKit
import LarkAlertController
import RxSwift
import UniverseDesignToast
import UniverseDesignFont
import LKCommonsLogging
import LKMetric
import LarkMessengerInterface
import LarkSnsShare
import LarkContainer
import RustPB
import QRCode
import LarkFoundation
import EENavigator
import LarkTraitCollection
import LarkEnv
import ByteWebImage
import LarkBizAvatar
import LarkAccountInterface
import FigmaKit
import UIKit
import UniverseDesignTheme

/// 国内版成员邀请分流页
final class MemberInviteSplitViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate, UserResolverWrapper {
    private typealias Self_ = MemberInviteSplitViewController
    private let viewModel: MemberInviteSplitViewModel
    var userResolver: LarkContainer.UserResolver
    private let passportUserService: PassportUserService
    private let passportService: PassportService
    private(set) var inviteInfo: InviteAggregationInfo?
    @ScopedInjectedLazy private var snsShareService: LarkShareService?
    var rightButtonTitle: String?
    var rightButtonClickHandler: (() -> Void)?
    private var isPresented: Bool = false
    private lazy var currentUserId: String = {
        return self.userResolver.userID
    }()
    private var templateConfig: TemplateConfiguration {
        var imageOptions = Contact_V1_ImageOptions()
        imageOptions.resolutionType = .highDefinition
        var isDarkMode = false
        if #available(iOS 13.0, *) {
            isDarkMode = UDThemeManager.getRealUserInterfaceStyle() == .dark
        }
        return TemplateConfiguration(
            bizScenario: isDarkMode ? .teamQrcardDark : .teamQrcardLight,
            imageOptions: imageOptions
        )
    }
    private lazy var exporter: DynamicRenderingTemplateExporter = {
        return DynamicRenderingTemplateExporter(
            templateConfiguration: templateConfig,
            extraOverlayViews: [:],
            resolver: userResolver
        )
    }()
    private var extraOverlayViews: [OverlayViewType: UIView]? {
        didSet {
            exporter.updateExtraOverlayViews(self.extraOverlayViews ?? [:])
        }
    }
    private lazy var needDisablePopSource: Bool = {
        return viewModel.sourceScenes == .newGuide
            || (viewModel.sourceScenes == .upgrade && passportService.isOversea)
    }()
    private lazy var showSkipNavItem: Bool = {
        return viewModel.sourceScenes == .newGuide
            || viewModel.sourceScenes == .upgrade
    }()
    private var exportDisposable: Disposable?
    private let disposeBag = DisposeBag()
    static let logger = Logger.log(MemberInviteSplitViewController.self,
                                   category: "LarkContact.MemberInviteSplitViewController")

    init(viewModel: MemberInviteSplitViewModel, resolver: UserResolver) throws {
        self.viewModel = viewModel
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        self.passportService = try resolver.resolve(assert: PassportService.self)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutPageSubviews()
        Tracer.trackAddMemberChannelShow(source: viewModel.sourceScenes)
        InviteMemberApprecibleTrack.inviteMemberPageFirstRenderCostTrack()
        InviteMemberApprecibleTrack.inviteMemberPageLoadingTimeEnd()
        // override traitCollection observe
        RootTraitCollection.observer
            .observeRootTraitCollectionDidChange(for: view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] _ in
                self.setSpecialNavBarIfOnOnboardingProcess()
            }).disposed(by: disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setSpecialNavBarIfOnOnboardingProcess()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.bgBase), for: .default)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pushGroupNameSettingPageIfSimpleB()
    }

    private lazy var tableView: UITableView = {
        let tableView = InsetTableView(frame: .zero)
        tableView.backgroundColor = UIColor.ud.bgBase
        tableView.bounces = true
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 52, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 58
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.lu.register(cellSelf: SplitChannelCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    @objc
    func skipStep() {
        Tracer.trackAddMemberSkip(source: viewModel.sourceScenes)
        if let handler = rightButtonClickHandler {
            handler()
        } else {
            if isPresented {
                dismiss(animated: true)
            } else {
                navigationController?.popViewController(animated: true)
            }
        }
    }

    @objc
    private func routeToHelpPage() {
        Tracer.trackAddMemmberHelpClick(source: viewModel.sourceScenes)
        viewModel.router.pushToHelpCenterInternal(baseVc: self)
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sectionCount
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rowCountOfSections[section]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: SplitChannelCell.lu.reuseIdentifier) as? SplitChannelCell {
            cell.bindModel(viewModel.splitChannels[indexPath.section][indexPath.row])
            return cell
        }
        return UITableViewCell()
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let channelContext = viewModel.splitChannels[indexPath.section][indexPath.row]
        switch channelContext.channelFlag {
        case .directed: routeToDirectedInvite()
        case .wechat: routeToWechatInvite()
        case .nonDirectedQRCode: routeToNonDirectedInvite(.qrCode)
        case .nonDirectedLink: routeToNonDirectedInvite(.inviteLink)
        case .larkInvite: routeToLarkInvite()
        case .teamCode: routeToTeamCodeInvite()
        case .addressbookImport: routeToAddressBookImport()
        case .unknown: break
        }
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 34))
        header.backgroundColor = UIColor.ud.bgBase
        let titleLabel = UILabel(frame: CGRect(x: 16.5, y: 12, width: tableView.frame.width - 33, height: 22))
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        titleLabel.textColor = UIColor.ud.textCaption
        if viewModel.sectionTitles.count > section {
            titleLabel.text = viewModel.sectionTitles[section]
        } else {
            titleLabel.text = ""
            MemberInviteSplitViewController.logger.warn(
                logId: "MemberInviteSplitViewController.dataAbnormal",
                "viewModel.sectionTitles data abnormal",
                params: ["sectionTitles": "\(viewModel.sectionTitles)",
                    "sectionCount": "\(viewModel.sectionCount)"]
            )
        }
        header.addSubview(titleLabel)
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 34.0
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if let inviteInfo = inviteInfo {
            updateTemplateConfig(with: inviteInfo)
        }
    }
}

private extension MemberInviteSplitViewController {

    func setSpecialNavBarIfOnOnboardingProcess() {
        if needDisablePopSource {
            // clear left back button
            navigationItem.setHidesBackButton(true, animated: false)
            navigationItem.leftBarButtonItem = nil
        }
        if showSkipNavItem {
            // add right skip button
            let skipItem = LKBarButtonItem(image: nil, title: rightButtonTitle ?? BundleI18n.LarkContact.Lark_Guide_VideoSkip)
            skipItem.button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
            skipItem.button.titleLabel?.font = UDFont.headline
            skipItem.button.addTarget(self, action: #selector(skipStep), for: .touchUpInside)
            navigationItem.rightBarButtonItem = skipItem
        }
    }

    func pushGroupNameSettingPageIfSimpleB() {
        if viewModel.currentTenantIsSimpleB {
            MemberInviteSplitViewController.logger.info("current tenant is simple B")
            Tracer.trackGuideUpdateDialogShow()
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkContact.Lark_Guide_UpgradeTeamDialogTitle)
            alertController.setContent(text: BundleI18n.LarkContact.Lark_Guide_UpgradeTeamDialogContent())
            alertController.addCancelButton(dismissCompletion: { [weak self] in
                guard let `self` = self else { return }
                Tracer.trackGuideUpdateDialogSkip()
                if self.isPresented {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            })
            alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Guide_UpgradeTeamYes, dismissCompletion: {
                Tracer.trackGuideUpdateDialogClick()
                self.viewModel.router.pushToGroupNameSettingController(baseVc: self) { [weak self] (isSuccess) in
                    guard let `self` = self else { return }
                    if isSuccess {
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        if self.isPresented {
                            self.dismiss(animated: true, completion: nil)
                        } else {
                            self.popSelf(dismissPresented: false)
                        }
                    }
                }
            })
            present(alertController, animated: true)
        } else {
            MemberInviteSplitViewController.logger.info("current tenant is not simple B")
        }
    }

    func layoutPageSubviews() {
        self.title = BundleI18n.LarkContact.Lark_Invitation_InviteTeamMembers_TitleBar
        isPresented = !hasBackPage && presentingViewController != nil
        let rBarItem = LKBarButtonItem(image: Resources.invite_help)
        rBarItem.button.addTarget(self, action: #selector(routeToHelpPage), for: .touchUpInside)
        navigationItem.rightBarButtonItem = rBarItem

        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func wakeWechatToInvite() {
        func shareExportedImage(_ inviteContext: InviteAggregationInfo) {
            downloadRendedImageIfNeeded { [weak self] (cardImage) in
                guard let `self` = self else { return }
                let imagePrepare = ImagePrepare(
                    title: BundleI18n.LarkContact.Lark_Invitation_AddMembersLinkTitle(
                        inviteContext.name,
                        inviteContext.tenantName
                    ),
                    image: cardImage
                )
                let shareContentContext = ShareContentContext.image(imagePrepare)
                let downgradePanelMeterial = DowngradeTipPanelMaterial.image(
                    panelTitle: BundleI18n.LarkContact.Lark_Invitation_ShareViaWeChat_TeamQRCodeImageSaved_Title
                )
                self.snsShareService?.present(
                    by: "lark.invite.member.qrcode.wx",
                    contentContext: shareContentContext,
                    baseViewController: self,
                    downgradeTipPanelMaterial: downgradePanelMeterial,
                    customShareContextMapping: [:],
                    defaultItemTypes: [],
                    popoverMaterial: nil) { [weak self] (result, type) in
                    guard let `self` = self else { return }
                    if case .wechat = type {
                        Tracer.trackJoinTeamWechatClick()
                    }
                    if result.isFailure() {
                        self.handleShareError(result: result, itemType: type)
                    }
                    let logMsg = "member share QRCode export image \(result.isSuccess() ? "success" : "failed") by \(type)"
                    Self_.logger.info(logMsg)
                }
            }
        }

        let hud = UDToast.showLoading(on: view, disableUserInteraction: false)
        viewModel.fetchInviteLink()
            .subscribe(onNext: { [weak self] (info) in
                hud.remove()

                guard let self = self else { return }
                guard let url = info.memberExtraInfo?.urlForLink, !url.isEmpty else {
                    if let window = self.view.window {
                        UDToast.showFailure(with: BundleI18n.LarkContact.Lark_UserGrowth_InviteMemberPermissionDeny, on: window)
                    }
                    return
                }
                self.inviteInfo = info
                self.genConstantOverlayViews(by: info)
                self.updateTemplateConfig(with: info)
                shareExportedImage(info)
            }, onError: { [weak self] (error) in
                guard let err: MemberInviteAPI.WrapError = error as? MemberInviteAPI.WrapError else { return }
                switch err {
                case .buzError(let displayMsg):
                    if let window = self?.view.window {
                        UDToast.showTipsOnScreenCenter(with: displayMsg, on: window)
                    }
                default: break
                }
                hud.remove()
            }, onDisposed: {
                hud.remove()
            }).disposed(by: disposeBag)
    }
}

private extension MemberInviteSplitViewController {
    func routeToDirectedInvite() {
        if viewModel.hasEmailInvitation && viewModel.hasPhoneInvitation {
            Tracer.trackAddMemberAddByPhoneOrEmailClick(source: viewModel.sourceScenes)
        } else if viewModel.hasEmailInvitation {
            Tracer.trackAddMemberAddByEmailClick(source: viewModel.sourceScenes)
        } else if viewModel.hasPhoneInvitation {
            Tracer.trackAddMemberAddByPhoneClick(source: viewModel.sourceScenes)
        }

        viewModel.router.pushToDirectedInviteController(
            baseVc: self,
            sourceScenes: viewModel.sourceScenes,
            departments: viewModel.departments) { [weak self] in
                self?.popSelf(animated: true, dismissPresented: false, completion: {
                    if let handler = self?.rightButtonClickHandler {
                        self?.navigationController?.popViewController(animated: true)
                        handler()
                    } else {
                        self?.popSelf(dismissPresented: false)
                    }
                })
        }
    }

    func routeToWechatInvite() {
        Tracer.trackAddMemberWechatInviteClick(source: viewModel.sourceScenes, result: "unknown")
        wakeWechatToInvite()
    }

    func routeToNonDirectedInvite(_ displayPriority: MemberNoDirectionalDisplayPriority) {
        switch displayPriority {
        case .qrCode:
            Tracer.trackAddMemberQrcodeInviteClick(source: viewModel.sourceScenes)
        case .inviteLink:
            Tracer.trackAddMemberLinkInviteClick(source: viewModel.sourceScenes)
        }
        viewModel.router.pushToNonDirectedInviteController(baseVc: self,
                                                           priority: displayPriority,
                                                           sourceScenes: viewModel.sourceScenes,
                                                           departments: viewModel.departments)
    }

    func routeToLarkInvite() {
        viewModel.forwordInviteLinkInLark(from: self) { [weak self] in
            if let handler = self?.rightButtonClickHandler {
                self?.navigationController?.popViewController(animated: true)
                handler()
            } else {
                self?.popSelf(dismissPresented: false)
            }
        }
    }

    func routeToTeamCodeInvite() {
        Tracer.trackAddMemberViewTeamCodeClick(source: viewModel.sourceScenes)
        viewModel.router.pushToTeamCodeInviteController(baseVc: self,
                                                        sourceScenes: viewModel.sourceScenes,
                                                        departments: viewModel.departments)
    }

    func routeToAddressBookImport() {
        Tracer.trackAddMemberContactBatchInviteClick(scenes: .addMemberChannel)
        viewModel.router.pushToAddressBookImportController(baseVc: self,
                                                           sourceScenes: viewModel.sourceScenes,
                                                           presenter: viewModel.batchInvitePresenter)
    }

    func downloadRendedImageIfNeeded(completion: @escaping (UIImage) -> Void) {
        guard extraOverlayViews != nil else { return }
        exportDisposable?.dispose()

        let hud = UDToast.showLoading(on: view)
        exportDisposable = exporter.export()
            .observeOn(MainScheduler.instance)
            .timeout(.seconds(10), scheduler: MainScheduler.instance)
            .subscribe(onNext: { (outputLayer) in
                hud.remove()
                Self_.logger.info("export qrcode image success")
                completion(outputLayer)
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                hud.remove()
                if let error = error as? DynamicResourceExportError {
                    switch error {
                    case .pullDynamicResourceFailed(let logMsg, let userMsg):
                        Self_.logger.warn(logMsg)
                        UDToast.showFailure(with: userMsg, on: self.view)
                    case .downloadFailed(let logMsg):
                        Self_.logger.warn(logMsg)
                    case .constraintsError(let logMsg):
                        Self_.logger.warn(logMsg)
                    case .bytesParseFailed(let logMsg):
                        Self_.logger.warn(logMsg)
                    case .graphContextError(let logMsg):
                        Self_.logger.warn(logMsg)
                    case .unknownError(let logMsg):
                        Self_.logger.warn(logMsg)
                    }
                }
            })
    }

    func genConstantOverlayViews(by info: InviteAggregationInfo) {
        guard let memberExtraInfo = info.memberExtraInfo else { return }

        let userAvatarContentSize = CGSize(width: 100, height: 100)
        let qrcodeContentSize = CGSize(width: 200, height: 200)
        let teamAvatarContentSize = CGSize(width: 100, height: 100)

        // 个人头像
        let avatarView = UIImageView()
        avatarView.frame = CGRect(x: 0, y: 0, width: userAvatarContentSize.width, height: userAvatarContentSize.height)
        /// 这里先读取小头像作为占位图，防止保存时出现空白区域
        avatarView.bt.setLarkImage(with: .avatar(key: info.avatarKey, entityID: currentUserId),
          trackStart: {
              TrackInfo(scene: .Profile, fromType: .avatar)
          },
          completion: { [weak avatarView, weak self] _ in
            guard let `self` = self else { return }
            avatarView?.bt.setLarkImage(with: .avatar(key: info.avatarKey, entityID: self.currentUserId, params: .defaultBig),
               trackStart: {
                   TrackInfo(scene: .Profile, fromType: .avatar)
               })
          })

        // 团队头像
        let teamLogoView = UIImageView()
        teamLogoView.frame = CGRect(x: 0, y: 0, width: teamAvatarContentSize.width, height: teamAvatarContentSize.height)
        teamLogoView.contentMode = .scaleAspectFill
        teamLogoView.bt.setLarkImage(with: .default(key: memberExtraInfo.teamLogoURL))

        // 二维码视图
        let qrcodeView = UIImageView()
        qrcodeView.frame = CGRect(x: 0, y: 0, width: qrcodeContentSize.width, height: qrcodeContentSize.height)
        qrcodeView.contentMode = .scaleAspectFill
        qrcodeView.image = QRCodeTool.createQRImg(str: memberExtraInfo.urlForQRCode, size: qrcodeContentSize.width)

        extraOverlayViews = [OverlayViewType.userAvatar: avatarView,
                             OverlayViewType.teamCodeQr: qrcodeView,
                             OverlayViewType.tenantAvatar: teamLogoView]
    }

    func updateTemplateConfig(with info: InviteAggregationInfo) {
        guard let teamcode = info.memberExtraInfo?.teamCode else {
            return
        }

        let expireDate = BundleI18n.LarkContact.Lark_AdminUpdate_Subtitle_MobileQRCodeExpire(info.memberExtraInfo?.expireDateDesc ?? "")
        let replacer = [
            "{{USER_NAME}}": info.name,
            "{{TENANT_NAME}}": info.tenantName,
            "{{TEAM_CODE}}": teamcode,
            "{{EXPIRE_DATE}}": expireDate
        ]
        var new = templateConfig
        new.textContentReplacer = replacer
        exporter.updateTemplateConfiguration(new)
    }

    func handleShareError(result: ShareResult, itemType: LarkShareItemType) {
        if case .failure(let errorCode, let debugMsg) = result {
            switch errorCode {
            case .notInstalled:
                if let window = self.view.window {
                    UDToast.showTipsOnScreenCenter(with: debugMsg, on: window)
                }
            default:
                Self_.logger.info("handleShareError.default",
                                  additionalData: ["errorCode": String(describing: debugMsg),
                                                   "errorMsg": String(describing: debugMsg)])
            }
        }
    }
}
