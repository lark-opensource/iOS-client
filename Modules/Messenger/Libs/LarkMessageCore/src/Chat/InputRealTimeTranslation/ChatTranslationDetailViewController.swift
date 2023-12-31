//
//  ChatTranslationDetailViewController.swift
//  LarkMessageCore
//
//  Created by bytedance on 3/31/22.
//

import UIKit
import Foundation
import LarkUIKit
import LKRichView
import UniverseDesignColor
import EENavigator
import LarkMessengerInterface
import RxSwift
import RxCocoa
import LarkContainer
import LarkSetting
import LarkMenuController
import UniverseDesignIcon
import LarkRichTextCore
import UniverseDesignToast
import RustPB
import LarkModel
import LarkCore
import LarkAssetsBrowser
import LarkEMM
import LarkBaseKeyboard

final class ChatTranslationDetailViewController: BaseUIViewController {
    private var disposeBag = DisposeBag()
    let viewModel: ChatTranslationDetailViewModel
    lazy var core = LKRichViewCore()
    private var contentMargin: CGFloat = 20
    private lazy var configOptions: ConfigOptions = {
        return ConfigOptions([
            .debug(false),
            .visualConfig(VisualConfig(
                selectionColor: UIColor.ud.colorfulBlue.withAlphaComponent(0.16),
                cursorColor: UIColor.ud.colorfulBlue,
                cursorHitTestInsets: UIEdgeInsets(top: -14, left: -25, bottom: -14, right: -25)
            ))
         ])
    }()
    lazy var richContainerView: LKRichContainerView = {
        let richContainerView = LKRichContainerView(frame: .zero, options: configOptions)
        let documentElement = viewModel.getRichElement()
        core.load(styleSheets: viewModel.styleSheets)
        let renderer = core.createRenderer(documentElement)
        core.load(renderer: renderer)
        let richView = richContainerView.richView
        richView.preferredMaxLayoutWidth = view.bounds.size.width - contentMargin * 2
        richView.isOpaque = false
        richView.backgroundColor = .clear
        richView.documentElement = documentElement
        richView.setRichViewCore(core)
        richView.delegate = viewModel
        richView.bindEvent(selectorLists: viewModel.propagationSelectors, isPropagation: true)
        richContainerView.lu.addLongPressGestureRecognizer(
            action: #selector(onLongPressRichView(_:)),
            duration: 0.5,
            target: self)
        richView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        richContainerView.backgroundColor = .clear
        return richContainerView
    }()

    @objc
    private func onLongPressRichView(_ gesture: UIGestureRecognizer) {
        guard gesture.state == .began else {
            return
        }
        richContainerView.richView.switchMode(.visual)
        showMenu()
    }

    lazy var useTranslationButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .ud.primaryContentDefault
        button.layer.cornerRadius = 6
        button.setTitle(BundleI18n.LarkMessageCore.Lark_IM_Translation_TranslatedText_Use_Button, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.setTitleColor(.ud.primaryOnPrimaryFill, for: .normal)
        button.addTarget(self, action: #selector(useTranslation), for: .touchUpInside)
        return button
    }()

    @objc
    private func useTranslation() {
        viewModel.useTranslationCallBack?()
        self.dismiss(animated: true)
    }

    init(viewModel: ChatTranslationDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .ud.bgBody
        self.title = BundleI18n.LarkMessageCore.Lark_IM_Translation_TranslatedText_Title

        view.addSubview(useTranslationButton)
        useTranslationButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-34)
            make.height.equalTo(48)
        }

        let container = RichViewContainerScrollView()
        container.richContainerViewAndCore = (richContainerView, core)
        view.addSubview(container)
        container.addSubview(richContainerView)
        container.snp.makeConstraints { make in
            make.left.equalTo(contentMargin)
            make.right.equalTo(-contentMargin)
            make.bottom.equalTo(useTranslationButton.snp.top).offset(-16)
            make.top.equalTo(15)
        }
        configViewModel()

    }

    func configViewModel() {
        viewModel.eventDriver
            .drive(onNext: { [weak self] event in
                guard let `self` = self,
                      let event = event else { return }
                switch event {
                case .atClick(let userID):
                    self.handleAtClick(userID: userID)
                case .imageClick(property: let property):
                    self.handleImageClick(property: property)
                case .imageCLick(image: let image):
                    self.handleImageClick(image: image)
                case .phoneNumberClick(phoneNumber: let phoneNumber):
                    self.handlePhoneNumberClick(phoneNumber: phoneNumber)
                case .URLClick(url: let url):
                    self.handleURLClick(url)
                case .videoClick(videoTransformInfo: let videoTransformInfo):
                    self.handleVideoClick(videoTransformInfo: videoTransformInfo)
                }
            }).disposed(by: disposeBag)

    }

    func handleAtClick(userID: String) {
        let body = PersonCardBody(chatterId: userID,
                                  chatId: viewModel.chat?.id ?? "",
                                  source: .chat)
        self.viewModel.navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: self,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }

    func handleImageClick(property: Basic_V1_RichTextElement.ImageProperty) {
        var coverImage = ImageSet()
        coverImage.origin.key = property.originKey
        var asset = Asset(sourceType: .image(coverImage))
        asset.key = property.originKey
        asset.originKey = property.originKey
        asset.forceLoadOrigin = true
        asset.isAutoLoadOrigin = true
        let assets = [asset]
        let body = PreviewImagesBody(assets: assets,
                                     pageIndex: 0,
                                     scene: .normal(assetPositionMap: [:], chatId: nil),
                                     trackInfo: PreviewImageTrackInfo(scene: .Chat),
                                     shouldDetectFile: false,
                                     canSaveImage: false,
                                     canShareImage: false,
                                     canEditImage: false,
                                     hideSavePhotoBut: true,
                                     showSaveToCloud: false,
                                     canTranslate: false,
                                     translateEntityContext: (nil, .other))
        self.viewModel.navigator.present(body: body, from: self)
    }
    func handleImageClick(image: UIImage) {
        let vc = LKAssetBrowser()
        let localImageAsset = LKLocalImageAsset(image: image)
        vc.displayAssets = [localImageAsset]
        let navigation = AssetsNavigationController(rootViewController: vc)
        navigation.transitioningDelegate = vc
        navigation.modalPresentationStyle = .custom
        navigation.modalPresentationCapturesStatusBarAppearance = true
        self.viewModel.navigator.present(navigation, from: self)
    }

    func handleVideoClick(videoTransformInfo: VideoTransformInfo) {
        var coverImage = ImageSet()
        coverImage.origin.key = videoTransformInfo.imageLocalKey
        let mediaInfoItem = MediaInfoItem(key: "",
                                          videoKey: "",
                                          coverImage: coverImage,
                                          url: "",
                                          videoCoverUrl: "",
                                          localPath: "",
                                          size: Float(videoTransformInfo.size),
                                          messageId: "",
                                          channelId: "",
                                          sourceId: "",
                                          sourceType: .typeFromUnkonwn,
                                          downloadFileScene: nil,
                                          duration: Int32(videoTransformInfo.duration),
                                          isPCOriginVideo: false)
        var asset = Asset(sourceType: .video(mediaInfoItem))
        asset.isLocalVideoUrl = true
        asset.isVideo = true
        asset.duration = videoTransformInfo.duration
        asset.videoUrl = videoTransformInfo.originPath
        let assets = [asset]
        let body = PreviewImagesBody(assets: assets,
                                     pageIndex: 0,
                                     scene: .normal(assetPositionMap: [:], chatId: nil),
                                     trackInfo: PreviewImageTrackInfo(scene: .Chat),
                                     shouldDetectFile: false,
                                     canSaveImage: false,
                                     canShareImage: false,
                                     canEditImage: false,
                                     hideSavePhotoBut: true,
                                     showSaveToCloud: false,
                                     canTranslate: false,
                                     translateEntityContext: (nil, .other))
        self.viewModel.navigator.present(body: body, from: self)
    }

    func handlePhoneNumberClick(phoneNumber: String) {
        self.viewModel.navigator.open(body: OpenTelBody(number: phoneNumber), from: self)
    }

    func handleURLClick(_ url: URL) {
        if let httpUrl = url.lf.toHttpUrl() {
            self.viewModel.navigator.push(httpUrl, from: self)
        }
    }

    private lazy var isUseNewMenu: Bool = {
        return self.viewModel.fgService?.staticFeatureGatingValue(with: "mobile.core.new_menu") ?? false
    }()

    weak var menuVc: MenuViewController?
    public func showMenu() {
            var inserts: UIEdgeInsets
            let layout: MenuBarLayout
            inserts = UIEdgeInsets(top: 20, left: 10, bottom: 80, right: 10)
            if isUseNewMenu {
                layout = NewMessageCommonMenuLayout(insets: inserts)
            } else {
                layout = MessageCommonMenuLayout(insets: inserts)
            }
            let copyItem = MenuActionItem(
                name: BundleI18n.LarkMessageCore.Lark_Legacy_Copy,
                image: SimpleMenuActionImage(image: UDIcon.getIconByKey(.copyOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)),
                params: [:],
                enable: true
            ) { [weak self] _ in
                guard let self = self else { return }
                let resultAttr: NSAttributedString?
                if self.richContainerView.richView.isSelectAll() {
                    resultAttr = self.viewModel.getAttributeString()
                } else {
                    resultAttr = self.richContainerView.richView.getCopyString()
                }
                guard let resultAttr = resultAttr else { return }
                if CopyToPasteboardManager.copyToPasteboardFormAttribute(resultAttr,
                                                                         fileAuthority: .canCopy(true),
                                                                         pasteboardToken: "LARK-PSDA-messenger-realTimeTranslate-detail-copy-permission",
                                                                         fgService: self.viewModel.userResolver.fg) {
                    UDToast.showSuccess(with: BundleI18n.LarkMessageCore.Lark_Legacy_JssdkCopySuccess, on: self.view)
                } else {
                    UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: self.view)
                }
                self.richContainerView.richView.switchMode(.normal)
                self.menuVc?.dismiss(animated: true, params: nil)
            }
        let menuViewModel = MenuViewModel(chatId: self.viewModel.chat?.id, items: [copyItem])
        let menuVc = MenuViewController(
            viewModel: menuViewModel,
            layout: layout,
            trigerView: self.richContainerView,
            trigerLocation: nil
        )
        menuVc.show(in: self)
        self.menuVc = menuVc
    }
}

private final class MenuViewModel: MenuBarViewModel {
    let chatId: String?
    let items: [MenuActionItem]

    lazy var menuBar: MenuBar = MenuBar(
        reactions: [],
        allReactionGroups: [],
        actionItems: items,
        supportMoreReactions: false,
        triggerGesture: nil
    )

    weak public var menu: MenuVCProtocol?

    public var type: String {
        return "translationDetail"
    }

    public var identifier: String {
        return self.chatId ?? ""
    }

    public var menuView: UIView {
        return self.menuBar
    }

    public var menuSize: CGSize {
        return self.menuBar.menuSize
    }

    init(chatId: String?, items: [MenuActionItem]) {
        self.chatId = chatId
        self.items = items
    }

    func update(rect: CGRect, info: MenuLayoutInfo, isFirstTime: Bool) {}
}

private final class SimpleMenuActionImage: MenuActionImage {
    private let image: UIImage
    init(image: UIImage) {
        self.image = image
    }
    func setActionImage(imageView: UIImageView, enable: Bool) {
        imageView.image = image
    }
}

final class RichViewContainerScrollView: UIScrollView {
    var richContainerViewAndCore: (LKRichContainerView, LKRichViewCore)?
    private var lastSize: CGSize = .zero
    override func layoutSubviews() {
        if bounds.size == lastSize {
            return
        }
        guard let richContainerView = richContainerViewAndCore?.0,
              let richCore = richContainerViewAndCore?.1 else {
            return
        }

        guard let size = richCore.layout(CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude)) else { return }
        if size.height > bounds.height {
            contentSize = CGSize(width: bounds.size.width, height: size.height)
            richContainerView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.left.greaterThanOrEqualToSuperview()
                make.right.lessThanOrEqualToSuperview()
                make.top.equalToSuperview()
                make.height.equalTo(size.height)
            }
        } else {
            contentSize = bounds.size
            richContainerView.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(size)
            }
        }
        lastSize = bounds.size
    }
}
