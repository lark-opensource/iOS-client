//
//  AssociationQRCodeInviteController.swift
//  LarkContact
//
//  Created by shizhengyu on 2021/3/22.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignColor
import SnapKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import LKCommonsLogging
import LarkAlertController
import UniverseDesignDialog
import EENavigator
import LKMetric
import LarkMessengerInterface
import LarkSnsShare
import LarkContainer
import Homeric
import RustPB
import QRCode
import LarkSDKInterface
import LarkSensitivityControl
import UniverseDesignFont

final class AssociationQRCodeInviteController: BaseUIViewController, CardInteractiable, UserResolverWrapper, UITextViewDelegate {
    private let viewModel: AssociationQRCodeViewModel
    private let router: CollaborationDepartmentViewControllerRouter?
    var userResolver: LarkContainer.UserResolver
    @ScopedProvider private var inAppShareService: InAppShareService?
    @ScopedProvider private var snsShareService: LarkShareService?
    private let monitor = InviteMonitor()
    private var gapScale: CGFloat {
        if Display.pad {
            return 0.25
        }
        return UIScreen.main.bounds.height / 896.0
    }
    private lazy var templateConfig: TemplateConfiguration = {
        var imageOptions = Contact_V1_ImageOptions()
        imageOptions.resolutionType = .highDefinition
        return TemplateConfiguration(
            bizScenario: .unknownScenario,
            imageOptions: imageOptions
        )
    }()
    private lazy var exporter: DynamicRenderingTemplateExporter = {
        return DynamicRenderingTemplateExporter(
            templateConfiguration: templateConfig,
            extraOverlayViews: [:],
            resolver: userResolver
        )
    }()
    private var outputLayerCache: UIImage?
    private var extraOverlayViews: [OverlayViewType: UIView]? {
        didSet {
            exporter.updateExtraOverlayViews(self.extraOverlayViews ?? [:])
        }
    }
    private var exportDisposable: Disposable?
    private let disposeBag = DisposeBag()
    static private let logger = Logger.log(AssociationQRCodeInviteController.self,
                                           category: "LarkContact.AssociationQRCodeInviteController")

    init(viewModel: AssociationQRCodeViewModel, resolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = resolver
        self.router = try? userResolver.resolve(assert: CollaborationDepartmentViewControllerRouter.self)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ud.bgBody
        layoutPageSubviews()
        fetchInviteInfo()
        Tracer.trackBindInviteStart(source: viewModel.source, isAdmin: viewModel.isAdmin)
        retryLoadingView.retryAction = { [unowned self] in
            self.fetchInviteInfo()
        }
    }

    func fetchInviteInfo(needRefresh: Bool = false) {
        // 因为toast会从左上角飘进来，加0.1秒延迟解决
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            var hud = UDToast.showDefaultLoading(on: self.view)

            self.viewModel.fetchCollaborationInviteInfo(needRefresh: needRefresh)?
                .timeout(.seconds(5), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in
                    self?.reloadCard()
                    self?.genConstantOverlayViews()
                    hud.remove()
                    if needRefresh {
                        self?.setRefreshing(false)
                    }
                }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    if needRefresh {
                        self.setRefreshing(false)
                        guard let apiError = error.underlyingError as? APIError else { return }
                        UDToast.showTips(with: apiError.displayMessage, on: self.view)
                    } else {
                        self.retryLoadingView.isHidden = false
                    }
                    hud.remove()
                }, onDisposed: {
                    hud.remove()
                }).disposed(by: self.disposeBag)
        }

    }

    lazy var helpTipsView: UITextView = {
        let textView = UITextView()

        textView.backgroundColor = .ud.bgBody
        textView.attributedText = getHelpLabel(with: .internal)
        textView.delegate = self
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.isScrollEnabled = false

        return textView
    }()

    func updateHelpLabel(with contactType: AssociationContactType) {
        helpTipsView.attributedText = getHelpLabel(with: contactType)
    }

    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool {
        router?.pushAssociationInviteHelpURL(url: url, from: self)
        return false
    }

    private lazy var qrcodeCardContainer: UIScrollView = {
        let container = UIScrollView()
        container.backgroundColor = UIColor.ud.bgBody
        container.showsVerticalScrollIndicator = false
        container.alwaysBounceVertical = false
        container.contentInsetAdjustmentBehavior = .never
        container.isScrollEnabled = true
        return container
    }()

    private lazy var qrcodeCard: AssociationQRCodeView = {
        let card = AssociationQRCodeView(gapScale: gapScale, delegate: self)
        return card
    }()

    private lazy var saveQRCodeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.bgBody), for: .normal)
        button.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.N200), for: .highlighted)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = 6.0
        button.layer.masksToBounds = true
        button.setTitle(BundleI18n.LarkContact.Lark_B2B_Save, for: .normal)
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
        button.layer.cornerRadius = 6.0
        button.layer.masksToBounds = true
        button.setTitle(BundleI18n.LarkContact.Lark_B2B_Share, for: .normal)
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
        downloadRendedImageIfNeeded { [weak self] (image) in
            self?.shareQRCode(cardImage: image)
        }
    }

    func triggleOtherAction(cardType: CardViewType) {
        downloadRendedImageIfNeeded { [weak self] (image) in
            self?.saveQRCodeImage(cardImage: image)
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
}

// Biz Logic
private extension AssociationQRCodeInviteController {
    func shareQRCode(cardImage: UIImage) {
        Self.logger.info("start share qrcode image")
        let imageContentInLark = ImageContentInLark(
            name: "",
            image: cardImage,
            type: .normal,
            needFilterExternal: false,
            cancelCallBack: nil,
            successCallBack: {
                Tracer.trackBindInviteComfirmTransmitClick()
            })
        guard let inAppShareService = self.inAppShareService else { return }
        let inappShareContext = inAppShareService.genInAppShareContext(content: .image(content: imageContentInLark))
        let imagePrepare = ImagePrepare(
            title: "",
            image: cardImage
        )
        let shareContentContext = ShareContentContext.image(imagePrepare)
        let downgradePanelMeterial = DowngradeTipPanelMaterial.image(panelTitle: nil)
        let popoverMaterial = PopoverMaterial(
            sourceView: shareQRCodeButton,
            sourceRect: CGRect(x: shareQRCodeButton.frame.width / 2, y: -10, width: 30, height: 30),
            direction: .down
        )
        snsShareService?.present(
            by: "lark.invite.b2b.qrcode",
            contentContext: shareContentContext,
            baseViewController: self,
            downgradeTipPanelMaterial: downgradePanelMeterial,
            customShareContextMapping: ["inapp": inappShareContext],
            defaultItemTypes: [],
            popoverMaterial: popoverMaterial) { [weak self] (result, type) in
            guard let `self` = self else { return }
            if result.isSuccess() {
                if case .custom(let context) = type, context.identifier == "inapp" {
                    Tracer.trackMessageForwardSingleClick()
                }
            } else {
                self.handleShareError(result: result, itemType: type)
            }
            let logMsg = "association invite share QRCode \(result.isSuccess() ? "success" : "failed") by \(type)"
            Self.logger.info(logMsg)
        }
    }

    func saveQRCodeImage(cardImage: UIImage) {
        Self.logger.info("save qrcode image")
        do {
            let token = Token("LARK-PSDA-association_qrcode_save")
            try AlbumEntry.UIImageWriteToSavedPhotosAlbum(forToken: token, cardImage, self, #selector(savePhotoToAlbum(image:didFinishSavingWithError:contextInfo:)), nil)
        } catch {
            ContactLogger.shared.error(module: .action, event: "\(Self.self) no save image token: \(error.localizedDescription)")
        }
    }

    func refreshLink() {
        Self.logger.info("refresh link")
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkContact.Lark_B2B_ConfirmReset)
        alertController.setContent(
            text: BundleI18n.LarkContact.Lark_B2B_InvitationExpired
        )
        alertController.addSecondaryButton(text: BundleI18n.LarkContact.Lark_B2B_Cancel)
        alertController.addDestructiveButton(text: BundleI18n.LarkContact.Lark_B2B_Reset, dismissCompletion: {
            self.setRefreshing(true)
            self.fetchInviteInfo(needRefresh: true)
        })
        navigator.present(alertController, from: self)
    }

    func handleShareError(result: ShareResult, itemType: LarkShareItemType) {
        if case .failure(let errorCode, let debugMsg) = result {
            switch errorCode {
            case .notInstalled:
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
        qrcodeCard.setRefreshing(toRefresh)
    }

    func reloadCard() {
        if let inviteInfo = viewModel.inviteInfo {
            qrcodeCard.bindWithModel(cardInfo: inviteInfo)
        }
    }
}

private extension AssociationQRCodeInviteController {
    func layoutPageSubviews() {
        self.title = (viewModel.contactType == .internal) ? BundleI18n.LarkContact.Lark_B2B_Title_InviteInternalOrg : BundleI18n.LarkContact.Lark_B2B_Title_InviteExternalOrg

        view.addSubview(qrcodeCardContainer)
        qrcodeCardContainer.addSubview(helpTipsView)
        qrcodeCardContainer.addSubview(qrcodeCard)
        view.addSubview(saveQRCodeButton)
        view.addSubview(shareQRCodeButton)

        let bottomMargin = Display.iPhoneXSeries ? 60 : 16

        qrcodeCardContainer.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(44 + bottomMargin * 2)
        }

        helpTipsView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }
        qrcodeCard.snp.makeConstraints { (make) in
            make.top.equalTo(helpTipsView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
            make.height.equalTo(380)
            make.bottom.equalToSuperview()
        }

        saveQRCodeButton.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().inset(20)
            make.trailing.equalTo(view.snp.centerX).offset(-8)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().inset(bottomMargin)
        }
        shareQRCodeButton.snp.makeConstraints { (make) in
            make.leading.equalTo(view.snp.centerX).offset(8)
            make.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().inset(bottomMargin)
        }

        qrcodeCard.updateTipWithIsOversea(viewModel.isOversea)
        updateHelpLabel(with: viewModel.contactType)

    }

    func downloadRendedImageIfNeeded(completion: @escaping (UIImage) -> Void) {
        if let cache = outputLayerCache {
            completion(cache)
            return
        }
        guard let configurations = viewModel.inviteInfo?.meta.viewQr else { return }
        print("server configurations = \(configurations)")
        let cliConfigurations = configurations.map { (serConfiguration) -> Contact_V1_ImageConfiguration in
            return Contact_V1_ImageConfiguration.transform(from: serConfiguration)
        }
        exportDisposable?.dispose()

        let hud = UDToast.showLoading(on: view)
        exportDisposable = exporter.export(by: cliConfigurations)
            .observeOn(MainScheduler.instance)
            .timeout(.seconds(10), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (outputLayer) in
                hud.remove()
                Self.logger.info("save qrcode image")
                self?.outputLayerCache = outputLayer
                completion(outputLayer)
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                hud.remove()
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

    func genConstantOverlayViews() {
        guard let inviteInfo = viewModel.inviteInfo else { return }

        let qrcodeContentSize = CGSize(width: 200, height: 200)

        // 二维码视图
        let qrcodeView = UIImageView()
        qrcodeView.frame = CGRect(x: 0, y: 0, width: qrcodeContentSize.width, height: qrcodeContentSize.height)
        qrcodeView.contentMode = .scaleAspectFill
        qrcodeView.image = QRCodeTool.createQRImg(str: inviteInfo.meta.url, size: qrcodeContentSize.width)

        extraOverlayViews = [OverlayViewType.qrcodeStr: qrcodeView]
    }

    func getHelpLabel(with contactType: AssociationContactType) -> NSAttributedString {
        let text = (contactType == .internal) ? BundleI18n.LarkContact.Lark_B2B_Title_InviteInternalOrgDetails : BundleI18n.LarkContact.Lark_B2B_Title_InviteExternalOrgDetails
        // 创建富文本
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UDFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.ud.textPlaceholder
        ]
        let attributedString = NSMutableAttributedString(string: text, attributes: textAttributes)

        // 添加超链接
        if let url = viewModel.helpURL {
            let linkText = " " + BundleI18n.LarkContact.Lark_B2B_Link_HelpCenterArticle
            let linkAttributes: [NSAttributedString.Key: Any] = [
                .link: url,
                .font: UDFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.ud.textLinkNormal
            ]
            let linkAttributedString = NSAttributedString(string: linkText, attributes: linkAttributes)
            attributedString.append(linkAttributedString)
        }
        return attributedString
    }
}
