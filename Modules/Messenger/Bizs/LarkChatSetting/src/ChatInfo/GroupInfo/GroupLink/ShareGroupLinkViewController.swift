//
//  ShareGroupLinkViewController.swift
//  LarkChatSetting
//
//  Created by 姜凯文 on 2020/4/20.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import LKCommonsLogging
import LarkModel
import RxSwift
import LarkSegmentedView
import LarkMessengerInterface
import LarkSDKInterface
import UniverseDesignToast
import UniverseDesignColor
import EENavigator
import LarkSnsShare
import LarkShareToken
import LarkContainer
import LarkFeatureGating
import LarkEMM
import LarkSensitivityControl
import UniverseDesignButton

final class ShareGroupLinkViewController: BaseSettingController, ShareGroupLinkController, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    private static let logger = Logger.log(ShareGroupLinkViewController.self, category: "Module.IM.ChatInfo.ShareGroupLink")

    private let disposeBag: DisposeBag = DisposeBag()

    private lazy var scrollView = UIScrollView()
    private let groupLinkView = ShareGroupLinkView()

    private let copyButton = UDButton(.secondaryBlue.type(.custom(from: .big, inset: 6)))
    private let shareButton = UDButton(.primaryBlue.type(.custom(from: .big, inset: 6)))
    private lazy var buttonGroup: UDButtonGroupView = {
        var config = UDButtonGroupView.Configuration()
        config.layoutStyle = .adaptive
        config.buttonHeight = 48
        return UDButtonGroupView(configuration: config)
    }()

    private let viewModel: ShareGroupLinkViewModel

    @ScopedInjectedLazy private var snsShareService: LarkShareService?

    /// 新 通用分享面板 - 链接
    private var linkSharePanel: LarkSharePanel?
    /// 新通用分享面板FG
    private lazy var newSharePanelFGEnabled: Bool = userResolver.fg.staticFeatureGatingValue(with: "app.share.panel")

    var inputNavigationItem: UINavigationItem?
    private var isChangeExpireTime = false

    init(resolver: UserResolver, viewModel: ShareGroupLinkViewModel) {
        self.viewModel = viewModel
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.ud.bgBase

        setupSubviews()
        setupGroupLinkView()
        setButtonEnable(false)
        setupButtonStyle()
        setupButtonEvent()

        loadLinkString()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NewChatSettingTracker.imChatSettingChatLinkPageView(chatId: viewModel.chatId, isAdmin: viewModel.isOwner, chat: viewModel.chat)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(groupLinkView)
        view.addSubview(buttonGroup)

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(buttonGroup.snp.top).offset(-20)
        }
        groupLinkView.snp.makeConstraints { make in
            make.top.bottom.left.right.equalTo(scrollView.contentLayoutGuide)
            make.width.equalToSuperview()
        }
        buttonGroup.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-24)
        }
    }

    private func setupGroupLinkView() {
        groupLinkView.setup(
            with: viewModel.avatarKey,
            entityId: viewModel.entityId,
            name: viewModel.name,
            tenantName: viewModel.tenantName,
            ownership: viewModel.ownership
        )
        groupLinkView.hud = UDToast.showLoading(on: self.view, disableUserInteraction: true)
        groupLinkView.onRetry = { [weak self] in self?.loadLinkString() }
        groupLinkView.setExpireTime = { [weak self] in
            guard let self = self else { return }
            let vc = UpdateShareExpireTimeController(defaultSelected: self.viewModel.expireTime,
                                                     supported: [.sevenDays, .oneYear, .forever]) { [weak self] time in
                guard let self = self, self.viewModel.expireTime != time else { return }
                self.viewModel.expireTime = time
                self.isChangeExpireTime = true
                self.loadLinkString()
            }
            self.userResolver.navigator.push(vc, from: self)
        }
    }

    private func setupButtonStyle() {
        copyButton.setTitle(BundleI18n.LarkChatSetting.Lark_Chat_Copy, for: .normal)
        shareButton.setTitle(BundleI18n.LarkChatSetting.Lark_Chat_TopicToolShare, for: .normal)
        buttonGroup.addButton(copyButton, priority: .default)
        buttonGroup.addButton(shareButton, priority: .highest)
    }

    private func setButtonEnable(_ isEnable: Bool) {
        let alpha: CGFloat = isEnable ? 1 : 0.6
        copyButton.isEnabled = isEnable
        shareButton.isEnabled = isEnable

        copyButton.alpha = alpha
        shareButton.alpha = alpha
    }

    func loadLinkString() {
        groupLinkView.hud = UDToast.showLoading(on: self.view, disableUserInteraction: true)
        viewModel.loadGroupLinkString()
            .timeout(.seconds(3), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] (string, expire) in
                    guard let self = self else { return }
                    self.groupLinkView.setupLinkInfo(string, expire)
                    ShareTokenManager.shared.cachePasteboardContent(string: string)
                    self.setButtonEnable(true)
                    self.groupLinkView.updateContentView(false)
                }, onError: { [weak self] (error) in
                    self?.setButtonEnable(false)
                    self?.groupLinkView.updateContentView(true)
                    ShareGroupLinkViewController.logger.error("load Group link error", error: error)
                })
            .disposed(by: disposeBag)
    }

    private func setupButtonEvent() {
        copyButton.rx.tap.asDriver().drive(onNext: { [weak self] (_) in
            self?.saveLink()
        }).disposed(by: disposeBag)

        shareButton.rx.tap.asDriver().drive(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.shareLink()
        }).disposed(by: disposeBag)
    }

    private func saveLink() {
        var config = PasteboardConfig(token: Token("LARK-PSDA-pasteboard_grouplink_copy"))
        config.shouldImmunity = true
        do {
            try SCPasteboard.generalUnsafe(config).string = self.viewModel.groupLinkText
            ChatSettingTracker.trackChatLinkCreate(
                isFromChatShare: viewModel.isFromChatShare,
                isFromShareLink: false,
                isExternal: viewModel.isExternal,
                isPublic: viewModel.isPublic
            )
            NewChatSettingTracker.imChatSettingChatLinkCopyClick(chatId: viewModel.chatId,
                                                                 isAdmin: viewModel.isOwner,
                                                                 isChange: self.isChangeExpireTime,
                                                                 time: viewModel.expireTime,
                                                                 chat: viewModel.chat)
            UDToast.showSuccess(with: BundleI18n.LarkChatSetting.Lark_Legacy_CopySuccess, on: view)
        } catch {

            UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: view)
        }
    }

    private func shareLink() {
        ChatSettingTracker.trackChatLinkCreate(
            isFromChatShare: viewModel.isFromChatShare,
            isFromShareLink: true,
            isExternal: viewModel.isExternal,
            isPublic: viewModel.isPublic
        )
        NewChatSettingTracker.imChatSettingChatLinkShareClick(chatId: viewModel.chatId,
                                                              isAdmin: viewModel.isOwner,
                                                              isChange: self.isChangeExpireTime,
                                                              time: viewModel.expireTime,
                                                              chat: viewModel.chat)
        guard let linkText = self.viewModel.groupLinkText, let url = self.viewModel.shareLink else { return }
        let textContentInLark = TextContentInLark(text: linkText, sendHandler: { [weak self] (_, _) in
            guard let `self` = self else { return }
            ChatSettingTracker.trackChatLinkShareChannel(
                type: .custom(CustomShareContext.default()),
                isExternal: self.viewModel.isExternal,
                isPublic: self.viewModel.isPublic
            )
        })
        let inappShareContext = viewModel.inAppShareService.genInAppShareContext(content: .text(content: textContentInLark))
        let webpagePrepare = WebUrlPrepare(
            title: BundleI18n.LarkChatSetting.Lark_UserGrowth_InvitePeopleContactsShareLinkTitle(),
            webpageURL: url
        )
        let shareContentContext = ShareContentContext.webUrl(webpagePrepare)
        let downgradePanelMeterial = DowngradeTipPanelMaterial.text(
            panelTitle: BundleI18n.LarkChatSetting.Lark_Chat_GroupShareTitle,
            content: linkText
        )
        let popoverMaterial = PopoverMaterial(
            sourceView: shareButton,
            sourceRect: CGRect(x: shareButton.frame.width / 2, y: -10, width: 30, height: 30),
            direction: .down
        )

        /// 新通用分享面板 FG
        if self.newSharePanelFGEnabled {
            self.linkSharePanel = LarkSharePanel(userResolver: userResolver,
                                                 by: "lark.chatsetting.group.link",
                                                 shareContent: shareContentContext,
                                                 on: self,
                                                 popoverMaterial: popoverMaterial,
                                                 productLevel: "App",
                                                 scene: "Group_Link",
                                                 pasteConfig: .scPasteImmunity)
            self.linkSharePanel?.downgradeTipPanel = downgradePanelMeterial
            self.linkSharePanel?.customShareContextMapping = ["inapp": inappShareContext]
            self.linkSharePanel?.show { [weak self] (result, type) in
                guard let self = self else { return }
                ChatSettingTracker.trackChatLinkShareChannel(
                    type: type,
                    isExternal: self.viewModel.isExternal,
                    isPublic: self.viewModel.isPublic
                )
                if result.isSuccess() {
                    if type == .copy {
                        UDToast.showSuccess(with: BundleI18n.LarkChatSetting.Lark_Legacy_CopySuccess, on: self.view)
                    }
                } else {
                    self.handleShareError(
                        result: result,
                        itemType: type
                    )
                }
                let logMsg = "group share link \(result.isSuccess() ? "success" : "failed") by \(type)"
                ShareGroupLinkViewController.logger.info(logMsg)
            }
        } else {
            snsShareService?.present(
                by: "lark.chatsetting.group.link",
                contentContext: shareContentContext,
                baseViewController: self,
                downgradeTipPanelMaterial: downgradePanelMeterial,
                customShareContextMapping: ["inapp": inappShareContext],
                defaultItemTypes: [],
                popoverMaterial: popoverMaterial,
                pasteConfig: .scPasteImmunity) { [weak self] (result, type) in
                guard let `self` = self else { return }
                ChatSettingTracker.trackChatLinkShareChannel(
                    type: type,
                    isExternal: self.viewModel.isExternal,
                    isPublic: self.viewModel.isPublic
                )
                if result.isSuccess() {
                    if type == .copy {
                        UDToast.showSuccess(with: BundleI18n.LarkChatSetting.Lark_Legacy_CopySuccess, on: self.view)
                    }
                } else {
                    self.handleShareError(
                        result: result,
                        itemType: type
                    )
                }
                let logMsg = "group share link \(result.isSuccess() ? "success" : "failed") by \(type)"
                ShareGroupLinkViewController.logger.info(logMsg)
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
                ShareGroupLinkViewController.logger.info("errorCode >>> \(String(describing: errorCode)), errorMsg >>> \(String(describing: debugMsg))")
            }
        }
    }

    // MARK: JXSegmentedListContainerViewListDelegate
    func listView() -> UIView {
        return view
    }
}
