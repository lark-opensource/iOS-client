//
//  MemberInviteNoDirectionalController.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/15.
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
import Homeric
import QRCode
import LarkSnsShare
import UniverseDesignTheme
import UniverseDesignColor
import LarkNavigation
import UniverseDesignIcon
import UniverseDesignDialog
import LarkFeatureGating
import LarkEMM
import LarkContainer
import LarkSDKInterface
import UniverseDesignEmpty
import LarkSensitivityControl

protocol MemberInviteNoDirectionalControllerRouter: ShareRouter {
    /// 成员邀请帮助中心
    func pushMemberInvitationHelpCenterViewController(vc: BaseUIViewController)
}

final class MemberInviteNoDirectionalController: MemberInviteBaseViewController, CardInteractiable {
    typealias ShareSource = MemberNoDirectionalDisplayPriority
    private let viewModel: MemberNoDirectionalViewModel
    private let monitor = InviteMonitor()
    private var currentDisplayCardType: ShareSource
    private var gapScale: CGFloat {
        if Display.pad {
            return 0.25
        }
        return UIScreen.main.bounds.height / 896.0
    }
    private let emptyView = UDEmptyView(
        config: UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: BundleI18n.LarkContact.Lark_UserGrowth_InviteMemberPermissionDeny),
        type: .noAccess)
    )

    // 5.9 新分享面板需要外部持有
    private var linkSharePanel: LarkSharePanel?
    private var qrCodeSharePanel: LarkSharePanel?
    static private let logger = Logger.log(MemberInviteNoDirectionalController.self,
                                           category: "LarkContact.MemberInviteNoDirectionalController")
    @ScopedInjectedLazy private var userAPI: UserAPI?

    init(viewModel: MemberNoDirectionalViewModel, resolver: UserResolver) {
        self.viewModel = viewModel
        self.currentDisplayCardType = viewModel.displayPriority
        super.init(resolver: resolver)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutPageSubviews()
        fetchInviteLinkInfo()
        buzTrackWhenAppear()
        buzTrackWhenDisappear()
        retryLoadingView.retryAction = { [unowned self] in
            self.fetchInviteLinkInfo()
        }

        userAPI?.isAdministrator()
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isAdmin in
                self?.qrcodeCard.isAdmin = isAdmin
                self?.linkCard.isAdmin = isAdmin
            }).disposed(by: self.disposeBag)

        var isDarkModeTheme: Bool = false
        if #available(iOS 13.0, *) {
            isDarkModeTheme = UDThemeManager.getRealUserInterfaceStyle() == .dark
        }
        qrcodeCard.setContainerAuroraEffect(isDarkModeTheme: isDarkModeTheme)
        linkCard.setContainerAuroraEffect(isDarkModeTheme: isDarkModeTheme)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.bgLogin), for: .default)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !switchContainer.contentOffset.x.isZero && switchContainer.contentOffset.x != view.frame.width {
            switchContainer.scrollRectToVisible(
                CGRect(x: view.frame.width,
                       y: 0,
                       width: switchContainer.frame.width,
                       height: switchContainer.frame.height),
                animated: false
            )
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *),
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            return
        }
        qrcodeCard.setContainerAuroraEffect(isDarkModeTheme: UDThemeManager.getRealUserInterfaceStyle() == .dark)
        linkCard.setContainerAuroraEffect(isDarkModeTheme: UDThemeManager.getRealUserInterfaceStyle() == .dark)
    }

    private lazy var switchContainer: UIScrollView = {
        let container = UIScrollView()
        container.backgroundColor = .clear
        container.showsVerticalScrollIndicator = false
        container.alwaysBounceVertical = false
        container.isScrollEnabled = false
        container.contentInsetAdjustmentBehavior = .never
        return container
    }()

    private lazy var qrcodeCardContainer: UIView = {
        let container = UIView()
        container.backgroundColor = .clear
        return container
    }()

    private lazy var linkCardContainer: UIView = {
        let container = UIView()
        container.backgroundColor = .clear
        return container
    }()

    private lazy var qrcodeCard: QRCodeCardView = {
        let card = QRCodeCardView(isOversea: viewModel.isOversea, delegate: self, navigator: userResolver.navigator)
        return card
    }()

    private lazy var linkCard: LinkCardView = {
        let card = LinkCardView(isOversea: viewModel.isOversea, delegate: self, navigator: userResolver.navigator)
        return card
    }()

    private lazy var copyLinkButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.N200), for: .highlighted)
        button.setTitleColor(UIColor.ud.N900, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = IGLayer.commonButtonRadius
        button.layer.masksToBounds = true
        button.setTitle(BundleI18n.LarkContact.Lark_AdminUpdate_Button_MobileCopyLink, for: .normal)
        button.rx.controlEvent(.touchUpInside)
        .asDriver()
        .drive(onNext: { [weak self] (_) in
            self?.triggleOtherAction(cardType: .link)
        }).disposed(by: disposeBag)
        return button
    }()

    private lazy var shareLinkButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.primaryContentDefault), for: .normal)
        button.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.B600), for: .highlighted)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.layer.cornerRadius = IGLayer.commonButtonRadius
        button.layer.masksToBounds = true
        button.setTitle(BundleI18n.LarkContact.Lark_AdminUpdate_Button_MobileShareLink, for: .normal)
        button.rx.controlEvent(.touchUpInside).asDriver().drive(onNext: { [weak self] (_) in
            self?.triggleShareAction(cardType: .link)
        }).disposed(by: disposeBag)
        return button
    }()

    private lazy var saveQRCodeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.N200), for: .highlighted)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = IGLayer.commonButtonRadius
        button.layer.masksToBounds = true
        button.setTitle(BundleI18n.LarkContact.Lark_AdminUpdate_Button_MobileSaveQRCode, for: .normal)
        button.rx.controlEvent(.touchUpInside)
        .asDriver()
        .drive(onNext: { [weak self] (_) in
            self?.triggleOtherAction(cardType: .qrcode)
        }).disposed(by: disposeBag)
        return button
    }()

    private lazy var shareQRCodeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.primaryContentDefault), for: .normal)
        button.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.B600), for: .highlighted)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.layer.cornerRadius = IGLayer.commonButtonRadius
        button.layer.masksToBounds = true
        button.setTitle(BundleI18n.LarkContact.Lark_AdminUpdate_Button_MobileShareQRCode, for: .normal)
        button.rx.controlEvent(.touchUpInside).asDriver().drive(onNext: { [weak self] (_) in
            self?.triggleShareAction(cardType: .qrcode)
        }).disposed(by: disposeBag)
        return button
    }()

    // MARK: - CardInteractiable
    func triggleRefreshAction(cardType: CardViewType) {
        refreshLink()
    }

    func triggleShareAction(cardType: CardViewType) {
        switch cardType {
        case .qrcode:
            downloadRendedImageIfNeeded { [weak self] (image) in
                self?.shareQRCode(cardImage: image)
            }
        case .link:
            Tracer.trackEduClickCTA(by: .link, and: .share)
            shareLink()
        }
    }

    func triggleOtherAction(cardType: CardViewType) {
        switch cardType {
        case .qrcode:
            downloadRendedImageIfNeeded { [weak self] (image) in
                self?.saveQRCodeImage(cardImage: image)
            }
        case .link:
            Tracer.trackEduClickCTA(by: .link, and: .other)
            copyLink()
        }
    }

    @objc
    private func switchToAnother() {
        if let item = navigationItem.rightBarButtonItem as? LKBarButtonItem {
            item.button.isEnabled = false

            switch currentDisplayCardType {
            case .qrCode:
                currentDisplayCardType = .inviteLink
                Tracer.trackAddMemberSwitchLinkQrcodeClick(source: viewModel.sourceScenes)
                Self.logger.info("switch to link card")
            case .inviteLink:
                currentDisplayCardType = .qrCode
                Tracer.trackAddMemberSwitchLinkQrcodeClick(source: viewModel.sourceScenes)
                Self.logger.info("switch to qrcode card")
            }

            switchContainer.scrollRectToVisible(
                CGRect(x: switchContainer.contentOffset.x.isZero ? view.frame.width : 0,
                       y: 0,
                       width: switchContainer.frame.width,
                       height: switchContainer.frame.height),
                animated: true
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.resetNavigationBar()
                item.button.isEnabled = true
            }
        }
    }

    @objc
    private func savePhotoToAlbum(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        if error == nil {
            LKMetric.IN.saveQrCodePermissionSuccess()
            InviteMonitor.post(
                name: Homeric.UG_INVITE_MEMBER_NONDIR_SAVE_QR_PERMISSON,
                category: ["succeed": "true"]
            )
            Self.logger.info("save qrcode image success")
            UDToast.showTips(with: BundleI18n.LarkContact.Lark_AdminUpdate_Toast_MobileSaved, on: view)
        } else {
            LKMetric.IN.saveQrCodePermissionFailed(errorMsg: error?.localizedDescription ?? "")
            InviteMonitor.post(
                name: Homeric.UG_INVITE_MEMBER_NONDIR_SAVE_QR_PERMISSON,
                category: ["succeed": "false"]
            )
            Self.logger.info("savePhotoToAlbum failed, error >>> \(String(describing: error?.localizedDescription))")

            let dialog = UDDialog.noPermissionDialog(title: BundleI18n.LarkContact.Lark_Core_PhotoAccessForSavePhoto,
                                                     detail: BundleI18n.LarkContact.Lark_Core_PhotoAccessForSavePhoto_Desc())
            navigator.present(dialog, from: self)
        }
    }
}

// Biz Logic
private extension MemberInviteNoDirectionalController {
    func fetchInviteLinkInfo(forceRefresh: Bool = false) {
        super.fetchInviteLinkInfo(forceRefresh: forceRefresh, departments: viewModel.departments)
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (inviteInfo) in
                guard let self = self else { return }

                guard let url = inviteInfo.memberExtraInfo?.urlForLink, !url.isEmpty else {
                    self.showNoPermissionPage()
                    return
                }

                self.bindWithModel(inviteInfo)
                if forceRefresh {
                    UDToast.showSuccess(with: BundleI18n.LarkContact.Lark_AdminUpdate_Toast_MobileReset, on: self.view)
                    self.setRefreshing(false)
                }
            }, onError: { [weak self] (_) in
                guard let self = self else { return }

                if forceRefresh {
                    UDToast.showFailure(with: BundleI18n.LarkContact.Lark_AdminUpdate_Toast_MobileFailedToReset, on: self.view)
                    self.setRefreshing(false)
                }
            }).disposed(by: disposeBag)
    }

    func showNoPermissionPage() {
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        navigationItem.rightBarButtonItem = nil
    }

    func shareQRCode(cardImage: UIImage) {
        guard let inviteInfo = inviteInfo else {
            Self.logger.error("Cannot find invite info when share QR code ")
            return
        }
        Self.logger.info("start share qrcode image")

        let imagePrepare = ImagePrepare(
            title: BundleI18n.LarkContact.Lark_Invitation_AddMembersLinkTitle(inviteInfo.name, inviteInfo.tenantName),
            image: cardImage
        )
        let shareContentContext = ShareContentContext.image(imagePrepare)
        let downgradePanelMeterial = DowngradeTipPanelMaterial.image(panelTitle: nil)
        let popoverMaterial = PopoverMaterial(
            sourceView: shareQRCodeButton,
            sourceRect: CGRect(x: shareQRCodeButton.frame.width / 2, y: -10, width: 30, height: 30),
            direction: .down
        )

        // 5.9 FG 控制是否使用新分享组件
        if userResolver.fg.staticFeatureGatingValue(with: "admin.share.component") {
            // product level & scene see in https://bytedance.feishu.cn/sheets/shtcnAcBrNPsFxdeVs4U54Ihywc
            let qrCodeSharePanel = LarkSharePanel(userResolver: userResolver,
                                                  by: "lark.invite.member.qrcode",
                                                  shareContent: shareContentContext,
                                                  on: self,
                                                  popoverMaterial: popoverMaterial,
                                                  productLevel: "Admin",
                                                  scene: "Invite_QRCode",
                                                  pasteConfig: .scPasteImmunity)

            qrCodeSharePanel.downgradeTipPanel = downgradePanelMeterial
            self.qrCodeSharePanel = qrCodeSharePanel

            self.qrCodeSharePanel?.show { [weak self] (result, type) in
                guard let self = self else { return }
                Tracer.trackAddMemberQrcodeInviteShareClick(source: self.viewModel.sourceScenes, method: type.teaDesc())
                if result.isSuccess() {
                    InviteMonitor.post(
                        name: Homeric.UG_INVITE_MEMBER_NONDIRECTIONAL_SHARE,
                        category: ["succeed": "true",
                                   "type": "qrcode",
                                   "item": String.desc(with: type)]
                    )
                } else {
                    self.handleShareError(result: result, itemType: type)
                }
                let logMsg = "member invite share QRCode \(result.isSuccess() ? "success" : "failed") by \(type)"
                Self.logger.info(logMsg)
            }
        } else {
            snsShareService?.present(
                by: "lark.invite.member.qrcode",
                contentContext: shareContentContext,
                baseViewController: self,
                downgradeTipPanelMaterial: downgradePanelMeterial,
                customShareContextMapping: [:],
                defaultItemTypes: [],
                popoverMaterial: popoverMaterial) { [weak self] (result, type) in
                    guard let `self` = self else { return }
                    Tracer.trackAddMemberQrcodeInviteShareClick(source: self.viewModel.sourceScenes, method: type.teaDesc())
                    if result.isSuccess() {
                        InviteMonitor.post(
                            name: Homeric.UG_INVITE_MEMBER_NONDIRECTIONAL_SHARE,
                            category: ["succeed": "true",
                                       "type": "qrcode",
                                       "item": String.desc(with: type)]
                        )
                    } else {
                        self.handleShareError(result: result, itemType: type)
                    }
                    let logMsg = "member invite share QRCode \(result.isSuccess() ? "success" : "failed") by \(type)"
                    Self.logger.info(logMsg)
            }
        }
    }

    func saveQRCodeImage(cardImage: UIImage) {
        Tracer.trackAddMemberQrcodeInviteSaveClick(source: viewModel.sourceScenes)
        Self.logger.info("save qrcode image")
        do {
            let token = Token("LARK-PSDA-member_invite_no_directional_qrcode_save")
            try AlbumEntry.UIImageWriteToSavedPhotosAlbum(forToken: token, cardImage, self, #selector(savePhotoToAlbum(image:didFinishSavingWithError:contextInfo:)), nil)
        } catch {
            ContactLogger.shared.error(module: .action, event: "\(Self.self) no save image token: \(error.localizedDescription)")
        }

    }

    func shareLink() {
        guard let inviteInfo = inviteInfo,
              let memberExtraInfo = inviteInfo.memberExtraInfo else {
            return
        }
        let (title, content) = viewModel.shareContext(
         tenantName: inviteInfo.tenantName,
         url: memberExtraInfo.urlForLink,
         teamCode: memberExtraInfo.teamCode
        )
        Self.logger.info("start share link")
        /// Because WeChat does not currently recognize non-newlined link-containing plain text,
        /// so need to manually handle the line feed here.
        var shareContent = content
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
        let popoverMaterial = PopoverMaterial(
            sourceView: shareLinkButton,
            sourceRect: CGRect(x: shareLinkButton.frame.width / 2, y: -10, width: 30, height: 30),
            direction: .down
        )

        // 5.9 FG 控制是否使用新分享组件
        if userResolver.fg.staticFeatureGatingValue(with: "admin.share.component") {
            // product level & scene see in https://bytedance.feishu.cn/sheets/shtcnAcBrNPsFxdeVs4U54Ihywc
            var linkSharePanel = LarkSharePanel(userResolver: userResolver,
                                                by: "lark.invite.member.link",
                                                shareContent: shareContentContext,
                                                on: self,
                                                popoverMaterial: popoverMaterial,
                                                productLevel: "Admin",
                                                scene: "Invite_Link",
                                                pasteConfig: .scPasteImmunity)

            linkSharePanel.downgradeTipPanel = downgradePanelMeterial
            self.linkSharePanel = linkSharePanel

            self.linkSharePanel?.show { [weak self] (result, type) in
                guard let self = self else { return }
                Tracer.trackAddMemberLinkInviteShareClick(source: self.viewModel.sourceScenes, method: type.teaDesc())
                if result.isSuccess() {
                    if case .copy = type {
                        self.copyLink()
                    }
                    InviteMonitor.post(
                        name: Homeric.UG_INVITE_MEMBER_NONDIRECTIONAL_SHARE,
                        category: ["succeed": "true",
                                   "type": "link",
                                   "item": String.desc(with: type)]
                    )
                } else {
                    self.handleShareError(result: result, itemType: type)
                }
                let logMsg = "member invite share InviteLink \(result.isSuccess() ? "success" : "failed") by \(type)"
                Self.logger.info(logMsg)
            }
        } else {
            snsShareService?.present(
                by: "lark.invite.member.link",
                contentContext: shareContentContext,
                baseViewController: self,
                downgradeTipPanelMaterial: downgradePanelMeterial,
                customShareContextMapping: [:],
                defaultItemTypes: [],
                popoverMaterial: popoverMaterial) { [weak self] (result, type) in
                    guard let `self` = self else { return }
                    Tracer.trackAddMemberLinkInviteShareClick(source: self.viewModel.sourceScenes, method: type.teaDesc())
                    if result.isSuccess() {
                        if case .copy = type {
                            self.copyLink()
                        }
                        InviteMonitor.post(
                            name: Homeric.UG_INVITE_MEMBER_NONDIRECTIONAL_SHARE,
                            category: ["succeed": "true",
                                       "type": "link",
                                       "item": String.desc(with: type)]
                        )
                    } else {
                        self.handleShareError(result: result, itemType: type)
                    }
                    let logMsg = "member invite share InviteLink \(result.isSuccess() ? "success" : "failed") by \(type)"
                    Self.logger.info(logMsg)
            }
        }
    }

    func copyLink() {
        guard let inviteInfo = inviteInfo,
              let memberExtraInfo = inviteInfo.memberExtraInfo else {
            return
        }
        let content = viewModel.shareContext(
         tenantName: inviteInfo.tenantName,
         url: memberExtraInfo.urlForLink,
         teamCode: memberExtraInfo.teamCode
        ).content
        LKMetric.IN.copyLinkSuccess()
        InviteMonitor.post(
            name: Homeric.UG_INVITE_MEMBER_NONDIRECTIONAL_COPY,
            category: ["succeed": "true",
                       "type": "link"]
        )
        Tracer.trackAddMemberLinkInviteCopyClick(source: viewModel.sourceScenes)
        Self.logger.info("copy link")
        if ContactPasteboard.writeToPasteboard(string: content, shouldImmunity: true) {
            let successTip = BundleI18n.LarkContact.Lark_AdminUpdate_Toast_MobileCopied
            UDToast.showTips(with: successTip, on: view)
        } else {
            UDToast.showFailure(with: BundleI18n.LarkContact.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: view)
        }
    }

    func refreshLink() {
        switch currentDisplayCardType {
        case .inviteLink:
            Tracer.trackAddMemberInviteRefreshClick(source: viewModel.sourceScenes, sourceTab: .link)
        case .qrCode:
            Tracer.trackAddMemberInviteRefreshClick(source: viewModel.sourceScenes, sourceTab: .qrcode)
        }
        Self.logger.info("refresh link")
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkContact.Lark_AdminUpdate_Toast_ConfirmResetMobile)
        alertController.setContent(
            text: BundleI18n.LarkContact.Lark_AdminUpdate_Toast_ResetDetailsMobile
        )
        alertController.addSecondaryButton(text: BundleI18n.LarkContact.Lark_Invitation_AddMembersRefreshDialogCancel, dismissCompletion: {
            Tracer.trackAddMemberInviteRefreshCancelClick(source: self.viewModel.sourceScenes)
        })
        alertController.addDestructiveButton(text: BundleI18n.LarkContact.Lark_AdminUpdate_Button_ResetMobile, dismissCompletion: {
            Tracer.trackAddMemberInviteRefreshConfirmClick(source: self.viewModel.sourceScenes)
            self.setRefreshing(true)
            self.fetchInviteLinkInfo(forceRefresh: true)
        })
        navigator.present(alertController, from: self)
    }

    func handleShareError(result: ShareResult, itemType: LarkShareItemType) {
        var sourceType = ""
        switch currentDisplayCardType {
        case .qrCode:
            sourceType = "qrcode"
        case .inviteLink:
            sourceType = "link"
        }
        if case .failure(let errorCode, let debugMsg) = result {
            InviteMonitor.post(
                name: Homeric.UG_INVITE_MEMBER_NONDIRECTIONAL_SHARE,
                category: ["succeed": "false",
                           "type": sourceType,
                           "item": String.desc(with: itemType),
                           "error_code": errorCode.rawValue],
                extra: ["error_msg": debugMsg]
            )
            switch errorCode {
            case .notInstalled, .saveImageFailed:
                if let window = self.view.window {
                    UDToast.showTipsOnScreenCenter(with: debugMsg, on: window)
                }
            default:
                Self.logger.info("handleShareError.default",
                                  additionalData: ["errorCode": String(describing: debugMsg),
                                                   "errorMsg": String(describing: debugMsg)])
            }
        }
    }

    func setRefreshing(_ toRefresh: Bool) {
        linkCard.setRefreshing(toRefresh)
        qrcodeCard.setRefreshing(toRefresh)
    }

    func bindWithModel(_ info: InviteAggregationInfo) {
        linkCard.bindWithModel(cardInfo: info)
        qrcodeCard.bindWithModel(cardInfo: info)
    }
}

private extension MemberInviteNoDirectionalController {
    func layoutPageSubviews() {
        resetNavigationBar()
        view.backgroundColor = UIColor.ud.bgLogin
        view.addSubview(switchContainer)
        switchContainer.addSubview(qrcodeCardContainer)
        switchContainer.addSubview(linkCardContainer)
        qrcodeCardContainer.addSubview(qrcodeCard)
        linkCardContainer.addSubview(linkCard)
        switchContainer.addSubview(copyLinkButton)
        switchContainer.addSubview(shareLinkButton)
        switchContainer.addSubview(saveQRCodeButton)
        switchContainer.addSubview(shareQRCodeButton)

        switchContainer.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        qrcodeCardContainer.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalToSuperview()
            switch viewModel.displayPriority {
            case .qrCode:
                make.leading.equalToSuperview()
            case .inviteLink:
                make.leading.equalTo(linkCardContainer.snp.trailing)
                make.trailing.equalToSuperview()
            }
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        linkCardContainer.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalToSuperview()
            switch viewModel.displayPriority {
            case .qrCode:
                make.leading.equalTo(qrcodeCardContainer.snp.trailing)
                make.trailing.equalToSuperview()
            case .inviteLink:
                make.leading.equalToSuperview()
            }
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        qrcodeCard.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        linkCard.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        let bottomMargin = Display.iPhoneXSeries ? 60 : 16
        copyLinkButton.snp.makeConstraints { (make) in
            make.leading.equalTo(linkCardContainer).offset(16)
            make.trailing.equalTo(linkCardContainer.snp.centerX).offset(-8)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().inset(bottomMargin)
        }
        shareLinkButton.snp.makeConstraints { (make) in
            make.leading.equalTo(linkCardContainer.snp.centerX).offset(8)
            make.trailing.equalTo(linkCardContainer).inset(16)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().inset(bottomMargin)
        }
        saveQRCodeButton.snp.makeConstraints { (make) in
            make.leading.equalTo(qrcodeCardContainer).offset(16)
            make.trailing.equalTo(qrcodeCardContainer.snp.centerX).offset(-8)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().inset(bottomMargin)
        }
        shareQRCodeButton.snp.makeConstraints { (make) in
            make.leading.equalTo(qrcodeCardContainer.snp.centerX).offset(8)
            make.trailing.equalTo(qrcodeCardContainer).inset(16)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().inset(bottomMargin)
        }
    }

    func resetNavigationBar() {
        switch currentDisplayCardType {
        case .qrCode:
            self.title = BundleI18n.LarkContact.Lark_Invitation_AddMembers_SubtitleTwo_AddMemberstoJoin_TeamQRCode
            let toLinkItem = LKBarButtonItem(image: Resources.switch_to_link_for_member)
            toLinkItem.button.addTarget(self, action: #selector(switchToAnother), for: .touchUpInside)
            navigationItem.rightBarButtonItem = toLinkItem
        case .inviteLink:
            self.title = BundleI18n.LarkContact.Lark_Invitation_AddMembers_SubtitleTwo_AddMemberstoJoin_TeamLink
            let toQrcodeItem = LKBarButtonItem(image: Resources.switch_to_qrcode_for_member)
            toQrcodeItem.button.addTarget(self, action: #selector(switchToAnother), for: .touchUpInside)
            navigationItem.rightBarButtonItem = toQrcodeItem
        }
    }

    func buzTrackWhenAppear() {
        switch viewModel.displayPriority {
        case .inviteLink:
            Tracer.trackAddMemberLinkInviteShow(source: viewModel.sourceScenes)
        case .qrCode:
            Tracer.trackAddMemberQrcodeInviteShow(source: viewModel.sourceScenes)
        }
    }

    func buzTrackWhenDisappear() {
        backCallback = { [weak self] in
            guard let `self` = self else { return }
            Tracer.trackAddMemberLinkQrcodeInviteGoBackClick(source: self.viewModel.sourceScenes)
        }
        closeCallback = { [weak self] in
            guard let `self` = self else { return }
            Tracer.trackAddMemberLinkQrcodeInviteGoBackClick(source: self.viewModel.sourceScenes)
        }
    }

    func downloadRendedImageIfNeeded(completion: @escaping (UIImage) -> Void) {
        let startTimeInterval = CACurrentMediaTime()
        monitor.startEvent(
            name: Homeric.UG_INVITE_MEMBER_NONDIR_GET_SAVE_OR_SHARE_QR,
            indentify: String(startTimeInterval),
            reciableEvent: .memberOrientationSaveOrShareQr
        )
        exportDisposable = super.downloadRendedImageIfNeeded()
            .subscribe(onNext: { [weak self] (outputLayer) in
                self?.monitor.endEvent(
                    name: Homeric.UG_INVITE_MEMBER_NONDIR_GET_SAVE_OR_SHARE_QR,
                    indentify: String(startTimeInterval),
                    category: ["succeed": "true"],
                    reciableState: .success,
                    reciableEvent: .memberOrientationSaveOrShareQr
                )
                Self.logger.info("save qrcode image")
                completion(outputLayer)
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                if let error = error as? DynamicResourceExportError {
                    var errMsg = "unknown"
                    switch error {
                    case .pullDynamicResourceFailed(let logMsg, let userMsg):
                        Self.logger.warn(logMsg)
                        errMsg = logMsg
                        UDToast.showFailure(with: userMsg, on: self.view)
                    case .downloadFailed(let logMsg):
                        errMsg = logMsg
                        Self.logger.warn(logMsg)
                    case .constraintsError(let logMsg):
                        errMsg = logMsg
                        Self.logger.warn(logMsg)
                    case .bytesParseFailed(let logMsg):
                        errMsg = logMsg
                        Self.logger.warn(logMsg)
                    case .graphContextError(let logMsg):
                        errMsg = logMsg
                        Self.logger.warn(logMsg)
                    case .unknownError(let logMsg):
                        errMsg = logMsg
                        Self.logger.warn(logMsg)
                    }
                    self.monitor.endEvent(
                        name: Homeric.UG_INVITE_MEMBER_NONDIR_GET_SAVE_OR_SHARE_QR,
                        indentify: String(startTimeInterval),
                        category: ["succeed": "false",
                                   "error_code": "biz_error_code"],
                        extra: ["error_msg": errMsg],
                        reciableState: .failed,
                        reciableEvent: .memberOrientationSaveOrShareQr
                    )
                }
            })
    }
}

extension UDComponentsExtension where BaseType == UIColor {
    static var bgLogin: UIColor {
        return UIColor.ud.N00 & UIColor.ud.N00
    }
}

extension MemberInviteNoDirectionalController {
    struct Icon {
        public static let rightBoldOutlined = UDIcon.getIconByKey(.rightBoldOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
    }
}
