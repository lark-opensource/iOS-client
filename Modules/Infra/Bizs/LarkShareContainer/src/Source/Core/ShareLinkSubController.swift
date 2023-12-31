//
//  ShareLinkSubController.swift
//  LarkShareContainer
//
//  Created by shizhengyu on 2020/12/21.
//

import UIKit
import Foundation
import LarkUIKit
import LarkSegmentedView
import LarkFoundation
import SnapKit
import LarkSnsShare
import RoundedHUD
import RxSwift
import LarkContainer
import LKCommonsLogging
import UniverseDesignColor
import LarkFeatureGating
import LarkEMM
import LarkSensitivityControl

final class ShareLinkSubController: BaseUIViewController, JXSegmentedListContainerViewListDelegate, UserResolverWrapper {
    let userResolver: UserResolver
    private let logger = Logger.log(ShareLinkSubController.self, category: "lark.share.container.link")
    private let circleAvatar: Bool
    private let contentProvider: (ShareTabType) -> Observable<TabContentMeterial>
    private var currentDisposable: Disposable?
    private var successMaterial: SuccessStatusMaterial.ViaLink?
    private let lifeCycleObserver: ((LifeCycleEvent, ShareTabType) -> Void)?
    private var hasheader: Bool = false
    private var hasContent: Bool = false
    @ScopedInjectedLazy private var snsShareService: LarkShareService?
    /// 新 通用分享面板 - 链接
    private var sharePanel: LarkSharePanel?
    /// 新通用分享面板FG
    private lazy var newSharePanelFGEnabled: Bool = userResolver.fg.staticFeatureGatingValue(with: "openplatform.share.panel")

    init(
        userResolver: UserResolver,
        circleAvatar: Bool,
        contentProvider: @escaping (ShareTabType) -> Observable<TabContentMeterial>,
        lifeCycleObserver: ((LifeCycleEvent, ShareTabType) -> Void)? = nil
    ) {
        self.userResolver = userResolver
        self.circleAvatar = circleAvatar
        self.contentProvider = contentProvider
        self.lifeCycleObserver = lifeCycleObserver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutPageSubviews()
        setButtonEnable(false)
        fetchMaterial()
    }

    private func fetchMaterial() {
        let hud = RoundedHUD.showLoading(on: view, disableUserInteraction: true)
        currentDisposable?.dispose()
        currentDisposable = contentProvider(.viaLink)
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (material) in
                switch material {
                case .preload(let commonInfo):
                    self?.linkCard.set(with: commonInfo)
                    self?.hasheader = true
                case .success(let successMaterial):
                    hud.remove()
                    self?.setButtonEnable(true)
                    guard case .viaLink(let info) = successMaterial else {
                        return
                    }
                    self?.hasContent = true
                    self?.successMaterial = info
                    let viewSuccessMaterial = SuccessViewMaterial(
                        link: info.content,
                        expireMsg: info.expiredTip,
                        tipMsg: info.tip
                    )
                    let viewMaterial = StatusViewMaterial.success(viewSuccessMaterial)

                    self?.linkCard.bind(with: viewMaterial)
                    self?.updateLayout()
                case .error(let errorMaterial):
                    hud.remove()
                    self?.setButtonEnable(false)
                    let viewErrorMaterial = ErrorViewMaterial(
                        errorImage: errorMaterial.errorTipImage,
                        errorTipMsg: errorMaterial.errorTipMsg ??
                            BundleI18n.LarkShareContainer.Lark_Chat_FailedToLoadChatLink
                    )
                    let viewMaterial = StatusViewMaterial.error(viewErrorMaterial)
                    self?.linkCard.bind(with: viewMaterial)
                case .disable(let disableMaterial):
                    hud.remove()
                    self?.setButtonEnable(false)
                    let viewDisableMaterial = DisableViewMaterial(
                        disableTipImage: disableMaterial.disableTipImage,
                        disableTipMsg: disableMaterial.disableTipMsg
                    )
                    let viewMaterial = StatusViewMaterial.disable(viewDisableMaterial)
                    self?.linkCard.bind(with: viewMaterial)
                case .none: break
                }
            }, onError: { (_) in
                hud.remove()
            }, onCompleted: { [weak self] in
                hud.remove()
                guard let self = self, !self.hasheader, self.hasContent else { return }
                //如成功但无header通用信息，则隐藏header并将content居中
                self.linkCard.hideHeaderView()
                self.linkCard.centreContentView()
            }, onDisposed: {
                hud.remove()
            })
    }

    @objc
    private func copyLink() {
        lifeCycleObserver?(.clickCopyForLink, .viaLink)
        guard let linkMaterial = successMaterial else {
            return
        }
        let config = PasteboardConfig(token: Token("LARK-PSDA-op_microApp_link_copy"), shouldImmunity: true)
        SCPasteboard.general(config).string = linkMaterial.content
        RoundedHUD.showSuccess(with: BundleI18n.LarkShareContainer.Lark_Legacy_CopySuccess, on: view)
        linkMaterial.copyCompletion?()
    }

    @objc
    private func shareLink() {
        lifeCycleObserver?(.clickShare, .viaLink)
        guard let linkMaterial = successMaterial else {
            return
        }
        let webpagePrepare = WebUrlPrepare(
            title: linkMaterial.thirdShareTitle,
            webpageURL: linkMaterial.link
        )
        let shareContentContext = ShareContentContext.webUrl(webpagePrepare)
        let downgradePanelMeterial = DowngradeTipPanelMaterial.text(
            panelTitle: nil,
            content: linkMaterial.content
        )
        let popoverMaterial = PopoverMaterial(
            sourceView: shareButton,
            sourceRect: CGRect(x: shareButton.frame.width / 2, y: -10, width: 30, height: 30),
            direction: .down
        )
        let inappShareContext = dependency!.inappShareContext(with: linkMaterial.content) { [weak self] shareResults in
            guard let self = self else { return }
            self.logger.info("about to call lifeCycleObserver callback: \(self.lifeCycleObserver), shareResult: \(shareResults)")
            shareResults?.forEach({ shareResult in
                if shareResult.1 {
                    self.lifeCycleObserver?(.shareSuccess, .viaLink)
                } else {
                    self.lifeCycleObserver?(.shareFailure, .viaLink)
                }
            })
        }

        /// 新通用分享面板 FG
        if self.newSharePanelFGEnabled {
            var scene = linkMaterial.thirdShareBizId.contains("app_page") ? "Apppage_Link" : "App_Link"
            self.sharePanel = LarkSharePanel(userResolver: userResolver,
                                             by: linkMaterial.thirdShareBizId,
                                             shareContent: shareContentContext,
                                             on: self,
                                             popoverMaterial: popoverMaterial,
                                             productLevel: "Openplatform",
                                             scene: scene,
                                             pasteConfig: .scPasteImmunity)
            self.sharePanel?.downgradeTipPanel = downgradePanelMeterial
            self.sharePanel?.customShareContextMapping = ["inapp": inappShareContext]
            self.sharePanel?.show { [weak self] (result, type) in
                guard let self = self else { return }
                if result.isSuccess() {
                    if type == .copy {
                        RoundedHUD.showSuccess(with: BundleI18n.LarkShareContainer.Lark_Legacy_CopySuccess, on: self.view)
                    }
                    self.lifeCycleObserver?(.shareSuccess, .viaLink)
                } else {
                    self.handleShareError(
                        result: result,
                        itemType: type
                    )
                    self.lifeCycleObserver?(.shareFailure, .viaLink)
                }
                let successDesc = result.isSuccess() ? "success" : "failed"
                let logMsg = "share link \(successDesc) by \(type) with bizId(\(linkMaterial.thirdShareBizId)"
                self.logger.info(logMsg)
                linkMaterial.shareCompletion?(result, type)
            }
        } else {
            snsShareService?.present(
                by: linkMaterial.thirdShareBizId,
                contentContext: shareContentContext,
                baseViewController: self,
                downgradeTipPanelMaterial: downgradePanelMeterial,
                customShareContextMapping: ["inapp": inappShareContext],
                defaultItemTypes: [],
                popoverMaterial: popoverMaterial,
                pasteConfig: .scPasteImmunity) { [weak self] (result, type) in
                guard let `self` = self else { return }

                if result.isSuccess() {
                    if type == .copy {
                        RoundedHUD.showSuccess(with: BundleI18n.LarkShareContainer.Lark_Legacy_CopySuccess, on: self.view)
                    }
                } else {
                    self.handleShareError(
                        result: result,
                        itemType: type
                    )
                }

                let successDesc = result.isSuccess() ? "success" : "failed"
                let logMsg = "share link \(successDesc) by \(type) with bizId(\(linkMaterial.thirdShareBizId)"
                self.logger.info(logMsg)

                linkMaterial.shareCompletion?(result, type)
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
                RoundedHUD.showTipsOnScreenCenter(with: debugMsg, on: view)
            default:
                logger.info("errorCode = \(String(describing: errorCode)), errorMsg = \(String(describing: debugMsg))")
            }
        }
    }

    private lazy var linkCard: LinkCardView = {
        let card = LinkCardView(circleAvatar: circleAvatar, retryHandler: { [weak self] in
            self?.fetchMaterial()
        })
        return card
    }()

    private lazy var copyButton: UIButton = {
        let button = UIButton(type: .custom)
        button.clipsToBounds = true
        button.layer.cornerRadius = 4
        button.backgroundColor = UIColor.ud.bgBase
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.setTitle(BundleI18n.LarkShareContainer.Lark_Chat_Copy, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.layer.borderWidth = 0.5
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        button.addTarget(self, action: #selector(copyLink), for: .touchUpInside)
        return button
    }()

    private lazy var shareButton: UIButton = {
        let button = UIButton(type: .custom)
        button.clipsToBounds = true
        button.layer.cornerRadius = 4
        button.backgroundColor = UIColor.ud.primaryContentDefault
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.setTitle(BundleI18n.LarkShareContainer.Lark_Legacy_QrCodeShare, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.addTarget(self, action: #selector(shareLink), for: .touchUpInside)
        return button
    }()

    // MARK: - JXSegmentedListContainerViewListDelegate
    func listView() -> UIView {
        return view
    }
}

private extension ShareLinkSubController {
    func layoutPageSubviews() {
        view.backgroundColor = UIColor.ud.bgBase
        view.addSubview(linkCard)
        view.addSubview(copyButton)
        view.addSubview(shareButton)
        linkCard.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(36)
            make.leading.trailing.equalToSuperview().inset(22)
            make.bottom.lessThanOrEqualToSuperview().offset(-100).priority(.medium)
            make.height.equalTo(196).priority(.low)
        }
        copyButton.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().inset(22)
            make.height.equalTo(50)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
            make.trailing.equalTo(view.snp.centerX).offset(-12)
        }
        shareButton.snp.makeConstraints { (make) in
            make.leading.equalTo(view.snp.centerX).offset(12)
            make.height.equalTo(50)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
            make.trailing.equalToSuperview().inset(22)
        }
    }

    private func setButtonEnable(_ isEnable: Bool) {
        let alpha: CGFloat = isEnable ? 1 : 0.6
        copyButton.isEnabled = isEnable
        shareButton.isEnabled = isEnable
        copyButton.alpha = alpha
        shareButton.alpha = alpha
    }

    private func updateLayout() {
        linkCard.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(36)
            make.leading.trailing.equalToSuperview().inset(22)
            make.bottom.lessThanOrEqualToSuperview().offset(-100).priority(.medium)
        }
        linkCard.superview?.layoutIfNeeded()
    }
}
