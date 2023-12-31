//
//  MemberInviteGuideController.swift
//  LarkContact
//
//  Created by shizhengyu on 2021/4/6.
//

import UIKit
import LarkUIKit
import SnapKit
import RxSwift
import LKCommonsLogging
import LarkMessengerInterface
import UniverseDesignToast
import UniverseDesignFont
import LarkSnsShare
import LarkAlertController
import EENavigator
import Foundation
import UniverseDesignDialog
import LarkFeatureGating
import LarkEMM
import LarkContainer
import LarkSensitivityControl

protocol MemberInviteGuideRouter: ShareRouter {
    func presentSelectContactListVC(from: BaseUIViewController, presenter: ContactBatchInvitePresenter)
}

final class MemberInviteGuideController: MemberInviteBaseViewController, MemberInviteGuideCardViewDelegate, MemberInviteGuideLarkCardViewDelegate, MemberInviteGuideLinkViewDelegate {
    /// 新 通用分享面板 - 二维码
    private var qrCodeSharePanel: LarkSharePanel?
    /// 新通用分享面板FG
    private lazy var newSharePanelFGEnabled: Bool = userResolver.fg.staticFeatureGatingValue(with: "app.share.panel")

    private let viewModel: MemberInviteGuideViewModel
    static private let logger = Logger.log(MemberInviteGuideController.self,
                                           category: "LarkContact.MemberInviteGuideController")
    private let scrollView = UIScrollView()
    private let mainTitleLabel = UILabel()
    private let descLabel = InsetsLabel(frame: .zero, insets: .zero)
    private lazy var cardView: MemberInviteGuideCardView = {
        let view = MemberInviteGuideCardView(delegate: self)
        return view
    }()

    private lazy var linkCardView: MemberInviteGuideLinkView = {
        let view = MemberInviteGuideLinkView(delegate: self)
        return view
    }()

    private lazy var larkCardView: MemberInviteGuideLarkCardView = {
        let view = MemberInviteGuideLarkCardView(delegate: self)
        return view
    }()

    private lazy var popoverMaterial: PopoverMaterial = {
        let sourceView = self.viewModel.isOversea ?
            self.larkCardView.shareSourceView :
            self.linkCardView.shareSourceView
        return PopoverMaterial(
            sourceView: sourceView,
            sourceRect: CGRect(x: sourceView.frame.width / 2, y: -10, width: 30, height: 30),
            direction: .down
        )
    }()

    private let moreButton = UIButton()

    init(viewModel: MemberInviteGuideViewModel, resolver: UserResolver) {
        self.viewModel = viewModel
        super.init(resolver: resolver)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .color(UIColor.ud.bgBody)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
        layoutPageSubviews()
        setNavigationBar()
        Tracer.trackOnboardingGuideAddmemberShow()
        Tracer.trackTeamQrcodeAddMemberGuideView()
        self.fetchInviteLinkInfo()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// passport 页面跳转过来，导航栏不是使用的LKNavigationController
        /// 导航栏存在黑线情况，单独处理下
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.bgBody), for: .default)
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.shadowImage = UIImage.ud.fromPureColor(.clear)
            appearance.backgroundImage = UIImage.ud.fromPureColor(UIColor.ud.bgBody)
            self.navigationController?.navigationBar.standardAppearance = appearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        (self.navigationController as? LkNavigationController)?.update(style: self.navigationBarStyle)
        navigationItem.leftBarButtonItem = nil
    }

    @discardableResult
    override func addCloseItem() -> UIBarButtonItem {
        let barItem = LKBarButtonItem()
        /// Base 控制器会在切换时候自动添加关闭按钮
        /// 但是本页面不需要关闭按钮
        self.navigationItem.leftBarButtonItem = nil
        return barItem
    }

    @discardableResult
    override func addBackItem() -> UIBarButtonItem {
        let barItem = LKBarButtonItem()
        /// Base 控制器会在切换时候自动添加关闭按钮
        /// 但是本页面不需要返回按钮
        self.navigationItem.leftBarButtonItem = nil
        return barItem
    }

    @objc
    func moreButtonDidClick() {
        // 弹出通讯录
        viewModel.router.presentSelectContactListVC(from: self, presenter: viewModel.prensenter)
        Tracer.trackTeamQrcodeAddMemberGuideViewClick(clickEvent: "team_addmember_addressbook",
                                                      target: "onboarding_team_addmember_addressbook_view")
    }

    @objc
    func skipStep() {
        viewModel.reportEndGuide()
        Tracer.trackTeamQrcodeAddMemberGuideViewClick(clickEvent: "next", target: "onboarding_operating_activities_view")
        if Display.pad {
            self.dismiss(animated: true)
            return
        }
        self.dismiss(animated: true) {
            OnboardingTaskManager.getSharedInstance().executeNextTask()
        }
    }

    func saveButtonDidClick() {
        Tracer.trackOnboardingGuideAddmemberSave()
        Tracer.trackTeamQrcodeAddMemberGuideViewClick(clickEvent: "mobile_qrcode_save", target: "none")
        downloadRendedImageIfNeeded { [weak self] (image) in
            self?.saveQRCodeImage(cardImage: image)
        }
    }

    func shareButtonDidClick() {
        Tracer.trackOnboardingGuideAddmemberShare()
        Tracer.trackTeamQrcodeAddMemberGuideViewClick(clickEvent: "mobile_qrcode_share", target: "none")
        downloadRendedImageIfNeeded { [weak self] (image) in
            self?.shareQRCode(cardImage: image)
        }
    }

    @objc
    private func savePhotoToAlbum(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        if error == nil {
            Self.logger.info("save qrcode image success")
            UDToast.showTips(with: BundleI18n.LarkContact.Lark_Legacy_QrCodeSaveAlbum, on: view)
        } else {
            Self.logger.info("savePhotoToAlbum failed, error >>> \(String(describing: error?.localizedDescription))")

            let dialog = UDDialog.noPermissionDialog(title: BundleI18n.LarkContact.Lark_Core_PhotoAccessForSavePhoto,
                                                     detail: BundleI18n.LarkContact.Lark_Core_PhotoAccessForSavePhoto_Desc())
            navigator.present(dialog, from: self)
        }
    }

    /// MemberInviteGuideLinkCardViewDelegate
    func copyButtonDidClick() {
        /// copy link
        Tracer.trackTeamQrcodeAddMemberGuideViewClick(clickEvent: "mobile_link_copy", target: "none")

        guard let inviteInfo = inviteInfo,
              let memberExtraInfo = inviteInfo.memberExtraInfo else {
            return
        }
        let content = viewModel.shareContext(
         tenantName: inviteInfo.tenantName,
         url: memberExtraInfo.urlForLink,
         teamCode: memberExtraInfo.teamCode
        ).content
        if ContactPasteboard.writeToPasteboard(string: content, shouldImmunity: true) {
            let successTip = BundleI18n.LarkContact.Lark_Legacy_CopyReady
            UDToast.showTips(with: successTip, on: view)
        } else {
            UDToast.showFailure(with: BundleI18n.LarkContact.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: view)
        }
    }

    func linkShareButtonDidClick() {
        /// share link
        Tracer.trackTeamQrcodeAddMemberGuideViewClick(clickEvent: "mobile_link_share", target: "none")
        self.shareLink(channel: "lark.invite.member.qrcode")
    }

    /// MemberInviteGuideLarkCardViewDelegate
    func larkShareButtonDidClick() {
        /// share link
        Tracer.trackTeamQrcodeAddMemberGuideViewClick(clickEvent: "link_copy", target: "none")
        self.shareLink(channel: "lark.op.system")
    }

    func sendEmailButtonDicClick() {
        /// send email invite
        Tracer.trackTeamQrcodeAddMemberGuideViewClick(clickEvent: "mobile_email_invitation", target: "none")

        let body = MemberDirectedInviteBody(sourceScenes: .larkGuide,
                                            isFromInviteSplitPage: false,
                                            departments: [],
                                            needShowType: .email)
        navigator.present(
            body: body,
            wrap: LkNavigationController.self,
            from: self,
            prepare: {
                $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            })
    }

    func invitePhoneButtonDidClick() {
        /// send contact invite
        Tracer.trackTeamQrcodeAddMemberGuideViewClick(clickEvent: "mobile_import_contacts", target: "none")

        viewModel.router.presentSelectContactListVC(from: self, presenter: viewModel.prensenter)
    }
}

private extension MemberInviteGuideController {
    func shareLink(channel: String) {
        guard let inviteInfo = inviteInfo,
              let memberExtraInfo = inviteInfo.memberExtraInfo else {
            return
        }

        let inviteLinkMsg = memberExtraInfo.urlForLink
        /// Because WeChat does not currently recognize non-newlined link-containing plain text,
        /// so you need to manually handle the line feed here.
        var finalLinkMsg = inviteLinkMsg
        if inviteLinkMsg.contains("http") {
            if let range = inviteLinkMsg.range(of: "http") {
                finalLinkMsg.replaceSubrange(range, with: "\nhttp")
            }
        }

        guard let url = finalLinkMsg.components(separatedBy: "\n").last else { return }

        let webpagePrepare = WebUrlPrepare(
            title: BundleI18n.LarkContact.Lark_UserGrowth_InvitePeopleContactsShareLinkTitle(),
            webpageURL: url
        )
        let shareContentContext = ShareContentContext.webUrl(webpagePrepare)
        let downgradePanelMeterial = DowngradeTipPanelMaterial.text(
            panelTitle: BundleI18n.LarkContact.Lark_Invitation_InviteViaWeChat_InviteLinkCopied_Title,
            content: inviteLinkMsg
        )
        snsShareService?.present(
            by: channel,
            contentContext: shareContentContext,
            baseViewController: self,
            downgradeTipPanelMaterial: downgradePanelMeterial,
            customShareContextMapping: [:],
            defaultItemTypes: [],
            popoverMaterial: self.popoverMaterial,
            pasteConfig: .scPasteImmunity) { [weak self] (result, type) in
            guard let `self` = self else { return }
            if result.isSuccess() {
                if case .copy = type {
                    self.copyButtonDidClick()
                }
            } else {
                self.handleShareError(result: result, itemType: type)
            }
        }
    }

    func shareQRCode(cardImage: UIImage) {
        if let inviteInfo = inviteInfo {
            Self.logger.info("start share qrcode image")

            let imagePrepare = ImagePrepare(
                title: BundleI18n.LarkContact.Lark_Invitation_AddMembersLinkTitle(inviteInfo.name, inviteInfo.tenantName),
                image: cardImage
            )
            let shareContentContext = ShareContentContext.image(imagePrepare)
            let downgradePanelMeterial = DowngradeTipPanelMaterial.image(panelTitle: nil)
            let popoverMaterial = PopoverMaterial(
                sourceView: cardView.shareSourceView,
                sourceRect: CGRect(x: cardView.shareSourceView.frame.width / 2, y: -10, width: 30, height: 30),
                direction: .down
            )
            if self.newSharePanelFGEnabled {
                self.qrCodeSharePanel = LarkSharePanel(userResolver: userResolver,
                                                       by: "lark.invite.member.qrcode",
                                                       shareContent: shareContentContext,
                                                       on: self,
                                                       popoverMaterial: popoverMaterial,
                                                       productLevel: "UG",
                                                       scene: "Onborading")
                self.qrCodeSharePanel?.downgradeTipPanel = downgradePanelMeterial
                self.qrCodeSharePanel?.show { [weak self] (result, type) in
                    if result.isSuccess() {
                        self?.handleShareSuccess()
                    } else {
                        self?.handleShareError(result: result, itemType: type)
                    }
                    let logMsg = "member invite share QRCode \(result.isSuccess() ? "success" : "failed") by \(type)"
                    Self.logger.info(logMsg)
                }
            } else {
                snsShareService?.present(by: "lark.invite.member.qrcode",
                                        contentContext: shareContentContext,
                                        baseViewController: self,
                                        downgradeTipPanelMaterial: downgradePanelMeterial,
                                        customShareContextMapping: [:],
                                        defaultItemTypes: [],
                                        popoverMaterial: popoverMaterial) { [weak self] (result, type) in
                    if result.isSuccess() {
                        self?.handleShareSuccess()
                    } else {
                        self?.handleShareError(result: result, itemType: type)
                    }
                    let logMsg = "member invite share QRCode \(result.isSuccess() ? "success" : "failed") by \(type)"
                    Self.logger.info(logMsg)
                }
            }
        }
    }

    func layoutPageSubviews() {
        view.backgroundColor = UIColor.ud.bgBody

        scrollView.backgroundColor = UIColor.ud.bgBody
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)

        mainTitleLabel.textAlignment = .left
        mainTitleLabel.textColor = UIColor.ud.textTitle
        mainTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        mainTitleLabel.numberOfLines = Display.pad ? 1 : 2
        mainTitleLabel.lineBreakMode = .byTruncatingTail
        let labelTxt = self.viewModel.isOversea ?
            BundleI18n.LarkContact.Lark_Guide_TeamCreate2Title() :
            BundleI18n.LarkContact.Lark_Guide_TeamInviteTitle()
        mainTitleLabel.text = labelTxt
        scrollView.addSubview(mainTitleLabel)

        descLabel.textAlignment = .left
        descLabel.textColor = UIColor.ud.textCaption
        descLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        descLabel.numberOfLines = Display.pad ? 1 : 2
        var descTitle = BundleI18n.LarkContact.Lark_Guide_TeamInviteSubTitleMobile
        switch self.viewModel.inviteType {
        case .link:
            descTitle = BundleI18n.LarkContact.Lark_Guide_TeamInviteSubTitleMobileV2
        case .split:
            descTitle = BundleI18n.LarkContact.Lark_Guide_TeamCreate2SubTitle()
        case .qrcode:
            descTitle = BundleI18n.LarkContact.Lark_Guide_TeamInviteSubTitleMobile
        default:
            break
        }
        descLabel.text = descTitle
        scrollView.addSubview(descLabel)

        scrollView.snp.makeConstraints { (make) in
            make.top.bottom.leading.trailing.equalToSuperview()
        }
        let topOffset = Display.pad ? 20 : 32
        mainTitleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(topOffset)
            make.leading.trailing.equalToSuperview().inset(20)
            make.width.equalToSuperview().offset(-40)
        }
        descLabel.snp.makeConstraints { (make) in
            make.top.equalTo(mainTitleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(20)
            make.width.equalToSuperview().offset(-40)
        }

        if self.viewModel.isOversea {
            scrollView.addSubview(larkCardView)
            larkCardView.snp.makeConstraints { (make) in
                make.top.equalTo(descLabel.snp.bottom).offset(22)
                make.width.equalToSuperview()
            }
        } else {
            if self.viewModel.inviteType == .link {
                scrollView.addSubview(linkCardView)
                linkCardView.snp.makeConstraints { (make) in
                    make.top.equalTo(descLabel.snp.bottom).offset(24)
                    make.leading.trailing.equalToSuperview().inset(16)
                    make.bottom.equalToSuperview().inset(16)
                    make.width.equalToSuperview().offset(-32)
                }
            } else {
                scrollView.addSubview(cardView)
                cardView.snp.makeConstraints { (make) in
                    make.top.equalTo(descLabel.snp.bottom).offset(24)
                    make.leading.trailing.equalToSuperview().inset(16)
                    make.bottom.equalToSuperview().inset(16)
                    make.width.equalToSuperview().offset(-32)
                }
            }

            moreButton.setTitleColor(UIColor.ud.textLinkHover, for: .normal)
            moreButton.titleLabel?.font = UDFont.headline
            let title = BundleI18n.LarkContact.Lark_Invitation_AddMembers_SubtitleThree_AddMembersDirectly_ImportFromContacts
            moreButton.setTitle(title, for: .normal)
            moreButton.addTarget(self, action: #selector(moreButtonDidClick), for: .touchUpInside)
            view.addSubview(moreButton)

            scrollView.snp.remakeConstraints { (make) in
                make.top.leading.trailing.equalToSuperview()
                make.bottom.equalTo(moreButton.snp.top)
            }
            moreButton.snp.makeConstraints { (make) in
                make.height.equalTo(24)
                make.width.equalToSuperview().offset(-16)
                make.bottom.equalToSuperview().inset(Display.iPhoneXSeries ? 42 : 24)
                make.centerX.equalToSuperview()
            }
        }
    }

    func setNavigationBar() {
        // clear left back button
        navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.leftBarButtonItem = nil
        // add right skip button
        let skipItem = LKBarButtonItem()
        skipItem.button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        skipItem.button.titleLabel?.font = UDFont.headline
        skipItem.resetTitle(title: BundleI18n.LarkContact.Lark_Passport_AppealNextButton, font: UDFont.headline)
        skipItem.button.addTarget(self, action: #selector(skipStep), for: .touchUpInside)
        navigationItem.rightBarButtonItem = skipItem
    }

    func fetchInviteLinkInfo(forceRefresh: Bool = false) {
        super.fetchInviteLinkInfo(forceRefresh: forceRefresh)
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (inviteInfo) in
                Self.logger.info("fetchInviteLinkInfo success")
                if self?.viewModel.inviteType == .qrcode {
                    self?.cardView.bindWithModel(cardInfo: inviteInfo)
                } else if self?.viewModel.inviteType == .link {
                    self?.linkCardView.bindWithModel(cardInfo: inviteInfo)
                }
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                Self.logger.warn("fetchInviteLinkInfo failed, err = \(error.localizedDescription)")
                self.dismiss(animated: true)
            }).disposed(by: disposeBag)
    }

    func downloadRendedImageIfNeeded(completion: @escaping (UIImage) -> Void) {
        exportDisposable = super.downloadRendedImageIfNeeded()
            .subscribe(onNext: { (outputLayer) in
                Self.logger.info("save qrcode image")
                completion(outputLayer)
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                if let error = error as? DynamicResourceExportError {
                    switch error {
                    case .pullDynamicResourceFailed(let logMsg, let userMsg):
                        Self.logger.warn(logMsg)
                        UDToast.showFailure(with: userMsg, on: self.view)
                    case .downloadFailed(let logMsg):
                        Self.logger.warn(logMsg)
                    case .constraintsError(let logMsg):
                        Self.logger.warn(logMsg)
                    case .bytesParseFailed(let logMsg):
                        Self.logger.warn(logMsg)
                    case .graphContextError(let logMsg):
                        Self.logger.warn(logMsg)
                    case .unknownError(let logMsg):
                        Self.logger.warn(logMsg)
                    }
                }
            })
    }

    func saveQRCodeImage(cardImage: UIImage) {
        Self.logger.info("save qrcode image")
        do {
            let token = Token("LARK-PSDA-member_invite_guide_qrcode_save")
            try AlbumEntry.UIImageWriteToSavedPhotosAlbum(forToken: token, cardImage, self, #selector(savePhotoToAlbum(image:didFinishSavingWithError:contextInfo:)), nil)
        } catch {
            ContactLogger.shared.error(module: .action, event: "\(Self.self) no save image token: \(error.localizedDescription)")
        }

    }

    func handleShareError(result: ShareResult, itemType: LarkShareItemType) {
        if case .failure(let errorCode, let debugMsg) = result {
            switch errorCode {
            case .notInstalled, .saveImageFailed:
                if let window = view.window {
                    UDToast.showTipsOnScreenCenter(with: debugMsg, on: window)
                }
            default:
                Self.logger.info("handleShareError.default",
                                 additionalData: ["errorCode": String(describing: debugMsg),
                                                  "errorMsg": String(describing: debugMsg)])
            }
        }
    }

    func handleShareSuccess() {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkContact.Lark_Guide_TeamCreate2ShareSuccess)
        alertController.addSecondaryButton(text: BundleI18n.LarkContact.Lark_Invitation_AddMembersInviteMore, dismissCompletion: {
            Tracer.trackOnboardingGuideAddmemberInviteMore()
        })
        alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Passport_AppealNextButton, dismissCompletion: { [weak self] in
            Tracer.trackOnboardingGuideAddmemberInviteNext()
            self?.dismiss(animated: true, completion: {
                OnboardingTaskManager.getSharedInstance().executeNextTask()
            })
        })
        navigator.present(alertController, from: self)
    }
}
