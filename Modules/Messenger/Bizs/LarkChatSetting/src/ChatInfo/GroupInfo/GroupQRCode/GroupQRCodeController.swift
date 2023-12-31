//
//  GroupQRCodeController.swift
//  LarkChat
//
//  Created by K3 on 2018/9/16.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import LarkFoundation
import RxSwift
import RxCocoa
import LarkCore
import LKCommonsLogging
import UniverseDesignToast
import LarkMessengerInterface
import LarkModel
import LarkSDKInterface
import LarkFeatureGating
import EENavigator
import LarkSnsShare
import LarkContainer
import LarkSetting
import UniverseDesignButton

class GroupQRCodeController: BaseSettingController, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    private static let logger = Logger.log(GroupQRCodeController.self, category: "Module.IM.ChatInfo.GroupQRCode")
    private let disposeBag: DisposeBag = DisposeBag()
    private lazy var scrollView = UIScrollView()
    private let qrCodeView: GroupQRCodeView
    private let saveButton: UIButton
    private let shareButton: UIButton

    private lazy var buttonGroup: UDButtonGroupView = {
        var config = UDButtonGroupView.Configuration()
        config.layoutStyle = .adaptive
        config.buttonHeight = 48
        return UDButtonGroupView(configuration: config)
    }()

    private let viewModel: GroupQRCodeViewModel
    private var tips: String = ""
    private let isPopOver: Bool

    @ScopedInjectedLazy private var snsShareService: LarkShareService?
    /// 新 通用分享面板 - 二维码
    private var qrCodeSharePanel: LarkSharePanel?
    /// 新通用分享面板FG
    private lazy var newSharePanelFGEnabled: Bool = userResolver.fg.staticFeatureGatingValue(with: "app.share.panel")
    /// 转发群二维码一级预览FG开关
    private lazy var forwardDialogContentFG: Bool = userResolver.fg.staticFeatureGatingValue(with: "core.forward.dialog_content_new")
    private var isChangeExpireTime = false

    init(resolver: UserResolver, viewModel: GroupQRCodeViewModel, isPopOver: Bool) {
        self.userResolver = resolver
        self.isPopOver = isPopOver
        qrCodeView = GroupQRCodeView(isPopOver: isPopOver)

        saveButton = UDButton(.secondaryBlue.type(.custom(from: .big, inset: 6)))
        shareButton = UDButton(.primaryBlue.type(.custom(from: .big, inset: 6)))

        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.ud.bgBase
        let title = viewModel.isThread ?
            BundleI18n.LarkChatSetting.Lark_Groups_GroupInfoGroupQrCode :
            BundleI18n.LarkChatSetting.Lark_Legacy_GroupInfoGroupQrCode
        self.titleString = title

        NewChatSettingTracker.imGroupQRView(chat: self.viewModel.chat)

        setupSubviews()
        setupQRCodeView()
        setButtonEnable(false)
        setupButtonStyle()
        setupButtonEvent()

        loadQRCodeString()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if viewModel.isFromShare {
            NewChatSettingTracker.imChatSettingQrcodePageView(chatId: viewModel.chatID,
                                                              isAdmin: viewModel.isOwner,
                                                              source: .shareIcon,
                                                              chat: self.viewModel.chat)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func shareQRImage() {
        ChatSettingTracker.shareGroupQRCodeImage()

        qrCodeView.setupTips(tips, false)
        let screenShotView = qrCodeView.prepareScreenShot(enabled: true)
        defer {
            qrCodeView.setupTips(tips, true)
            qrCodeView.prepareScreenShot(enabled: false)
        }
        guard let image = screenShotView.lu.screenshot() else {
            return
        }
        shareGroupQRCodeImage(image)
    }
}

extension GroupQRCodeController {
    private func shareGroupQRCodeImage(_ image: UIImage) {
        let chat = viewModel.chat
        let name = viewModel.name
        let shareType: ShareImageType = forwardDialogContentFG ? .forwardPreview : .normal
        ShareGroupQRCodeViewController.logger.info("shareGroupQRCode type \(shareType)")
        let imageContentInLark = ImageContentInLark(name: name ?? "", image: image, type: shareType, needFilterExternal: false, cancelCallBack: nil, successCallBack: { [weak self] in
            guard let `self` = self else { return }
            ChatSettingTracker.chatQRcodeShareChannel(
                type: .custom(CustomShareContext.default()),
                isExternal: self.viewModel.isExternal,
                isPublic: self.viewModel.isPublic,
                chat: chat
            )
        })
        NewChatSettingTracker.imChatSettingQrcodeShareClick(chatId: chat.id,
                                                            isChange: self.isChangeExpireTime,
                                                            isAdmin: viewModel.isOwner,
                                                            time: viewModel.expireTime,
                                                            chat: chat)
        let inappShareContext = viewModel.inAppShareService.genInAppShareContext(content: .image(content: imageContentInLark))
        // 群设置二维码 群分享二维码 外部群加人二维码走外部分享
        let imagePrepare = ImagePrepare(
            title: BundleI18n.LarkChatSetting.Lark_UserGrowth_InvitePeopleContactsShareLinkTitle(),
            image: image
        )
        let shareContentContext = ShareContentContext.image(imagePrepare)
        let downgradePanelMeterial = DowngradeTipPanelMaterial.image(panelTitle: nil)
        let popoverMaterial = PopoverMaterial(
            sourceView: shareButton,
            sourceRect: CGRect(x: shareButton.frame.width / 2, y: -10, width: 30, height: 30),
            direction: .down
        )
        NewChatSettingTracker.imGroupQRLinkShareToView(chat: chat)

        /// 新通用分享面板 FG
        if self.newSharePanelFGEnabled {
            self.qrCodeSharePanel = LarkSharePanel(userResolver: userResolver,
                                                   by: "lark.chatsetting.group.qrcode",
                                                   shareContent: shareContentContext,
                                                   on: self,
                                                   popoverMaterial: popoverMaterial,
                                                   productLevel: "App",
                                                   scene: "Group_QRCode")
            self.qrCodeSharePanel?.downgradeTipPanel = downgradePanelMeterial
            self.qrCodeSharePanel?.customShareContextMapping = ["inapp": inappShareContext]
            self.qrCodeSharePanel?.show { [weak self] (result, type) in
                guard let self = self else { return }
                ChatSettingTracker.chatQRcodeShareChannel(
                    type: type,
                    isExternal: self.viewModel.isExternal,
                    isPublic: self.viewModel.isPublic,
                    chat: self.viewModel.chat
                )
                if result.isFailure() {
                    self.handleShareError(result: result, itemType: type)
                }
                let logMsg = "group share QRCodeImage \(result.isSuccess() ? "success" : "failed") by \(type)"
                ShareGroupQRCodeViewController.logger.info(logMsg)
            }
        } else {
            snsShareService?.present(by: "lark.chatsetting.group.qrcode",
                                    contentContext: shareContentContext,
                                    baseViewController: self,
                                    downgradeTipPanelMaterial: downgradePanelMeterial,
                                    customShareContextMapping: ["inapp": inappShareContext],
                                    defaultItemTypes: [],
                                    popoverMaterial: popoverMaterial) { [weak self] (result, type) in
                guard let `self` = self else { return }
                ChatSettingTracker.chatQRcodeShareChannel(type: type,
                                                          isExternal: self.viewModel.isExternal,
                                                          isPublic: self.viewModel.isPublic,
                                                          chat: self.viewModel.chat)
                if result.isFailure() {
                    self.handleShareError(result: result, itemType: type)
                }
                let logMsg = "group share QRCodeImage \(result.isSuccess() ? "success" : "failed") by \(type)"
                ShareGroupQRCodeViewController.logger.info(logMsg)
            }
        }
    }

    private func handleShareError(
        result: ShareResult,
        itemType: LarkShareItemType
    ) {
        if case .failure(let errorCode, let debugMsg) = result {
            switch errorCode {
            case .notInstalled:
                UDToast.showTipsOnScreenCenter(with: debugMsg, on: view)
            default:
                GroupQRCodeController.logger.info("errorCode >>> \(String(describing: errorCode)), errorMsg >>> \(String(describing: debugMsg))")
            }
        }
    }

    private func setupSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(qrCodeView)
        view.addSubview(buttonGroup)

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(buttonGroup.snp.top).offset(-20)
        }
        qrCodeView.snp.makeConstraints { make in
            make.top.bottom.left.right.equalTo(scrollView.contentLayoutGuide)
            make.width.equalToSuperview()
        }
        buttonGroup.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-24)
        }
    }

    private func setupQRCodeView() {
        qrCodeView.setup(
            with: viewModel.avatarKey,
            entityId: viewModel.chatID,
            name: viewModel.name,
            tenantName: viewModel.tenantName,
            ownership: viewModel.ownership
        )

        qrCodeView.onRetry = { [weak self] in self?.loadQRCodeString() }
        qrCodeView.setExpireTime = { [weak self] in
            guard let self = self else { return }
            let vc = UpdateShareExpireTimeController(defaultSelected: self.viewModel.expireTime,
                                                     supported: [.sevenDays, .oneYear, .forever]) { [weak self] time in
                guard let self = self, self.viewModel.expireTime != time else { return }
                self.viewModel.expireTime = time
                self.isChangeExpireTime = true
                self.loadQRCodeString()
            }
            self.userResolver.navigator.push(vc, from: self)
        }
        qrCodeView.hud = UDToast.showLoading(on: self.view, disableUserInteraction: true)
    }

    func loadQRCodeString() {
        qrCodeView.hud = UDToast.showLoading(on: self.view, disableUserInteraction: true)
        viewModel.loadQRCodeURLString()
            .timeout(.seconds(3), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] (string, expire) in
                    guard let self = self else { return }
                    self.tips = expire
                    self.qrCodeView.setupQRCodeInfo(string, expire)
                    self.setButtonEnable(true)
                    self.qrCodeView.updateContentView(false)
                }, onError: { [weak self] (error) in
                    self?.setButtonEnable(false)
                    self?.qrCodeView.updateContentView(true)
                    GroupQRCodeController.logger.error("load Group qrcode error", error: error)
                })
            .disposed(by: disposeBag)
    }

    private func setupButtonStyle() {
        saveButton.setTitle(BundleI18n.LarkChatSetting.Lark_Contact_ShareQRCodeSaveImage_Button, for: .normal)
        shareButton.setTitle(BundleI18n.LarkChatSetting.Lark_Legacy_QrCodeShare, for: .normal)
        buttonGroup.addButton(saveButton, priority: .default)
        buttonGroup.addButton(shareButton, priority: .highest)
    }

    private func setButtonEnable(_ isEnable: Bool) {
        let alpha: CGFloat = isEnable ? 1 : 0.6
        saveButton.isEnabled = isEnable
        shareButton.isEnabled = isEnable

        saveButton.alpha = alpha
        shareButton.alpha = alpha
    }

    private func setupButtonEvent() {
        saveButton.rx.tap.asDriver().drive(onNext: { [weak self] (_) in
            self?.saveQRImage()
        }).disposed(by: disposeBag)

        shareButton.rx.tap.asDriver().drive(onNext: { [weak self] (_) in
            guard let self = self else { return }
            ChatSettingTracker.trackQrcodeShareConfirmed(
                isExternal: self.viewModel.isExternal,
                isPublic: self.viewModel.isPublic,
                isFormQRcodeEntrance: self.viewModel.isFormQRcodeEntrance,
                isFromShare: self.viewModel.isFromShare
            )
            self.shareQRImage()
        }).disposed(by: disposeBag)
    }

    private func saveQRImage() {
        NewChatSettingTracker.imChatSettingQrcodeSaveClick(chatId: viewModel.chatID,
                                                           isChange: self.isChangeExpireTime,
                                                           isAdmin: viewModel.isOwner,
                                                           time: viewModel.expireTime,
                                                           chat: viewModel.chat)
        // 保存图片时需要隐藏「更改有效期」的入口，避免被一起截进图里
        qrCodeView.setupTips(tips, false)
        let screenShotView = qrCodeView.prepareScreenShot(enabled: true)
        defer {
            qrCodeView.setupTips(tips, true)
            qrCodeView.prepareScreenShot(enabled: false)
        }
        guard let image = screenShotView.lu.screenshot() else {
            return
        }
        try? Utils.savePhoto(token: ChatSettingToken.savePhoto.token, image: image) { [weak self] (success, granted) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch (granted, success) {
                case (false, _):
                    UDToast.showFailure(
                        with: BundleI18n.LarkChatSetting.Lark_Legacy_PhotoPermissionRequired,
                        on: self.view)
                case (true, true):
                    UDToast.showSuccess(
                        with: BundleI18n.LarkChatSetting.Lark_Legacy_QrCodeSaveToAlbum,
                        on: self.view)
                case (true, false):
                    UDToast.showFailure(
                        with: BundleI18n.LarkChatSetting.Lark_Legacy_ChatGroupInfoQrCodeSaveFail,
                        on: self.view)
                }
            }
        }
    }
}
