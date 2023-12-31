//
//  ShareQRCodeSubController.swift
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
import LarkFeatureGating
import LarkSensitivityControl

final class ShareQRCodeSubController: BaseUIViewController, JXSegmentedListContainerViewListDelegate, UserResolverWrapper {
    private static var qrcodeToken = Token("LARK-PSDA-op_microApp_save_qrcode")
    let userResolver: UserResolver
    private let logger = Logger.log(ShareQRCodeSubController.self, category: "lark.share.container.qrcode")
    private let circleAvatar: Bool
    private let needFilterExternal: Bool
    private let contentProvider: (ShareTabType) -> Observable<TabContentMeterial>
    private var currentDisposable: Disposable?
    private var successMaterial: SuccessStatusMaterial.ViaQRCode?
    private let lifeCycleObserver: ((LifeCycleEvent, ShareTabType) -> Void)?
    private var hasHeader: Bool = false
    private var hasContent: Bool = false
    @ScopedInjectedLazy private var snsShareService: LarkShareService?
    /// 新 通用分享面板 - 二维码
    private var sharePanel: LarkSharePanel?
    /// 新通用分享面板FG
    private lazy var newSharePanelFGEnabled: Bool = userResolver.fg.staticFeatureGatingValue(with: "openplatform.share.panel") 

    init(
        userResolver: UserResolver,
        circleAvatar: Bool,
        needFilterExternal: Bool,
        contentProvider: @escaping (ShareTabType) -> Observable<TabContentMeterial>,
        lifeCycleObserver: ((LifeCycleEvent, ShareTabType) -> Void)? = nil
    ) {
        self.userResolver = userResolver
        self.circleAvatar = circleAvatar
        self.needFilterExternal = needFilterExternal
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
        currentDisposable = contentProvider(.viaQRCode)
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (material) in
                switch material {
                case .preload(let commonInfo):
                    self?.qrcodeCard.set(with: commonInfo)
                    self?.hasHeader = true
                case .success(let successMaterial):
                    hud.remove()
                    self?.setButtonEnable(true)
                    guard case .viaQRCode(let info) = successMaterial else {
                        return
                    }
                    self?.hasContent = true
                    self?.successMaterial = info
                    let viewSuccessMaterial = SuccessViewMaterial(
                        link: info.link,
                        expireMsg: info.expiredTip,
                        tipMsg: info.tip
                    )
                    let viewMaterial = StatusViewMaterial.success(viewSuccessMaterial)

                    self?.qrcodeCard.bind(with: viewMaterial)
                    self?.updateLayout()
                case .error(let errorMaterial):
                    hud.remove()
                    self?.setButtonEnable(false)
                    let viewErrorMaterial = ErrorViewMaterial(
                        errorImage: errorMaterial.errorTipImage,
                        errorTipMsg: errorMaterial.errorTipMsg ??
                            BundleI18n.LarkShareContainer.Lark_Legacy_QRCodeLoadFailed
                    )
                    let viewMaterial = StatusViewMaterial.error(viewErrorMaterial)
                    self?.qrcodeCard.bind(with: viewMaterial)
                case .disable(let disableMaterial):
                    hud.remove()
                    self?.setButtonEnable(false)
                    let viewDisableMaterial = DisableViewMaterial(
                        disableTipImage: disableMaterial.disableTipImage,
                        disableTipMsg: disableMaterial.disableTipMsg
                    )
                    let viewMaterial = StatusViewMaterial.disable(viewDisableMaterial)
                    self?.qrcodeCard.bind(with: viewMaterial)
                case .none: break
                }
            }, onError: { (_) in
                hud.remove()
            }, onCompleted: { [weak self] in
                hud.remove()
                guard let self = self, !self.hasHeader, self.hasContent else { return }
                //如无header通用信息，则隐藏header并将content居中
                self.qrcodeCard.hideHeaderView()
                self.qrcodeCard.centreContentView()
            }, onDisposed: {
                hud.remove()
            })
    }

    @objc
    private func saveQRCodeImage() {
        lifeCycleObserver?(.clickSaveForQRCode, .viaQRCode)
        guard let image = qrcodeCard.lu.screenshot() else {
            return
        }
        do {
            try Utils.savePhoto(token: Self.qrcodeToken, image: image) { [weak self] (success, granted) in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch (granted, success) {
                    case (false, _):
                        RoundedHUD.showFailure(
                            with: BundleI18n.LarkShareContainer.Lark_Legacy_PhotoPermissionRequired,
                            on: self.view)
                        self.successMaterial?.saveCompletion?(false)
                    case (true, true):
                        RoundedHUD.showSuccess(
                            with: BundleI18n.LarkShareContainer.Lark_Legacy_QrCodeSaveToAlbum,
                            on: self.view)
                        self.successMaterial?.saveCompletion?(true)
                    case (true, false):
                        RoundedHUD.showFailure(
                            with: BundleI18n.LarkShareContainer.Lark_Legacy_ChatGroupInfoQrCodeSaveFail,
                            on: self.view)
                        self.successMaterial?.saveCompletion?(false)
                    }
                }
            }
        } catch {
            self.logger.error("save qr code image failed, error: \(error)")
        }
    }

    @objc
    private func shareQRCodeImage() {
        lifeCycleObserver?(.clickShare, .viaQRCode)
        guard let image = qrcodeCard.lu.screenshot(),
              let qrcodeMaterial = successMaterial else {
            return
        }
        let imagePrepare = ImagePrepare(
            title: qrcodeMaterial.thirdShareTitle,
            image: image
        )
        let shareContentContext = ShareContentContext.image(imagePrepare)
        let downgradePanelMeterial = DowngradeTipPanelMaterial.image(panelTitle: nil)
        let popoverMaterial = PopoverMaterial(
            sourceView: shareButton,
            sourceRect: CGRect(x: shareButton.frame.width / 2, y: -10, width: 30, height: 30),
            direction: .down
        )
        let inappShareContext = dependency!.inappShareContext(
            with: "",
            image: image,
            needFilterExternal: needFilterExternal
        ) { [weak self] shareResults in
            guard let self = self else { return }
            self.logger.info("about to call lifeCycleObserver callback: \(self.lifeCycleObserver), shareResult: \(shareResults)")
            shareResults?.forEach({ shareResult in
                if shareResult.1 {
                    self.lifeCycleObserver?(.shareSuccess, .viaQRCode)
                } else {
                    self.lifeCycleObserver?(.shareFailure, .viaQRCode)
                }
            })
        }

        /// 新通用分享面板 FG
        if self.newSharePanelFGEnabled {
            var scene = qrcodeMaterial.thirdShareBizId.contains("app_page") ? "Apppage_QRCode" : "App_QRCode"
            self.sharePanel = LarkSharePanel(userResolver: userResolver,
                                             by: qrcodeMaterial.thirdShareBizId,
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
                if result.isFailure() {
                    self.handleShareError(result: result, itemType: type)
                    self.lifeCycleObserver?(.shareFailure, .viaQRCode)
                } else {
                    self.lifeCycleObserver?(.shareSuccess, .viaQRCode)
                }
                let successDesc = result.isSuccess() ? "success" : "failed"
                let logMsg = "share qrcode image \(successDesc) by \(type) with bizId(\(qrcodeMaterial.thirdShareBizId)"
                self.logger.info(logMsg)

                qrcodeMaterial.shareCompletion?(result, type)
            }
        } else {
            snsShareService?.present(
                by: qrcodeMaterial.thirdShareBizId,
                contentContext: shareContentContext,
                baseViewController: self,
                downgradeTipPanelMaterial: downgradePanelMeterial,
                customShareContextMapping: ["inapp": inappShareContext],
                defaultItemTypes: [],
                popoverMaterial: popoverMaterial,
                pasteConfig: .scPasteImmunity) { [weak self] (result, type) in
                guard let `self` = self else { return }

                if result.isFailure() {
                    self.handleShareError(result: result, itemType: type)
                }

                let successDesc = result.isSuccess() ? "success" : "failed"
                let logMsg = "share qrcode image \(successDesc) by \(type) with bizId(\(qrcodeMaterial.thirdShareBizId)"
                self.logger.info(logMsg)

                qrcodeMaterial.shareCompletion?(result, type)
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

    private lazy var qrcodeCard: QRCodeCardView = {
        let card = QRCodeCardView(circleAvatar: circleAvatar, retryHandler: { [weak self] in
            self?.fetchMaterial()
        })
        return card
    }()

    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .custom)
        button.clipsToBounds = true
        button.layer.cornerRadius = 4
        button.backgroundColor = UIColor.ud.bgBase
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.setTitle(BundleI18n.LarkShareContainer.Lark_Legacy_QrCodeSave, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.layer.borderWidth = 0.5
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        button.addTarget(self, action: #selector(saveQRCodeImage), for: .touchUpInside)
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
        button.addTarget(self, action: #selector(shareQRCodeImage), for: .touchUpInside)
        return button
    }()

    // MARK: - JXSegmentedListContainerViewListDelegate
    func listView() -> UIView {
        return view
    }
}

private extension ShareQRCodeSubController {
    func layoutPageSubviews() {
        view.backgroundColor = UIColor.ud.bgBase
        view.addSubview(qrcodeCard)
        view.addSubview(saveButton)
        view.addSubview(shareButton)
        qrcodeCard.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(36)
            make.leading.trailing.equalToSuperview().inset(22)
            make.bottom.lessThanOrEqualTo(saveButton.snp.top).offset(-5).priority(.medium)
        }
        saveButton.snp.makeConstraints { (make) in
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
        saveButton.isEnabled = isEnable
        shareButton.isEnabled = isEnable
        saveButton.alpha = alpha
        shareButton.alpha = alpha
    }

    private func updateLayout() {
        qrcodeCard.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(36)
            make.leading.trailing.equalToSuperview().inset(22)
            make.bottom.lessThanOrEqualTo(saveButton.snp.top).offset(-5).priority(.medium)
        }
        qrcodeCard.superview?.layoutIfNeeded()
    }
}
