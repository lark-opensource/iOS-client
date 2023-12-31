//
//  ExternalContactsInvitationViewController.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/9/23.
//

import Foundation
import LarkUIKit
import SnapKit
import LarkMessengerInterface
import RxSwift
import RxCocoa
import UniverseDesignToast
import LKCommonsLogging
import EENavigator
import LKMetric
import LarkFeatureGating
import LarkFeatureSwitch
import RustPB
import QRCode
import AppReciableSDK
import LarkSDKInterface
import LarkContainer
import LarkSnsShare
import LarkFoundation
import Homeric
import LarkAppResources
import LarkAccountInterface
import UIKit
import ByteWebImage
import UniverseDesignDialog
import Reachability
import LarkEMM
import LarkSensitivityControl

protocol ExternalContactsInvitationRouter: ShareRouter {
    // 通过手机联系人邀请
    func pushAddFromContactsViewController(vc: BaseUIViewController, presenter: ContactImportPresenter, fromEntrance: ExternalInviteSourceEntrance)
    // 通过手机/邮箱邀请外部联系人
    func pushExternalContactsSearchViewController(vc: BaseUIViewController, inviteMsg: String, uniqueId: String, fromEntrance: ExternalInviteSourceEntrance)
    // 外部邀请帮助中心
    func pushHelpCenterForExternalInvite(vc: BaseUIViewController)
    // 隐私设置
    func pushPrivacySettingViewController(vc: BaseUIViewController, from: ExternalContactsInvitationScenes)
    // 扫码
    func pushQRCodeControllerr(vc: BaseUIViewController, fromEntrance: ExternalInviteSourceEntrance)
    // 面对面建群
    func pushFaceToFaceCreateGroupController(vc: BaseUIViewController)
    // 引导页
    func presentGuidePage(from: BaseUIViewController, fromEntrance: ExternalInviteSourceEntrance, completion: @escaping () -> Void)
}

// MARK: - 外部联系人邀请页
final class ExternalContactsInvitationViewController: BaseUIViewController, UnifiedNoDirectionalHeaderDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UserResolverWrapper {
    typealias ShareSource = MemberNoDirectionalDisplayPriority
    private typealias Self_ = ExternalContactsInvitationViewController
    private let viewModel: ExternalInvitationIndexViewModel
    private var inviteInfo: InviteAggregationInfo?
    private var contactImportPresenter: ContactImportPresenter?
    private let monitor = InviteMonitor()
    private var currentDisplayCardType: ShareSource
    private let disposeBag = DisposeBag()
    private var exportDisposable: Disposable?
    static private let logger = Logger.log(ExternalContactsInvitationViewController.self,
                                           category: "LarkContact.ExternalContactsInvitationViewController")
    private lazy var exporter: DynamicRenderingTemplateExporter = {
        var imageOptions = Contact_V1_ImageOptions()
        imageOptions.resolutionType = .highDefinition
        let configuration = TemplateConfiguration(
            bizScenario: .contactCard,
            imageOptions: imageOptions
        )
        return DynamicRenderingTemplateExporter(
            templateConfiguration: configuration,
            extraOverlayViews: [:],
            resolver: userResolver
        )
    }()
    private lazy var topOffset: CGFloat = {
        let offset = Display.iPhoneXSeries ? 88 : 64
        return CGFloat((viewModel.scenes == .myQRCode && !Display.pad) ? offset + (Display.iPhoneXSeries ? 64 : 24) : offset)
    }()
    private var outputLayerCache: UIImage?
    private var extraOverlayViews: [OverlayViewType: UIView]? {
        didSet {
            exporter.updateExtraOverlayViews(self.extraOverlayViews ?? [:])
        }
    }
    private lazy var popoverMaterial: PopoverMaterial = {
        let sourceView = self.inviteInfoHeader.shareSourceView
        return PopoverMaterial(
            sourceView: sourceView,
            sourceRect: CGRect(x: sourceView.frame.width / 2, y: -10, width: 30, height: 30),
            direction: .down
        )
    }()
    var userResolver: LarkContainer.UserResolver
    private let passportUserService: PassportUserService
    private lazy var currentUserId: String = {
        return self.userResolver.userID
    }()

    @ScopedInjectedLazy private var snsShareService: LarkShareService?
    /// 新 通用分享面板 - 二维码
    private var qrCodeSharePanel: LarkSharePanel?
    /// 新 通用分享面板 - 链接
    private var linkSharePanel: LarkSharePanel?
    /// 新通用分享面板FG
    private lazy var newSharePanelFGEnabled: Bool = userResolver.fg.staticFeatureGatingValue(with: "app.share.panel")

    private var personalQRCodeVC: PersonalQRCodeViewController
    private var personalLinkVC: PersonalLinkViewController
    private var showQRCode: Bool = true
    private lazy var linkBarItem: LKBarButtonItem = {
        let rBarItem = LKBarButtonItem(image: Resources.switch_to_link_for_personalInfo)
        rBarItem.button.addTarget(self, action: #selector(switchContent), for: .touchUpInside)
        return rBarItem
    }()
    private lazy var qrCodeBarItem: LKBarButtonItem = {
        let rBarItem = LKBarButtonItem(image: Resources.switch_to_qrcode_for_personalInfo)
        rBarItem.button.addTarget(self, action: #selector(switchContent), for: .touchUpInside)
        return rBarItem
    }()

    init(viewModel: ExternalInvitationIndexViewModel, resolver: UserResolver) throws {
        self.viewModel = viewModel
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        personalQRCodeVC = PersonalQRCodeViewController(viewModel: viewModel, resolver: resolver)
        personalLinkVC = PersonalLinkViewController(viewModel: viewModel, resolver: resolver)
        // 国内国外包均改为二维码优先，PM@张永昊，QA@李文静： https://bits.bytedance.net/meego/larksuite/issue/detail/2135863#detail
        self.currentDisplayCardType = .qrCode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutPageSubviews()
        fetchInviteLinkInfo()
        retryLoadingView.retryAction = { [unowned self] in
            self.fetchInviteLinkInfo()
        }
        if case .myQRCode = viewModel.scenes {
            Tracer.trackInvitePeopleExternalQrcodeShow(source: viewModel.fromEntrance.rawValue)
        }
        viewModel.addMeSettingPush
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (message) in
                self?.showPrivaryViewIfNeeded(canShareLink: message.addMeSetting)
            }).disposed(by: self.disposeBag)
        AppReciableTrack.addExternalContactPageFirstRenderCostTrack()

        personalQRCodeVC.saveQRCodeImage = { [weak self] in
            self?.saveQRCodeImage()
        }

        personalQRCodeVC.shareQRCodeImage = { [weak self] in
            self?.shareQRCode()
        }

        personalLinkVC.copyLinkAction = { [weak self] in
            self?.copyLink()
        }

        personalLinkVC.shareLinkAction = { [weak self] in
            self?.shareLink()
        }
    }

    func fetchInviteLinkInfo() {
        loadingPlaceholderView.isHidden = false
        var isShowing = false
        viewModel.fetchInviteContextFromLocal()
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (inviteContext) in
                guard let `self` = self else { return }
                let inviteInfo = inviteContext.inviteInfo
                self.inviteInfo = inviteInfo
                self.inviteInfoHeader.bindWithModel(cardInfo: inviteInfo)
                self.personalQRCodeVC.bindWithModel(cardInfo: inviteInfo)
                self.personalLinkVC.bindWithModel(cardInfo: inviteInfo)
                let canShareLink = inviteInfo.externalExtraInfo?.canShareLink ?? false
                self.showPrivaryViewIfNeeded(canShareLink: canShareLink)
                self.genConstantOverlayViews(by: inviteInfo)
                if inviteContext.needDisplayGuide {
                    self.viewModel.router?.presentGuidePage(
                        from: self,
                        fromEntrance: self.viewModel.fromEntrance) {
                            self.loadingPlaceholderView.isHidden = true
                            isShowing = true
                    }
                } else {
                    self.loadingPlaceholderView.isHidden = true
                    isShowing = true
                }
            }, onError: { (_) in
                isShowing = false
            }).disposed(by: disposeBag)
        viewModel.fetchInviteContextFromServer()
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (inviteContext) in
                guard let `self` = self else { return }
                let inviteInfo = inviteContext.inviteInfo
                self.inviteInfo = inviteInfo
                self.inviteInfoHeader.bindWithModel(cardInfo: inviteInfo)
                self.personalQRCodeVC.bindWithModel(cardInfo: inviteInfo)
                self.personalLinkVC.bindWithModel(cardInfo: inviteInfo)
                let canShareLink = inviteInfo.externalExtraInfo?.canShareLink ?? false
                self.showPrivaryViewIfNeeded(canShareLink: canShareLink)
                self.genConstantOverlayViews(by: inviteInfo)
                if inviteContext.needDisplayGuide {
                    self.viewModel.router?.presentGuidePage(
                        from: self,
                        fromEntrance: self.viewModel.fromEntrance) {
                        self.loadingPlaceholderView.isHidden = true
                    }
                } else {
                    self.loadingPlaceholderView.isHidden = true
                }
            }, onError: { [weak self] (_) in
                guard let `self` = self else { return }
                if !isShowing {
                    self.loadingPlaceholderView.isHidden = false
                    self.retryLoadingView.isHidden = false
                }
            }).disposed(by: disposeBag)
    }

    @objc
    private func routeToHelpPage() {
        Tracer.trackInvitePeopleHelpClick()
        viewModel.router?.pushHelpCenterForExternalInvite(vc: self)
    }

    private lazy var searchWrapper: SearchUITextFieldWrapperView = {
        let wrapper = SearchUITextFieldWrapperView()
        wrapper.backgroundColor = .clear
        wrapper.searchUITextField.placeholder = BundleI18n.LarkContact.Lark_NewContacts_ProfileSearchUsersPlaceholder
        wrapper.searchUITextField.delegate = self
        return wrapper
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .singleLine
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = headerView
        tableView.contentInset = UIEdgeInsets(top: topOffset, left: 0, bottom: 0, right: 0)
        tableView.separatorColor = UIColor.ud.N300
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.register(ExternalInviteCell.self, forCellReuseIdentifier: NSStringFromClass(ExternalInviteCell.self))
        return tableView
    }()

    private lazy var inviteInfoHeader: UnifiedNoDirectionalHeader = {
        /// It is not possible to use the environment to judge whether it is overseas or not,
        /// Because the application for sharing on all major platforms is bound to the Bundle ID.
        let view = UnifiedNoDirectionalHeader(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: CGFloat.leastNormalMagnitude),
                                              scenes: .external,
                                              delegate: self, resolver: self.userResolver)
        return view
    }()

    private lazy var headerView: UIView = {
        let header = UIView()
        header.backgroundColor = .clear
        if viewModel.scenes == .externalInvite {
            header.addSubview(self.searchWrapper)
            header.addSubview(self.inviteInfoHeader)
            self.searchWrapper.snp.remakeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalToSuperview().offset(8)
                make.height.equalTo(50)
            }
            self.inviteInfoHeader.snp.makeConstraints { (make) in
                make.top.equalTo(searchWrapper.snp.bottom).offset(8)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(inviteInfoHeader.headerHeight)
            }
        } else {
            header.addSubview(self.inviteInfoHeader)
            self.inviteInfoHeader.snp.makeConstraints { (make) in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(inviteInfoHeader.headerHeight)
            }
        }
        return header
    }()

    private lazy var privaryView: ExternalInvitePrivacyView = {
        let view = ExternalInvitePrivacyView { [weak self] in
            self?.goToPrvacySetting()
        }
        return view
    }()

    // MARK: - UnifiedNoDirectionalHeaderDelegate
    func whichCardDisplayFirst() -> MemberNoDirectionalDisplayPriority {
        return viewModel.isOversea ? .inviteLink : .qrCode
    }

    func shareQRCode() {
        downloadRendedImageIfNeeded { [weak self] (result) in
            guard let `self` = self, let inviteInfo = self.inviteInfo else { return }
            switch result {
            case .success(let image):
                Self_.logger.info("start share qrcode image")

                let imagePrepare = ImagePrepare(
                    title: BundleI18n.LarkContact.Lark_UserGrowth_InvitePeopleContactsShareLinkTitle(),
                    image: image
                )
                let shareContentContext = ShareContentContext.image(imagePrepare)
                let downgradePanelMeterial = DowngradeTipPanelMaterial.image(panelTitle: nil)

                let popoverMaterial: PopoverMaterial
                if self.viewModel.scenes == .myQRCode {
                    popoverMaterial = PopoverMaterial(sourceView: self.personalQRCodeVC.shareButton,
                                                      sourceRect: CGRect(x: self.personalQRCodeVC.shareButton.frame.width / 2, y: -10, width: 30, height: 30),
                                                      direction: .down)
                } else {
                    popoverMaterial = self.popoverMaterial
                }

                /// 新通用分享面板 FG
                if self.newSharePanelFGEnabled {
                    self.qrCodeSharePanel = LarkSharePanel(userResolver: self.userResolver,
                                                           by: "lark.invite.external.qrcode",
                                                           shareContent: shareContentContext,
                                                           on: self,
                                                           popoverMaterial: popoverMaterial,
                                                           productLevel: "App",
                                                           scene: "My_QRCode")
                    self.qrCodeSharePanel?.downgradeTipPanel = downgradePanelMeterial
                    self.qrCodeSharePanel?.show { [weak self] (result, type) in
                        guard let self = self else { return }
                        self.handleShareError(result: result, itemType: type)
                    }
                } else {
                    self.snsShareService?.present(
                        by: "lark.invite.external.qrcode",
                        contentContext: shareContentContext,
                        baseViewController: self,
                        downgradeTipPanelMaterial: downgradePanelMeterial,
                        customShareContextMapping: [:],
                        defaultItemTypes: [],
                        popoverMaterial: popoverMaterial) { [weak self] (result, type) in
                        guard let `self` = self else { return }
                        if result.isSuccess() {
                            if let channel = Tracer.ShareChannel.transform(with: type),
                               let uniqueId = inviteInfo.externalExtraInfo?.qrcodeInviteData.uniqueID {
                                Tracer.trackInvitePeopleExternalShareQrcode(
                                    method: channel.rawValue,
                                    source: self.viewModel.fromEntrance.rawValue
                                )
                                Tracer.trackInvitePeopleH5Share(
                                    method: .shareQrcode,
                                    channel: channel,
                                    uniqueId: uniqueId,
                                    type: .qrcode
                                )
                            }
                            InviteMonitor.post(
                                name: Homeric.UG_INVITE_EXTERNAL_NONDIRECTIONAL_SHARE,
                                category: ["succeed": "true",
                                           "type": "qrcode",
                                           "item": String.desc(with: type)]
                            )
                        } else {
                            self.handleShareError(result: result, itemType: type)
                        }
                        let logMsg = "external invite share QRCode \(result.isSuccess() ? "success" : "failed") by \(type)"
                        Self_.logger.info(logMsg)
                    }
                }
            case .failure(let error):
                if let rxError = error as? RxError, case .timeout = rxError { // 弱网条件
                    UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Legacy_NetworkErrorRetry, on: self.view)
                } else if let reachability = Reachability(), !reachability.isReachable { // 断网条件
                        UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Legacy_NetworkErrorRetry, on: self.view)
                } else { // other
                    UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Legacy_ShareFailed, on: self.view, error: error)
                }
            }
        }
    }

    func saveQRCodeImage() {
        downloadRendedImageIfNeeded { [weak self] (result) in
            guard let `self` = self else { return }
            switch result {
            case .success(let image):
                do {
                    let token = Token("LARK-PSDA-external_contacts_invitation_qrcode_save")
                    try AlbumEntry.UIImageWriteToSavedPhotosAlbum(forToken: token, image, self, #selector(self.savePhotoToAlbum(image:didFinishSavingWithError:contextInfo:)), nil)
                } catch {
                    ContactLogger.shared.error(module: .action, event: "\(Self.self) no save image token: \(error.localizedDescription)")
                }
            case .failure(let error):
                if let rxError = error as? RxError, case .timeout = rxError { // 弱网条件
                    UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Legacy_NetworkErrorRetry, on: self.view)
                } else if let reachability = Reachability(), !reachability.isReachable { // 断网条件
                        UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Legacy_NetworkErrorRetry, on: self.view)
                } else { // other
                    UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Legacy_SaveFail, on: self.view, error: error)
                }
            }
        }
    }

    func shareLink() {
        if let inviteLinkMsg = inviteInfo?.externalExtraInfo?.linkInviteData.inviteMsg {
            Self_.logger.info("start share link")
            /// Because WeChat does not currently recognize non-newlined link-containing plain text,
            /// so you need to manually handle the line feed here.
            var finalLinkMsg = inviteLinkMsg
            if inviteLinkMsg.contains("http") {
                if let range = inviteLinkMsg.range(of: "http") {
                    finalLinkMsg.replaceSubrange(range, with: "\nhttp")
                }
            }

            let title = finalLinkMsg.components(separatedBy: "\n").first ??
                        BundleI18n.LarkContact.Lark_UserGrowth_InvitePeopleContactsShareLinkTitle()

            guard let url = finalLinkMsg.components(separatedBy: "\n").last else { return }
            let webpagePrepare = WebUrlPrepare(
                title: title,
                webpageURL: url
            )
            let shareContentContext = ShareContentContext.webUrl(webpagePrepare)
            let downgradePanelMeterial = DowngradeTipPanelMaterial.text(
                panelTitle: BundleI18n.LarkContact.Lark_Invitation_InviteViaWeChat_InviteLinkCopied_Title,
                content: inviteLinkMsg
            )
            let popoverMaterial: PopoverMaterial
            if self.viewModel.scenes == .myQRCode {
                popoverMaterial = PopoverMaterial(sourceView: self.personalLinkVC.shareButton,
                                                  sourceRect: CGRect(x: self.personalLinkVC.shareButton.frame.width / 2, y: -10, width: 30, height: 30),
                                                  direction: .down)
            } else {
                popoverMaterial = self.popoverMaterial
            }

            /// 新通用分享面板 FG
            if self.newSharePanelFGEnabled {
                self.linkSharePanel = LarkSharePanel(userResolver: userResolver,
                                                     by: "lark.invite.external.link",
                                                     shareContent: shareContentContext,
                                                     on: self,
                                                     popoverMaterial: popoverMaterial,
                                                     productLevel: "App",
                                                     scene: "My_Link",
                                                     pasteConfig: .scPasteImmunity)
                self.linkSharePanel?.downgradeTipPanel = downgradePanelMeterial
                self.linkSharePanel?.show { [weak self] (result, type) in
                    guard let self = self else { return }
                    if result.isSuccess() {
                        if case .copy = type {
                            self.copyLink()
                        }
                    } else {
                        self.handleShareError(result: result, itemType: type)
                    }
                    let logMsg = "external invite share InviteLink \(result.isSuccess() ? "success" : "failed") by \(type)"
                    Self_.logger.info(logMsg)
                }
            } else {
                snsShareService?.present(
                    by: "lark.invite.external.link",
                    contentContext: shareContentContext,
                    baseViewController: self,
                    downgradeTipPanelMaterial: downgradePanelMeterial,
                    customShareContextMapping: [:],
                    defaultItemTypes: [],
                    popoverMaterial: popoverMaterial,
                    pasteConfig: .scPasteImmunity) { [weak self] (result, type) in
                    guard let `self` = self else { return }
                    if let channel = Tracer.ShareChannel.transform(with: type),
                       let uniqueId = self.inviteInfo?.externalExtraInfo?.linkInviteData.uniqueID {
                        Tracer.trackInvitePeopleExternalShareLink(
                            method: channel.rawValue,
                            source: self.viewModel.fromEntrance.rawValue
                        )
                        Tracer.trackInvitePeopleH5Share(
                            method: .shareLink,
                            channel: channel,
                            uniqueId: uniqueId,
                            type: .link
                        )
                    }
                    if result.isSuccess() {
                        if case .copy = type {
                            self.copyLink()
                        }
                        InviteMonitor.post(
                            name: Homeric.UG_INVITE_EXTERNAL_NONDIRECTIONAL_SHARE,
                            category: ["succeed": "true",
                                       "type": "link",
                                       "item": String.desc(with: type)]
                        )
                    } else {
                        self.handleShareError(result: result, itemType: type)
                    }
                    let logMsg = "external invite share InviteLink \(result.isSuccess() ? "success" : "failed") by \(type)"
                    Self_.logger.info(logMsg)
                }
            }
        }
    }

    func copyLink() {
        guard let inviteLink = inviteInfo?.externalExtraInfo?.linkInviteData.inviteMsg else {
            return
        }
        Tracer.trackInvitePeopleExternalCopyLink(source: viewModel.fromEntrance.rawValue)
        if let uniqueId = inviteInfo?.externalExtraInfo?.linkInviteData.uniqueID {
            Tracer.trackInvitePeopleH5Share(
                method: .copyLink,
                channel: .none,
                uniqueId: uniqueId,
                type: .link
            )
        }
        InviteMonitor.post(name: Homeric.UG_INVITE_EXTERNAL_NONDIRECTIONAL_COPY)
        Self_.logger.info("copy link")
        if ContactPasteboard.writeToPasteboard(string: inviteLink, shouldImmunity: true) {
            let successTip = BundleI18n.LarkContact.Lark_Legacy_CopyReady
            UDToast.showTips(with: successTip, on: view)
        } else {
            UDToast.showFailure(with: BundleI18n.LarkContact.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: view)
        }
    }

    func goToPrvacySetting() {
        viewModel.router?.pushPrivacySettingViewController(vc: self, from: viewModel.scenes)
    }

    func switchToCard(targetCardState: CardSwitchState) {
        Self_.logger.info("switch to card <\(targetCardState.rawValue)>")
        switch targetCardState {
        case .qrCode:
            Tracer.trackInvitePeopleExternalSwitchtoQrcode(source: viewModel.fromEntrance.rawValue)
        case .inviteLink:
            Tracer.trackInvitePeopleExternalSwitchtoLink(source: viewModel.fromEntrance.rawValue)
        }
        currentDisplayCardType = targetCardState
    }

    @objc
    private func switchContent() {
        showQRCode = !showQRCode

        personalLinkVC.start3DRotateAnimation()
        personalQRCodeVC.start3DRotateAnimation()

        if let inviteInfo = inviteInfo {
            if showQRCode {
                personalQRCodeVC.bindWithModel(cardInfo: inviteInfo)
            } else {
                personalLinkVC.bindWithModel(cardInfo: inviteInfo)
            }
        }

        let duration = SwitchAnimatedView.switchAnimationDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2, execute: { [weak self] in
            guard let self = self else { return }
            self.personalLinkVC.view.isHidden = self.showQRCode
            self.personalQRCodeVC.view.isHidden = !self.showQRCode
        })

        navigationItem.rightBarButtonItem = showQRCode ? self.linkBarItem : self.qrCodeBarItem
        self.title = showQRCode ?
                     BundleI18n.LarkContact.Lark_NewContacts_AddExternalContacts_MyQRCodePage_title :
                     BundleI18n.LarkContact.Lark_Contact_ShareMyLink_Title
    }

    @objc
    private func savePhotoToAlbum(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        if error == nil {
            LKMetric.EN.saveQrCodePermissionSuccess()
            Self_.logger.info("save qrcode image success")
            InviteMonitor.post(
                name: Homeric.UG_INVITE_EXTERNAL_NONDIR_SAVE_QR_PERMISSON,
                category: ["succeed": "true"]
            )
            UDToast.showTips(with: BundleI18n.LarkContact.Lark_Legacy_QrCodeSaveAlbum, on: view)
        } else {
            LKMetric.EN.saveQrCodePermissionFailed(errorMsg: error?.localizedDescription ?? "")
            Self_.logger.info("savePhotoToAlbum failed, error >>> \(String(describing: error?.localizedDescription))")
            InviteMonitor.post(
                name: Homeric.UG_INVITE_EXTERNAL_NONDIR_SAVE_QR_PERMISSON,
                category: ["succeed": "false"]
            )

            let dialog = UDDialog.noPermissionDialog(title: BundleI18n.LarkContact.Lark_Core_PhotoAccessForSavePhoto,
                                                     detail: BundleI18n.LarkContact.Lark_Core_PhotoAccessForSavePhoto_Desc())
            navigator.present(dialog, from: self)
        }
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.tableSectionCount()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.tableRowsForSection()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(ExternalInviteCell.self))
        if let cell = cell as? ExternalInviteCell {
            cell.bind(with: viewModel.entrances[indexPath.row])
        }
        return cell ?? UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54.0
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard viewModel.scenes == .externalInvite else { return }
        let entrance = viewModel.entrances[indexPath.row]

        switch entrance.flag {
        case .createNearbyGroup:
            viewModel.router?.pushFaceToFaceCreateGroupController(vc: self)
        case .importFromAddressbook:
            guard let externalExtra = inviteInfo?.externalExtraInfo, let chatApplicationAPI = viewModel.chatApplicationAPI, let presenterRouter = viewModel.presenterRouter else {
                return
            }
            let presenter = ContactImportPresenter(
                isOversea: viewModel.isOversea,
                applicationAPI: chatApplicationAPI,
                router: presenterRouter,
                inviteMsg: externalExtra.linkInviteData.inviteMsg,
                uniqueId: externalExtra.linkInviteData.uniqueID,
                source: viewModel.fromEntrance,
                resolver: userResolver)
            contactImportPresenter = presenter
            viewModel.router?.pushAddFromContactsViewController(vc: self, presenter: presenter, fromEntrance: viewModel.fromEntrance)
        case .scan:
            Tracer.trackScan(source: "add_external_contact")
            Tracer.trackInvitePeopleExternalScanQRCodeClick(source: viewModel.fromEntrance.rawValue)
            viewModel.router?.pushQRCodeControllerr(vc: self, fromEntrance: viewModel.fromEntrance)
        }
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if let externalExtra = inviteInfo?.externalExtraInfo {
            viewModel.router?.pushExternalContactsSearchViewController(
                vc: self,
                inviteMsg: externalExtra.linkInviteData.inviteMsg,
                uniqueId: externalExtra.linkInviteData.uniqueID,
                fromEntrance: viewModel.fromEntrance
            )
        }
        return false
    }
}

// MARK: - Private Methods
private extension ExternalContactsInvitationViewController {
    func layoutPageSubviews() {
        view.backgroundColor = UIColor.ud.bgBase
        setupNavigationBar()
        switchSence()
    }

    func setupNavigationBar() {
        self.title = viewModel.title()
        if case .myQRCode = viewModel.scenes {
            navigationItem.rightBarButtonItem = self.linkBarItem
        } else if case .externalInvite = viewModel.scenes {
            let rBarItem = LKBarButtonItem(image: Resources.invite_help)
            rBarItem.button.addTarget(self, action: #selector(routeToHelpPage), for: .touchUpInside)
            navigationItem.rightBarButtonItem = rBarItem
        }
    }

    func switchSence() {
        tableView.contentInsetAdjustmentBehavior = .never
        view.addSubview(tableView)

        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tableView.tableHeaderView?.snp.makeConstraints({ (make) in
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            if viewModel.scenes == .externalInvite {
                make.height.equalTo(inviteInfoHeader.headerHeight + 100)
            } else {
                make.height.equalTo(inviteInfoHeader.headerHeight)
            }
        })
        tableView.tableHeaderView?.superview?.layoutIfNeeded()

        if case .myQRCode = viewModel.scenes {
            addChildController(personalQRCodeVC, parentView: view)
            personalQRCodeVC.view.isHidden = false
            addChildController(personalLinkVC, parentView: view)
            personalLinkVC.view.isHidden = !personalQRCodeVC.view.isHidden
        } else if case .externalInvite = viewModel.scenes {
            tableView.isHidden = false
        }
    }

    func showPrivaryViewIfNeeded(canShareLink: Bool) {
        if canShareLink {
            if privaryView.superview != nil {
                privaryView.removeFromSuperview()
            }
        } else {
            view.addSubview(privaryView)
            privaryView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
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
                name: Homeric.UG_INVITE_EXTERNAL_NONDIRECTIONAL_SHARE,
                category: ["succeed": "false",
                           "type": sourceType,
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
                Self_.logger.info("handleShareError.default",
                                  additionalData: ["errorCode": String(describing: debugMsg),
                                                   "errorMsg": String(describing: debugMsg)])
            }
        }
    }

    func downloadRendedImageIfNeeded(completion: @escaping (Result<UIImage, Error>) -> Void) {
        if let cache = outputLayerCache {
            completion(.success(cache))
            return
        }
        guard extraOverlayViews != nil else { return }
        exportDisposable?.dispose()

        let startTimeInterval = CACurrentMediaTime()
        monitor.startEvent(
            name: Homeric.UG_INVITE_EXTERNAL_NONDIR_GET_SAVE_OR_SHARE_QR,
            indentify: String(startTimeInterval),
            reciableEvent: .externalOrientationSaveOrShareQr
        )

        let hud = UDToast.showLoading(on: view)
        exportDisposable = exporter.export()
            .observeOn(MainScheduler.instance)
            .timeout(.seconds(10), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (outputLayer) in
                guard let `self` = self else { return }
                hud.remove()
                Tracer.trackInvitePeopleExternalSaveQRCode(source: self.viewModel.fromEntrance.rawValue)
                self.monitor.endEvent(
                    name: Homeric.UG_INVITE_EXTERNAL_NONDIR_GET_SAVE_OR_SHARE_QR,
                    indentify: String(startTimeInterval),
                    category: ["succeed": "true"],
                    reciableState: .success,
                    reciableEvent: .externalOrientationSaveOrShareQr
                )
                if let uniqueId = self.inviteInfo?.externalExtraInfo?.qrcodeInviteData.uniqueID {
                    Tracer.trackInvitePeopleH5Share(
                        method: .saveQrcode,
                        channel: .none,
                        uniqueId: uniqueId,
                        type: .qrcode
                    )
                }
                Self_.logger.info("save qrcode image")
                self.outputLayerCache = outputLayer
                completion(.success(outputLayer))
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                hud.remove()
                completion(.failure(error))
                if let error = error as? DynamicResourceExportError {
                    var errMsg = "unknown"
                    switch error {
                    case .pullDynamicResourceFailed(let logMsg, let userMsg):
                        Self_.logger.warn(logMsg)
                        errMsg = logMsg
                        UDToast.showFailure(with: userMsg, on: self.view)
                    case .downloadFailed(let logMsg):
                        errMsg = logMsg
                        Self_.logger.warn(logMsg)
                    case .constraintsError(let logMsg):
                        errMsg = logMsg
                        Self_.logger.warn(logMsg)
                    case .bytesParseFailed(let logMsg):
                        errMsg = logMsg
                        Self_.logger.warn(logMsg)
                    case .graphContextError(let logMsg):
                        errMsg = logMsg
                        Self_.logger.warn(logMsg)
                    case .unknownError(let logMsg):
                        errMsg = logMsg
                        Self_.logger.warn(logMsg)
                    }
                    self.monitor.endEvent(
                        name: Homeric.UG_INVITE_EXTERNAL_NONDIR_GET_SAVE_OR_SHARE_QR,
                        indentify: String(startTimeInterval),
                        category: ["succeed": "false",
                                   "error_code": "biz_error_code"],
                        extra: ["error_msg": errMsg],
                        reciableState: .failed,
                        reciableEvent: .externalOrientationSaveOrShareQr
                    )
                }
            })
    }

    func genConstantOverlayViews(by info: InviteAggregationInfo) {
        // 这里分享出去的卡片因为与设备宽度挂钩，故以设备屏幕宽度为基准进行布局
        let screenWidth = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let avatarContentSize = CGSize(width: screenWidth - 21 * 2, height: screenWidth - 21 * 2)
        let qrcodeContentSize = CGSize(width: screenWidth, height: screenWidth)
        let appIconSize = CGSize(width: 40, height: 40)

        // 头像
        let avatarView = UIImageView()
        avatarView.frame = CGRect(x: 0, y: 0, width: avatarContentSize.width, height: avatarContentSize.height)
        avatarView.contentMode = .scaleAspectFill
        /// 这里先读取小头像作为占位图，防止保存时出现空白区域
        avatarView.bt.setLarkImage(with: .avatar(key: info.avatarKey, entityID: currentUserId),
           trackStart: {
               return TrackInfo(scene: .Profile, fromType: .avatar)
           },
           completion: { [weak avatarView, weak self] _ in
            guard let `self` = self else { return }
            avatarView?.bt.setLarkImage(with: .avatar(key: info.avatarKey, entityID: self.currentUserId, params: .defaultBig),
                   trackStart: {
                    return TrackInfo(scene: .Profile, fromType: .avatar)
                })
        })

        // 二维码视图
        let qrcodeView = UIImageView()
        qrcodeView.frame = CGRect(x: 0, y: 0, width: qrcodeContentSize.width, height: qrcodeContentSize.height)
        qrcodeView.contentMode = .scaleAspectFill
        if let qrlinkGenUrl = info.externalExtraInfo?.qrcodeInviteData.inviteURL {
            qrcodeView.image = QRCodeTool.createQRImg(str: qrlinkGenUrl, size: qrcodeContentSize.width)
        }

        // appicon
        let appIconView = UIImageView()
        appIconView.frame = CGRect(x: 0, y: 0, width: appIconSize.width, height: appIconSize.height)
        appIconView.contentMode = .scaleAspectFill
        appIconView.image = AppResources.calendar_share_logo

        extraOverlayViews = [OverlayViewType.userAvatar: avatarView,
                             OverlayViewType.personalContactQr: qrcodeView,
                             OverlayViewType.appIcon: appIconView]
    }
}

extension BaseUIViewController {

    func addChildController(_ child: UIViewController, parentView: UIView) {
        self.addChild(child)
        parentView.addSubview(child.view)
        child.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        child.didMove(toParent: self) // 通知子视图控制器已经被加入到父视图控制器中
    }

    func removeSelfFromParent() {
        guard parent != nil else {
            return
        }
        willMove(toParent: nil) // 通知子视图控制器将要从父视图控制器中移除
        view.removeFromSuperview()
        self.removeFromParent()
    }
}
