//
//  EventCheckInQRCodeViewController.swift
//  Calendar
//
//  Created by huoyunjie on 2022/9/19.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa
import UIKit
import UniverseDesignButton
import UniverseDesignToast
import UniverseDesignTabs
import UniverseDesignIcon
import CalendarFoundation
import UniverseDesignColor
import LarkSnsShare
import UniverseDesignEmpty
import LarkEMM
import LarkSensitivityControl

extension EventCheckInQRCodeViewController: UDTabsListContainerViewDelegate {
    func listView() -> UIView {
        return self.view
    }
}

class EventCheckInQRCodeViewController: UIViewController, UserResolverWrapper {

    let userResolver: UserResolver

    @ScopedInjectedLazy var rustApi: CalendarRustAPI?

    private let rxImage: BehaviorRelay<UIImage?> = .init(value: nil)

    private let imgWrapper = UIScrollView()
    private let imageView: UIImageView = UIImageView(image: nil)

    private lazy var saveImageBtn: UDButton = {
        let button = UDButton(.secondaryBlue)
        button.config.type = .big
        button.setTitle(I18n.Calendar_Share_SaveImage, for: .normal)
        button.addTarget(self, action: #selector(doSaveImage), for: .touchUpInside)
        return button
    }()

    private lazy var shareBtn: UDButton = {
        let button = UDButton(.primaryBlue)
        button.config.type = .big
        button.setTitle(I18n.Calendar_Share_ShareButton, for: .normal)
        button.addTarget(self, action: #selector(doShare), for: .touchUpInside)
        return button
    }()

    private lazy var loadingView: LoadingView = {
        let loadingView = LoadingView(displayedView: self.view)
        loadingView.backgroundColor = self.view.backgroundColor
        return loadingView
    }()

    private var sharePanel: LarkSharePanel?
    private let disposeBag = DisposeBag()
    private let viewModel: EventCheckInInfoViewModel

    // 埋点需要
    private var eventID: String = ""
    private let startTime: Int64

    init(viewModel: EventCheckInInfoViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        self.startTime = viewModel.startTime
        super.init(nibName: nil, bundle: nil)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        loadingView.showLoading()
        viewModel.getEventCheckInInfo(condition: [.image])
            .map({ [weak self] response -> UIImage in
                guard let image = UIImage(data: response.imageData) else {
                    throw RxError.unknown
                }
                self?.eventID = String(response.eventID)
                return image
            })
            .subscribeForUI(onNext: { [weak self] image in
                self?.rxImage.accept(image)
                self?.loadingView.remove()
                CalendarTracerV2.CheckInfo.traceClick {
                    $0.click("code").target("none")
                    $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: self?.eventID,
                                                                           eventStartTime: self?.viewModel.startTime.description,
                                                                           originalTime: self?.viewModel.originalTime.description,
                                                                           uid: self?.viewModel.key))
                }
            }, onError: { [weak self] error in
                if error.errorType() == .calendarEventCheckInApplinkNoPermission {
                    self?.loadingView.show(image: UDEmptyType.noAccess.defaultImage(), title: I18n.Calendar_Event_NoPermitView)
                } else {
                    self?.loadingView.showFailed { [weak self] in
                        self?.setup()
                    }
                }
            })
            .disposed(by: disposeBag)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UDColor.bgBase

        let stackView = UIStackView(arrangedSubviews: [saveImageBtn, shareBtn])
        stackView.axis = .horizontal
        stackView.spacing = 17
        stackView.distribution = .fillEqually

        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.right.left.equalToSuperview().inset(16)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(12)
        }

        view.addSubview(imgWrapper)
        imgWrapper.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(stackView.snp.top).offset(-24)
        }

        imgWrapper.addSubview(imageView)
        imageView.layer.cornerRadius = 12
        imageView.layer.masksToBounds = true
        imageView.clipsToBounds = true
        imageView.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(343)
            make.height.equalTo(0)
            make.left.right.greaterThanOrEqualTo(24)
            make.centerX.equalToSuperview()
            make.top.lessThanOrEqualTo(imgWrapper.contentLayoutGuide.snp.top).offset(80).priority(.high)
            make.bottom.lessThanOrEqualTo(imgWrapper.contentLayoutGuide.snp.bottom).priority(.low)
        }

        bindRxImageViewData()

    }

    private func bindRxImageViewData() {
        self.rxImage
            .subscribeForUI(onNext: { [weak self] image in
                guard let self = self, let image = image else { return }
                self.updateImageView(image)
            })
            .disposed(by: disposeBag)
    }

    private func updateImageView(_ image: UIImage) {
        let imgSize = image.size
        self.imageView.image = image

        imageView.setNeedsLayout()
        imageView.layoutIfNeeded()

        let imgViewWidth = imageView.bounds.width
        let imgViewHeight = imgSize.height * (imgViewWidth / imgSize.width)

        let topInsetAutoLayout = imgViewHeight > imgWrapper.bounds.height - 80 * 2 ? 24 : 80

        imageView.snp.updateConstraints { make in
            make.height.equalTo(imgViewHeight)
            make.top.lessThanOrEqualTo(imgWrapper.contentLayoutGuide.snp.top).offset(topInsetAutoLayout).priority(.high)
        }
    }

    @objc
    private func doSaveImage() {
        CalendarTracerV2.CheckInfo.traceClick {
            $0.click("download_pic").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: eventID,
                                                                   eventStartTime: viewModel.startTime.description,
                                                                   originalTime: viewModel.originalTime.description,
                                                                   uid: viewModel.key))
        }
        let renderer = UIGraphicsImageRenderer(size: self.imageView.bounds.size)
        let image = renderer.image { _ in
            self.imageView.drawHierarchy(in: self.imageView.bounds, afterScreenUpdates: true)
        }
        let token = SensitivityControlToken.checkInSaveQR
        do {
            try AlbumEntry.UIImageWriteToSavedPhotosAlbum(
                forToken: token.LSCToken,
                image,
                self,
                #selector(self.savePhotoToAlbum(image:didFinishSavingWithError:contextInfo:)),
                nil)
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
        guard let image = self.rxImage.value else { return }
        CalendarTracerV2.CheckInfo.traceClick {
            $0.click("share_pic").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: eventID,
                                                                   eventStartTime: viewModel.startTime.description,
                                                                   originalTime: viewModel.originalTime.description,
                                                                   uid: viewModel.key))
        }
        let imagePrepare = ImagePrepare(title: "", image: image)
        let contentContext = ShareContentContext.image(imagePrepare)

        let shareContent: CustomShareContent = .text("", ["": ""])

        let icon = UDIcon.getIconByKeyNoLimitSize(.forwardOutlined).ud.resized(to: CGSize(width: 24, height: 24)).renderColor(with: .n1)
        let itemContext = CustomShareItemContext(title: I18n.Calendar_Share_Lark, icon: icon)
        let inapp = CustomShareContext(
            identifier: "inapp",
            itemContext: itemContext,
            content: shareContent) { [weak self] _, _, _ in
                self?.shareImageToChat()
        }

        let copyIcon = UDIcon.getIconByKeyNoLimitSize(.linkCopyOutlined).ud.resized(to: CGSize(width: 24, height: 24)).renderColor(with: .n1)
        let copyContext = CustomShareItemContext(title: I18n.Calendar_Share_CopyLink, icon: copyIcon)
        let copy = CustomShareContext(
            identifier: "copy",
            itemContext: copyContext,
            content: shareContent) { [weak self] _, _, _ in
                self?.copyLink()
        }

        let pop = PopoverMaterial(sourceView: shareBtn,
                                  sourceRect: shareBtn.bounds,
                                  direction: .any)

        sharePanel = LarkSharePanel(userResolver: self.userResolver,
                                    with: [.custom(inapp), .custom(copy)],
                                    shareContent: contentContext,
                                    on: self, popoverMaterial: pop,
                                    productLevel: "calendar",
                                    scene: "event_check_in_qrcode",
                                    pasteConfig: .scPasteImmunity)

        sharePanel?.show(nil)

    }
}

extension EventCheckInQRCodeViewController {

    private func shareImageToChat() {
        guard let image = self.rxImage.value else { return }
        self.rustApi?.calendarDependency.jumpToImageShareController(from: self, image: image, modalPresentationStyle: .formSheet)
    }

    private func copyLink() {
        UDToast.showLoading(with: I18n.Calendar_Common_LoadingCommon, on: view)
        self.viewModel.getEventCheckInInfo(condition: [.checkInUrl])
            .subscribeForUI(onNext: { [weak self] checkInfo in
                guard let self = self else { return }
                let string = checkInfo.generateAttributeString().string
                do {
                    var config = PasteboardConfig(token: LarkSensitivityControl.Token(SCPasteboardUtils.getSceneKey(.eventCheckInQRCodeShareUrlCopy)))
                    config.shouldImmunity = true
                    try SCPasteboard.generalUnsafe(config).string = string
                    UDToast.showSuccess(with: I18n.Calendar_Share_Copied, on: self.view)
                } catch {
                    SCPasteboardUtils.logCopyFailed()
                    UDToast.showFailure(with: I18n.Calendar_Share_UnableToCopy, on: self.view)
                }
            }, onError: { [weak self] _ in
                guard let self = self else { return }
                UDToast.showFailure(with: I18n.Calendar_Common_FailedToLoad, on: self.view)
            }).disposed(by: disposeBag)
    }
}
