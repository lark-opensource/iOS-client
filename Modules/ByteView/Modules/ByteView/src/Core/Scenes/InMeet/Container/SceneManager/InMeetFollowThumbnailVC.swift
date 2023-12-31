//
//  InMeetFollowThumbnailVC.swift
//  ByteView
//
//  Created by liujianlong on 2022/9/4.
//

import UIKit
import RxSwift
import RxRelay
import ByteViewNetwork
import SnapKit
import UniverseDesignColor
import UniverseDesignIcon

class InMeetFollowThumbnailVM: InMeetShareDataListener {

    var magicShareAndSSToMSDocumentObservable: Observable<MagicShareDocument?> {
        magicShareAndSSToMSDocumentRelay.asObservable()
    }
    private let magicShareAndSSToMSDocumentRelay = BehaviorRelay<MagicShareDocument?>(value: nil)

    let meeting: InMeetMeeting
    let shareWatermark: ShareWatermarkManager
    var service: MeetingBasicService { meeting.service }
    init(meeting: InMeetMeeting, resolver: InMeetViewModelResolver) {
        self.meeting = meeting
        self.shareWatermark = resolver.resolve()!
        meeting.shareData.addListener(self)
    }

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        switch newScene.shareSceneType {
        case .magicShare:
            magicShareAndSSToMSDocumentRelay.accept(newScene.magicShareData)
        case .shareScreenToFollow:
            magicShareAndSSToMSDocumentRelay.accept(newScene.shareScreenToFollowData)
        default:
            magicShareAndSSToMSDocumentRelay.accept(nil)
        }
    }
}

class InMeetFollowThumbnailVC: UIViewController {
    private let viewModel: InMeetFollowThumbnailVM
    private var currentSharingThumbnailURL: String?
    private let disposeBag = DisposeBag()
    private let preferredThumbnailSize: CGSize?
    /// 水印
    private var watermarkView: UIView?

    private lazy var sharingDefaultThumbnail: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.shareScreenFilled, iconColor: .ud.iconN3, size: CGSize(width: 54, height: 54))
        view.contentMode = .scaleAspectFit
        view.isHidden = true
        return view
    }()

    private lazy var sharingDocumentThumbnail: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.layer.ud.setBorderColor(UIColor.ud.lineDividerDefault, bindTo: self.view)
        view.layer.borderWidth = 0.5
        view.layer.cornerRadius = 8.0
        view.isHidden = true
        return view
    }()

    required init?(coder: NSCoder) {
        return nil
    }

    init(viewModel: InMeetFollowThumbnailVM, thumbnailSize: CGSize? = nil) {
        self.viewModel = viewModel
        self.preferredThumbnailSize = thumbnailSize
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UDColor.vcTokenMeetingBgVideoOff
        self.view.addSubview(sharingDefaultThumbnail)
        self.view.addSubview(sharingDocumentThumbnail)

        sharingDefaultThumbnail.snp.makeConstraints { (make: ConstraintMaker) in
            make.center.equalToSuperview()
            make.width.equalTo(sharingDocumentThumbnail.snp.height)
            make.height.equalToSuperview().multipliedBy(0.3)
        }

        sharingDocumentThumbnail.snp.makeConstraints { (make: ConstraintMaker) in
            make.edges.equalToSuperview()
        }

        bindViewModel()
    }

    var isThumbnailLoaded: Bool = false {
        didSet {
            guard self.isThumbnailLoaded != oldValue else {
                return
            }
            self.isThumbnailLoadedCallback?(self.isThumbnailLoaded)
        }
    }
    var isThumbnailLoadedCallback: ((Bool) -> Void)? {
        didSet {
            self.isThumbnailLoadedCallback?(self.isThumbnailLoaded)
        }
    }

    private func bindViewModel() {
        viewModel.magicShareAndSSToMSDocumentObservable
            .distinctUntilChanged { (v1: MagicShareDocument?, v2: MagicShareDocument?) in v1?.thumbnail?.thumbnailURL == v2?.thumbnail?.thumbnailURL }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (document: MagicShareDocument?) in
                guard let self = self else {
                    return
                }
                guard let thumbnail = document?.thumbnail, !thumbnail.thumbnailURL.isEmpty else {
                    self.sharingDefaultThumbnail.isHidden = false
                    self.sharingDocumentThumbnail.isHidden = true
                    return
                }
                self.sharingDefaultThumbnail.isHidden = !self.sharingDocumentThumbnail.isHidden
                self.currentSharingThumbnailURL = thumbnail.thumbnailURL
                self.isThumbnailLoaded = false
                self.viewModel.meeting.service.ccm.downloadEncryptedImage(
                    use: thumbnail.thumbnailURL,
                    to: self.sharingDocumentThumbnail,
                    imageSize: self.preferredThumbnailSize ?? CGSize(width: self.view.bounds.width, height: self.view.bounds.height),
                    thumbnailInfo: [
                        "nonce": thumbnail.nonce,
                        "secret": thumbnail.decryptKey,
                        "type": thumbnail.cipherType.rawValue
                    ],
                    requireFullImage: document?.shareSubType == .ccmPpt,
                    completion: { [weak self] (image, _) in
                        Logger.ui.debug("floating window request MS thumbnail image completed, image is nil: \(image == nil)")
                        guard let self = self else { return }
                        if self.currentSharingThumbnailURL == thumbnail.thumbnailURL {
                            self.isThumbnailLoaded = image != nil
                            self.sharingDefaultThumbnail.isHidden = (image != nil)
                            self.sharingDocumentThumbnail.isHidden = (image == nil)
                        }
                    })

            })
            .disposed(by: self.disposeBag)
        setupWatermark()
    }

    private func setupWatermark() {
        let combined = Observable.combineLatest(
            viewModel.service.larkUtil.getVCShareZoneWatermarkView(),
            viewModel.shareWatermark.showWatermarkRelay.asObservable().distinctUntilChanged())
        combined.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (view, showWatermark) in
                guard let self = self else { return }
                self.watermarkView?.removeFromSuperview()
                guard showWatermark, let view = view else {
                    self.watermarkView = nil
                    return
                }
                view.frame = self.view.bounds
                view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                self.view.addSubview(view)
                view.layer.zPosition = .greatestFiniteMagnitude
                self.watermarkView = view
            }).disposed(by: self.disposeBag)
    }

}
