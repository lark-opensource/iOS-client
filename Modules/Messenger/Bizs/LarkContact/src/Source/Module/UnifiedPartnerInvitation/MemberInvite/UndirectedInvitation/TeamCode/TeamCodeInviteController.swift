//
//  TeamCodeInviteController.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/4/26.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import LKCommonsLogging
import LarkAlertController
import EENavigator
import LKMetric
import LarkMessengerInterface
import LarkSnsShare
import LarkContainer
import Homeric
import LarkFeatureGating
import LarkEMM
import LarkSDKInterface
import UniverseDesignEmpty
import UniverseDesignTheme

protocol TeamCodeInviteControllerRouter: ShareRouter {
    /// 成员邀请团队码帮助中心
    func pushMemberInvitationTeamCodeHelpViewController(vc: BaseUIViewController)
}

final class TeamCodeInviteController: BaseUIViewController, UserResolverWrapper {

    private let viewModel: TeamCodeInviteViewModel
    var userResolver: LarkContainer.UserResolver
    @ScopedInjectedLazy private var snsShareService: LarkShareService?
    @ScopedInjectedLazy private var userAPI: UserAPI?
    private var inviteInfo: InviteAggregationInfo? {
        didSet {
            if let inviteInfo = self.inviteInfo {
                container.tenantLabel.text = inviteInfo.tenantName
                teamCodeWrapView.bindWithModel(cardInfo: inviteInfo)

                if let expireDateDesc = inviteInfo.memberExtraInfo?.expireDateDesc {
                    container.expireLabel.text = BundleI18n.LarkContact.Lark_AdminUpdate_Subtitle_MobileInviteCodeExpire(expireDateDesc)
                }
            }
        }
    }
    private let disposeBag = DisposeBag()
    // 5.9 新分享面板需要外部持有
    private var sharePanel: LarkSharePanel?
    private lazy var container = InviteContainerView(hostViewController: self, navigator: userResolver.navigator)
    private lazy var copyCodeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.N200), for: .highlighted)
        button.setTitleColor(UIColor.ud.N900, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = IGLayer.commonButtonRadius
        button.layer.masksToBounds = true
        button.setTitle(BundleI18n.LarkContact.Lark_AdminUpdate_Button_MobileCopyInviteCode, for: .normal)
        button.rx.controlEvent(.touchUpInside)
        .asDriver()
        .drive(onNext: { [weak self] (_) in
            self?.copyButtonDidClick()
        }).disposed(by: disposeBag)
        return button
    }()

    private lazy var shareCodeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.primaryContentDefault), for: .normal)
        button.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.B600), for: .highlighted)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.layer.cornerRadius = IGLayer.commonButtonRadius
        button.layer.masksToBounds = true
        button.setTitle(BundleI18n.LarkContact.Lark_AdminUpdate_Button_MobileShareInviteCode, for: .normal)
        button.rx.controlEvent(.touchUpInside).asDriver().drive(onNext: { [weak self] (_) in
            self?.shareButtonDidClick()
        }).disposed(by: disposeBag)
        return button
    }()
    private let emptyView = UDEmptyView(
        config: UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: BundleI18n.LarkContact.Lark_UserGrowth_InviteMemberPermissionDeny),
        type: .noAccess)
    )

    static private let logger = Logger.log(TeamCodeInviteController.self,
                                           category: "LarkContact.MemberInviteNoDirectionalController")

    init(viewModel: TeamCodeInviteViewModel, resolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        fetchInviteLinkInfo()

        Tracer.trackAddMemberTeamCodeShow(source: viewModel.sourceScenes)

        userAPI?.isAdministrator()
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isAdmin in
                if isAdmin {
                    self?.container.tipText = BundleI18n.LarkContact.Lark_AdminUpdate_Toast_MobileOrgInviteCodeAdmin
                } else {
                    self?.container.tipText = BundleI18n.LarkContact.Lark_AdminUpdate_Toast_MobileOrgInviteCodeContactAdmin
                }
            }).disposed(by: self.disposeBag)

        var isDarkModeTheme: Bool = false
        if #available(iOS 13.0, *) {
            isDarkModeTheme = UDThemeManager.getRealUserInterfaceStyle() == .dark
        }
        container.setAuroraEffect(isDarkModeTheme: isDarkModeTheme)
    }

    private func setupViews() {
        self.title = BundleI18n.LarkContact.Lark_Invitation_AddMembers_SubtitleTwo_AddMemberstoJoin_TeamCode
        view.backgroundColor = UIColor.ud.bgBody
        self.navigationController?.navigationBar.barTintColor = UIColor.ud.bgBody

        if viewModel.isOversea {
            container.tipLabel.text = BundleI18n.LarkContact.Lark_AdminUpdate_Subtitle_MobileInviteBelowOrg
            container.infoButton.isHidden = true
        } else {
            container.tipLabel.text = BundleI18n.LarkContact.Lark_AdminUpdate_PH_MobileOrgQRCode
        }
        container.onResetBlock = { [weak self] in
            self?.refreshButtonDidClick()
        }
        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalTo(36)
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.height.greaterThanOrEqualTo(380)
        }

        container.addSubview(teamCodeWrapView)
        teamCodeWrapView.snp.makeConstraints { (make) in
            make.top.equalTo(136)
            make.left.right.equalToSuperview().inset(20)
            make.height.greaterThanOrEqualTo(148)
        }

        if viewModel.teamCodeCopyEnable {
            view.addSubview(copyCodeButton)
            copyCodeButton.snp.makeConstraints { (make) in
                make.leading.equalTo(view).offset(16)
                make.trailing.equalTo(view.snp.centerX).offset(-8)
                make.height.equalTo(40)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
            }
        }

        view.addSubview(shareCodeButton)
        shareCodeButton.snp.makeConstraints { (make) in
            if viewModel.teamCodeCopyEnable {
                make.leading.equalTo(view.snp.centerX).offset(8)
            } else {
                make.leading.equalTo(view).offset(16)
            }
            make.trailing.equalTo(view).inset(16)
            make.height.equalTo(40)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.ud.fromPureColor(.clear), for: .default)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *),
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            return
        }
        container.setAuroraEffect(isDarkModeTheme: UDThemeManager.getRealUserInterfaceStyle() == .dark)
    }

    func fetchInviteLinkInfo(forceRefresh: Bool = false) {
        let hud = UDToast.showLoading(on: view)
        viewModel.fetchInviteInfo(forceRefresh: forceRefresh)
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (inviteInfo) in
                guard let `self` = self else { return }

                guard let url = inviteInfo.memberExtraInfo?.urlForLink, !url.isEmpty else {
                    self.showNoPermissionPage()
                    return
                }

                self.inviteInfo = inviteInfo
                hud.remove()
                if forceRefresh {
                    UDToast.showSuccess(with: BundleI18n.LarkContact.Lark_AdminUpdate_Toast_MobileReset, on: self.view)
                    self.container.setRefreshing(false)
                }

            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                if forceRefresh {
                    UDToast.showFailure(with: BundleI18n.LarkContact.Lark_AdminUpdate_Toast_MobileReset, on: self.view)
                    self.container.setRefreshing(false)
                    guard let err = error as? MemberInviteAPI.WrapError else { return }
                    switch err {
                    case .buzError(let displayMsg):
                        UDToast.showTips(with: displayMsg, on: self.view)
                    default: break
                    }
                } else {
                    self.retryLoadingView.isHidden = false
                }
                hud.remove()
            }, onDisposed: {
                hud.remove()
            }).disposed(by: disposeBag)
    }

    func showNoPermissionPage() {
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func copyButtonDidClick() {
        copyInviteMsg()
    }

    func shareButtonDidClick() {
        guard let inviteInfo = inviteInfo, let memberExtraInfo = inviteInfo.memberExtraInfo else {
            return
        }
        let (title, content) = viewModel.shareContext(
         tenantName: inviteInfo.tenantName,
         url: memberExtraInfo.urlForLink,
         teamCode: memberExtraInfo.teamCode
        )
        TeamCodeInviteController.logger.info("start share team code")
        var shareContent = content
        /// Because WeChat does not currently recognize non-newlined link-containing plain text,
        /// so you need to manually handle the line feed here.
        if shareContent.contains("http") {
            shareContent.range(of: "http").flatMap { shareContent.replaceSubrange($0, with: "\nhttp") }
        }

        let webpagePrepare = WebUrlPrepare(
            title: shareContent,
            webpageURL: memberExtraInfo.urlForLink
        )
        let shareContentContext = ShareContentContext.webUrl(webpagePrepare)
        let downgradePanelMeterial = DowngradeTipPanelMaterial.text(
            panelTitle: title,
            content: shareContent
        )
        let sourceView = shareCodeButton
        let popoverMaterial = PopoverMaterial(
            sourceView: sourceView,
            sourceRect: CGRect(x: sourceView.frame.width / 2, y: -10, width: 30, height: 30),
            direction: .down
        )

        // 5.9 FG 控制是否使用新分享组件
        if userResolver.fg.staticFeatureGatingValue(with: "admin.share.component") {
            // product level & scene see in https://bytedance.feishu.cn/sheets/shtcnAcBrNPsFxdeVs4U54Ihywc
            var sharePanel = LarkSharePanel(userResolver: userResolver,
                                            by: "lark.invite.member.teamcode",
                                            shareContent: shareContentContext,
                                            on: self,
                                            popoverMaterial: popoverMaterial,
                                            productLevel: "Admin",
                                            scene: "Invite_Code",
                                            pasteConfig: .scPasteImmunity)

            sharePanel.downgradeTipPanel = downgradePanelMeterial
            self.sharePanel = sharePanel

            self.sharePanel?.show { [weak self] (result, type) in
                guard let self = self else { return }
                Tracer.trackAddMemberTeamCodeShareClick(source: self.viewModel.sourceScenes, method: type.teaDesc())
                if result.isSuccess() {
                    if case .copy = type {
                        self.copyInviteMsg()
                    }
                    InviteMonitor.post(
                        name: Homeric.UG_INVITE_MEMBER_NONDIRECTIONAL_SHARE,
                        category: ["succeed": "true",
                                   "type": "teamcode",
                                   "item": String.desc(with: type)]
                    )
                } else {
                    self.handleShareError(result: result, itemType: type)
                }
                let logMsg = "member invite share TeamCode \(result.isSuccess() ? "success" : "failed") by \(type)"
                TeamCodeInviteController.logger.info(logMsg)
            }
        } else {
            snsShareService?.present(
                by: "lark.invite.member.teamcode",
                contentContext: shareContentContext,
                baseViewController: self,
                downgradeTipPanelMaterial: downgradePanelMeterial,
                customShareContextMapping: [:],
                defaultItemTypes: [],
                popoverMaterial: popoverMaterial) { [weak self] (result, type) in
                    guard let `self` = self else { return }
                    Tracer.trackAddMemberTeamCodeShareClick(source: self.viewModel.sourceScenes, method: type.teaDesc())
                    if result.isSuccess() {
                        if case .copy = type {
                            self.copyInviteMsg()
                        }
                        InviteMonitor.post(
                            name: Homeric.UG_INVITE_MEMBER_NONDIRECTIONAL_SHARE,
                            category: ["succeed": "true",
                                       "type": "teamcode",
                                       "item": String.desc(with: type)]
                        )
                    } else {
                        self.handleShareError(result: result, itemType: type)
                    }
                    let logMsg = "member invite share TeamCode \(result.isSuccess() ? "success" : "failed") by \(type)"
                    TeamCodeInviteController.logger.info(logMsg)
            }

        }

    }

    func refreshButtonDidClick() {
        Tracer.trackAddMemberInviteRefreshClick(source: viewModel.sourceScenes, sourceTab: .teamCode)
        TeamCodeInviteController.logger.info("refresh link")
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkContact.Lark_Legacy_Hint)
        alertController.setContent(text: BundleI18n.LarkContact.Lark_Invitation_AddMembersRefreshDialogContentTeamCode)
        alertController.addSecondaryButton(text: BundleI18n.LarkContact.Lark_Invitation_AddMembersRefreshDialogCancel, dismissCompletion: {
            Tracer.trackAddMemberInviteRefreshCancelClick(source: self.viewModel.sourceScenes)
        })
        alertController.addDestructiveButton(text: BundleI18n.LarkContact.Lark_Invitation_AddMembers_SharedInvitationInfo_ResetButton, dismissCompletion: {
            Tracer.trackAddMemberInviteRefreshConfirmClick(source: self.viewModel.sourceScenes)
            self.container.setRefreshing(true)
            self.fetchInviteLinkInfo(forceRefresh: true)
        })
        navigator.present(alertController, from: self)
    }

    private lazy var teamCodeWrapView: TeamCodeWrapView = {
        let view = TeamCodeWrapView()
        return view
    }()
}

private extension TeamCodeInviteController {

    func copyInviteMsg() {
        guard let inviteInfo = inviteInfo,
              let memberInviteExtra = inviteInfo.memberExtraInfo else {
            return
        }
        let content = viewModel.shareContext(
            tenantName: inviteInfo.tenantName,
            url: memberInviteExtra.urlForLink,
            teamCode: memberInviteExtra.teamCode
        ).content
        LKMetric.IN.copyTeamCodeSuccess()
        InviteMonitor.post(
            name: Homeric.UG_INVITE_MEMBER_NONDIRECTIONAL_COPY,
            category: ["succeed": "true",
                       "type": "teamcode"]
        )
        Tracer.trackAddMemberTeamCodeCopyClick(source: viewModel.sourceScenes)
        TeamCodeInviteController.logger.info("copy team code")
        if ContactPasteboard.writeToPasteboard(string: content, shouldImmunity: true) {
            let successTip = BundleI18n.LarkContact.Lark_Legacy_CopyReady
            UDToast.showTips(with: successTip, on: view)
        } else {
            UDToast.showFailure(with: BundleI18n.LarkContact.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: view)
        }
    }

    func handleShareError(result: ShareResult, itemType: LarkShareItemType) {
        if case .failure(let errorCode, let debugMsg) = result {
            InviteMonitor.post(
                name: Homeric.UG_INVITE_MEMBER_NONDIRECTIONAL_SHARE,
                category: ["succeed": "false",
                           "type": "teamcode",
                           "item": String.desc(with: itemType),
                           "error_code": errorCode.rawValue],
                extra: ["error_msg": debugMsg]
            )
            switch errorCode {
            case .notInstalled:
                if let window = self.view.window {
                    UDToast.showTipsOnScreenCenter(with: debugMsg, on: window)
                }
            default:
                TeamCodeInviteController.logger.info("handleShareError.default",
                                                     additionalData: ["errorCode": String(describing: debugMsg),
                                                                      "errorMsg": String(describing: debugMsg)])
            }
        }
    }

}
