//
//  CalendarShareQRCodeViewController.swift
//  Calendar
//
//  Created by Hongbin Liang on 4/18/23.
//

import Foundation
import RxSwift
import QRCode
import LarkUIKit
import LarkBizAvatar
import LarkEMM
import LarkSnsShare
import LarkLocalizations
import LarkSensitivityControl
import UniverseDesignButton
import UniverseDesignTabs
import UniverseDesignToast
import UniverseDesignEmpty
import UniverseDesignIcon
import LarkContainer
import Swinject

class CalendarShareQRCodeViewData: ShareCalendarLinkViewData {
    var avatarInfo: CalendarAvatar = .normal(
        avatar: CalendarDetailCardViewModel.defaultAvatar.avatar,
        key: CalendarDetailCardViewModel.defaultAvatar.key
    )
}

class CalendarShareQRCodeViewController: UIViewController, UserResolverWrapper {
    private lazy var loadingView: LoadingView = {
        let loadingView = LoadingView(displayedView: self.view)
        loadingView.backgroundColor = .ud.bgBase
        return loadingView
    }()

    private let fullScreenTipView = PlaceHolderIconLabelView()

    private lazy var btnContainer: UIStackView = {
        let btnContainer = UIStackView(arrangedSubviews: [saveBtn, shareBtn])
        btnContainer.distribution = .fillEqually
        btnContainer.spacing = 17
        return btnContainer
    }()

    private let card = UIView()
    private let headerBG = CalendarDetailHeaderBGView()
    private let avatarView = BizAvatar()
    private let titleLabel = UILabel()
    private let ownerLabel = UILabel()
    private let subscriberNumLabel = UILabel()
    private let descLabel = UILabel()

    private let tipLabel = UILabel()
    private let qrCodeImageView = UIImageView()

    private let saveBtn = UDButton(.secondaryBlue)
    private let shareBtn = UDButton(.primaryBlue)

    private var sharePanel: LarkSharePanel?

    private let disposeBag = DisposeBag()

    private let viewModel: CalendarShareViewModel

    let userResolver: UserResolver

    init(viewModel: CalendarShareViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .ud.bgBase
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let container = UIScrollView()
        container.showsVerticalScrollIndicator = false
        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        card.clipsToBounds = true
        card.layer.cornerRadius = 16
        container.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(80)
            make.leading.trailing.equalToSuperview().inset(16)
            make.centerX.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview().inset(80)
        }

        let cardHeader = UIView()
        card.addSubview(cardHeader)
        cardHeader.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        cardHeader.addSubview(headerBG)
        headerBG.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.greaterThanOrEqualToSuperview()
        }

        cardHeader.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().inset(16)
            make.size.equalTo(CGSize(width: 56, height: 56))
        }

        titleLabel.numberOfLines = 2
        titleLabel.font = UIFont.cd.semiboldFont(ofSize: 16)
        titleLabel.textColor = .ud.staticWhite
        cardHeader.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(16)
            make.leading.equalTo(avatarView.snp.trailing).offset(16)
        }

        ownerLabel.font = UIFont.cd.regularFont(ofSize: 12)
        ownerLabel.textColor = .ud.staticWhite

        subscriberNumLabel.font = UIFont.cd.regularFont(ofSize: 12)
        subscriberNumLabel.textColor = .ud.staticWhite

        descLabel.font = UIFont.cd.regularFont(ofSize: 12)
        descLabel.textColor = .ud.staticWhite
        if !FG.showSubscribers { descLabel.numberOfLines = 2 }

        let list = UIStackView(arrangedSubviews: [ownerLabel, subscriberNumLabel, descLabel])
        list.axis = .vertical

        cardHeader.addSubview(list)
        list.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.trailing.equalToSuperview().inset(16)
            make.leading.equalTo(avatarView.snp.trailing).offset(16)
            make.bottom.equalToSuperview().inset(20)
        }

        ownerLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
        }

        subscriberNumLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
        }

        descLabel.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(20)
        }

        let cardCenter = UIView()
        cardCenter.backgroundColor = .ud.bgFloat
        card.addSubview(cardCenter)
        cardCenter.snp.makeConstraints { make in
            make.top.equalTo(cardHeader.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        let qrCodeWrapper = UIView()
        qrCodeWrapper.backgroundColor = .ud.staticWhite
        qrCodeWrapper.layer.cornerRadius = 10
        cardCenter.addSubview(qrCodeWrapper)
        qrCodeWrapper.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(24)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(164)
        }
        qrCodeImageView.layer.cornerRadius = 4
        qrCodeImageView.clipsToBounds = true
        qrCodeWrapper.addSubview(qrCodeImageView)
        qrCodeImageView.snp.makeConstraints { make in
            make.width.height.equalTo(148)
            make.center.equalToSuperview()
        }

        tipLabel.numberOfLines = 2
        tipLabel.font = UIFont.cd.regularFont(ofSize: 12)
        tipLabel.textColor = .ud.textCaption
        tipLabel.textAlignment = .center
        tipLabel.text = I18n.Calendar_Share_HowToSubscribe()
        cardCenter.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.top.equalTo(qrCodeWrapper.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.leading.trailing.lessThanOrEqualToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(32)
        }

        var shareBtnConfig = shareBtn.config
        shareBtnConfig.type = .big
        shareBtn.config = shareBtnConfig
        saveBtn.setTitle(I18n.Calendar_Share_SaveImage, for: .normal)
        shareBtn.snp.makeConstraints { $0.height.equalTo(48) }

        var saveBtnConfig = saveBtn.config
        saveBtnConfig.type = .big
        saveBtn.config = saveBtnConfig
        shareBtn.setTitle(I18n.Calendar_Share_ShareButton, for: .normal)
        saveBtn.snp.makeConstraints { $0.height.equalTo(48) }

        shareBtn.addTarget(self, action: #selector(doShare), for: .touchUpInside)
        saveBtn.addTarget(self, action: #selector(doSaveImage), for: .touchUpInside)

        view.addSubview(btnContainer)
        btnContainer.snp.makeConstraints { make in
            make.top.equalTo(container.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(12)
        }

        view.addSubview(fullScreenTipView)
        fullScreenTipView.isHidden = true
        fullScreenTipView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        bindData()
    }

    private func bindData() {
        viewModel.rxQRCodeData
            .subscribeForUI { [weak self] qrCodeData in
                guard let self = self, let qrCodeData = qrCodeData else { return }
                self.titleLabel.text = qrCodeData.calTitle
                self.ownerLabel.text = I18n.Calendar_Detail_OwnerColon + qrCodeData.ownerName
                if FG.showSubscribers, qrCodeData.subscriberNum >= 0 { self.subscriberNumLabel.text = I18n.Calendar_Share_HowManySubscribed_Desc + qrCodeData.subscriberNum.description }
                self.subscriberNumLabel.isHidden = self.subscriberNumLabel.text.isEmpty
                self.descLabel.text = (FG.showSubscribers ? I18n.Calendar_Share_CalendarDesc_Desc : I18n.Calendar_Detail_DescriptionColon) + qrCodeData.calDesc
                self.qrCodeImageView.image = QRCodeTool.createQRImg(str: qrCodeData.linkStr, size: 148)

                switch qrCodeData.avatarInfo {
                case let .normal(avatar: image, key: key):
                    var avatarInfo: (avatar: UIImage, key: String)
                    if let image = image {
                        avatarInfo = (image, key)
                    } else {
                        avatarInfo = CalendarDetailCardViewModel.defaultAvatar
                    }
                    self.avatarView.image = avatarInfo.avatar
                    self.headerBG.setHeaderBGImageWithOriginImage(avatarInfo.avatar, avatarInfo.key)
                case let .primary(avatarKey: key, identifier: identifier):
                    self.avatarView.setAvatarByIdentifier(identifier, avatarKey: key, avatarViewParams: .defaultBig) { [weak self] imageResult in
                        guard let self = self else { return }
                        var avatarInfo: (avatar: UIImage, key: String)
                        if case .success(let imageResult) = imageResult, let image = imageResult.image {
                            avatarInfo = (image, imageResult.request.requestKey)
                        } else {
                            CalendarBiz.shareLogger.error("Download primary avatar failed.")
                            avatarInfo = CalendarDetailCardViewModel.defaultAvatar
                        }
                        self.headerBG.setHeaderBGImageWithOriginImage(avatarInfo.avatar, avatarInfo.key)
                    }
                }
            }.disposed(by: disposeBag)

        viewModel.rxQRCodeViewStatus
            .subscribeForUI { [weak self] status in
                guard let self = self else { return }
                if case .loading = status {
                    self.loadingView.showLoading()
                }
                if case .error(let error) = status {
                    if error.errorType() == .calendarIsPrivateErr {
                        self.fullScreenTipView.isHidden = false
                        self.fullScreenTipView.image = UDEmptyType.noPreview.defaultImage()
                        self.fullScreenTipView.title = I18n.Calendar_G_CantSharePrivateCalendar
                    } else if error.errorType() == .calendarIsDeletedErr {
                        self.fullScreenTipView.isHidden = false
                        self.fullScreenTipView.image = UDEmptyType.noSchedule.defaultImage()
                        self.fullScreenTipView.title = I18n.Calendar_Common_CalendarDeleted
                    } else {
                        self.loadingView.showFailed(withRetry: { [weak self] in
                            self?.viewModel.fetchData()
                        })
                    }
                }
                if case .dataLoaded = status {
                    self.loadingView.remove()
                }
            }.disposed(by: disposeBag)
    }

    private lazy var generatedImage: UIImage = {
        card.layer.cornerRadius = 0
        let renderer = UIGraphicsImageRenderer(size: card.bounds.size)
        let image = renderer.image { _ in
            self.card.drawHierarchy(in: self.card.bounds, afterScreenUpdates: true)
        }
        defer { card.layer.cornerRadius = 16 }
        return image
    }()

    @objc
    private func doSaveImage() {
        let token = SensitivityControlToken.shareCalendarSaveQR
        do {
            try AlbumEntry.UIImageWriteToSavedPhotosAlbum(
                forToken: token.LSCToken,
                generatedImage,
                self,
                #selector(self.savePhotoToAlbum(image:didFinishSavingWithError:contextInfo:)),
                nil)
            CalendarTracerV2.CalendarShare.traceClick {
                $0.click("qr_code_download")
                $0.calendar_id = self.viewModel.calContext.calID
                $0.is_admin_plus = self.viewModel.calContext.isManager.description
            }
        } catch {
            SensitivityControlToken.logFailure("Failed to save image, because SensitivityControl for \(token), error: \(error)")
            UDToast.showFailure(with: I18n.Calendar_Share_UnableToSaveToast, on: view)
        }
    }

    @objc
    private func savePhotoToAlbum(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        if error != nil {
            UDToast.showFailure(with: I18n.Calendar_Share_UnableToSaveToast, on: view)
        } else {
            UDToast.showSuccess(with: I18n.Calendar_Share_AlbumSaved, on: view)
        }
    }

    @objc
    private func doShare() {
        let imagePrepare = ImagePrepare(title: "", image: generatedImage)
        let contentContext = ShareContentContext.image(imagePrepare)

        let shareContent: CustomShareContent = .text("", ["": ""])

        let icon = UDIcon.getIconByKeyNoLimitSize(.forwardOutlined).ud.resized(to: CGSize(width: 24, height: 24)).renderColor(with: .n1)
        let itemContext = CustomShareItemContext(title: I18n.Calendar_Share_Lark, icon: icon)
        let inapp = CustomShareContext(
            identifier: "inapp",
            itemContext: itemContext,
            content: shareContent
        ) { [weak self] _, _, _ in
            self?.shareImageToChat()
        }

        let pop = PopoverMaterial(sourceView: shareBtn,
                                  sourceRect: shareBtn.bounds,
                                  direction: .any)

        sharePanel = LarkSharePanel(userResolver: self.userResolver,
                                    with: [.custom(inapp)],
                                    shareContent: contentContext,
                                    on: self,
                                    popoverMaterial: pop,
                                    productLevel: "calendar",
                                    scene: "calendar_share_in_qrcode",
                                    pasteConfig: .scPasteImmunity)

        sharePanel?.show(nil)

        CalendarTracerV2.CalendarShare.traceClick {
            $0.click("qr_code_share")
            $0.calendar_id = self.viewModel.calContext.calID
            $0.is_admin_plus = self.viewModel.calContext.isManager.description
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarShareQRCodeViewController: UDTabsListContainerViewDelegate {
    func listView() -> UIView { view }

    // fix UD 内部 lazy 导致 view.bottom safeArea 取到 0 的问题
    func listDidAppear() {
        btnContainer.snp.updateConstraints { make in
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(12)
        }
    }
}

// MARK: - SharePanel action
extension CalendarShareQRCodeViewController {
    private func shareImageToChat() {
        let modalStyle: UIModalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        viewModel.rustAPI?.calendarDependency
            .jumpToImageShareController(from: self, image: generatedImage, modalPresentationStyle: modalStyle)
    }
}
