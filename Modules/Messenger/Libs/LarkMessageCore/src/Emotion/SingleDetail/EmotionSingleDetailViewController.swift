//
//  EmotionSingleDetailViewController.swift
//  LarkUIKit
//
//  Created by huangjianming on 2019/8/6.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import EENavigator
import RxSwift
import LarkModel
import ByteWebImage
import LarkAlertController
import LarkMessengerInterface
import RustPB

public final class EmotionSingleDetailViewController: BaseUIViewController, UIScrollViewDelegate {
    // MARK: - 成员变量
    var disposeBag = DisposeBag()
    var viewModel: EmotionSingleDetailViewModel

    lazy var imageView: ByteImageView = {
        var imageView = ByteImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var stateView: EmotionStateView = {
        var stateView = EmotionStateView()
        stateView.setStyle(style: .full)
        return stateView
    }()

    lazy var imageViewContainer: UIView = {
        let imageViewContainer = UIView()
        imageViewContainer.isUserInteractionEnabled = false
        return imageViewContainer
    }()

    lazy var emotionNameLabel: UILabel = {
        let emotionNameLabel = UILabel()
        emotionNameLabel.font = UIFont.systemFont(ofSize: 14)
        return emotionNameLabel
    }()

    lazy var containerScrollView: UIScrollView = {
        let containerScrollView = UIScrollView()
        containerScrollView.minimumZoomScale = 1.0
        containerScrollView.maximumZoomScale = 1.0

        return containerScrollView
    }()

    var bottomContainer: UIView = {
        let bottomContainer = UIView()
        bottomContainer.backgroundColor = UIColor.ud.bgBody
        bottomContainer.layer.shadowOpacity = 0.03
        bottomContainer.layer.shadowRadius = 4
        bottomContainer.isHidden = true
        return bottomContainer
    }()

    var avatorImageView: UIImageView = {
        let avatorImageView = UIImageView()
        avatorImageView.contentMode = .scaleAspectFill
        return avatorImageView
    }()

    var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = UIColor.ud.textTitle
        return titleLabel
    }()

    lazy var subTitleLabel: UILabel = {
        let subTitleLabel = UILabel()
        subTitleLabel.font = UIFont.systemFont(ofSize: 14)
        subTitleLabel.textColor = UIColor.ud.textCaption
        return subTitleLabel
    }()

    lazy var loadingView: UIImageView = {
        let loadingView = UIImageView(image: BundleResources.imageLoading)
        return loadingView
    }()

    var bottomContainerHeight: CGFloat = 80
    var avatorHeight: CGFloat = 48

    // MARK: - 生命周期
    public init(viewModel: EmotionSingleDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBody
        setupNavibar()
        setupSubviews()
        fillStickerInfo(sticker: self.viewModel.sticker)
        layout()
        self.viewModel.dataDriver.drive(onNext: { [weak self] (_) in
            self?.reloadData()
        }).disposed(by: self.disposeBag)
        self.viewModel.fetchData()
    }

    // MARK: - 内部方法
    func setupNavibar() {
        addBackItem()
    }

    func reloadData() {
        guard let stickerSet = self.viewModel.stickerSet, self.checkStickerSetValid() else {
            self.removeRightItem()
            self.setBottomContainerViewHidden(isHidden: true)
            return
        }
        self.addRightItem()
        self.setBottomContainerViewHidden(isHidden: false)
        self.fillstickerSetInfo(stickerSet: stickerSet)
    }

    func checkStickerSetValid() -> Bool {
        guard let stickerSet = self.viewModel.stickerSet else {
            return false
        }
        return !stickerSet.title.isEmpty || !stickerSet.description_p.isEmpty || !stickerSet.preview.key.isEmpty
    }

    func setBottomContainerViewHidden(isHidden: Bool) {
        self.bottomContainer.isHidden = isHidden
    }

    /// show loading animation
    private func showDownloadProgressLayer() {
        self.imageViewContainer.addSubview(loadingView)
        self.loadingView.isHidden = false
        loadingView.snp.makeConstraints({ (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(30)
        })
        loadingView.lu.addRotateAnimation()
    }

    private func hideDownloadProgressLayer() {
        self.loadingView.isHidden = true
    }

    func addRightItem() {
        let barItem = LKBarButtonItem(image: Resources.emotionShopShareIcon)
        barItem.button.addTarget(self, action: #selector(shareBtnTapped), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = barItem
    }

    func removeRightItem() {
        self.navigationItem.rightBarButtonItem = nil
    }

    func setupSubviews() {
        self.setupImageViewContent()
        setupBottomContent()
    }

    func fillstickerSetInfo(stickerSet: RustPB.Im_V1_StickerSet) {

        self.titleLabel.text = stickerSet.title
        self.subTitleLabel.text = stickerSet.description_p
        self.avatorImageView.bt.setLarkImage(with: .sticker(key: stickerSet.cover.key,
                                                            stickerSetID: stickerSet.stickerSetID),
                                             placeholder: BundleResources.emotionPlaceholderIcon,
                                             trackStart: {
                                                return TrackInfo(scene: .Chat, fromType: .sticker)
                                             })
        self.stateView.setState(state: self.viewModel.getDownloadState(stickerSet: stickerSet))

        //产品要求已下载时按钮不可点击,把事件透到superview,因此把stateView的isUserInteractionEnabled改为false
        self.viewModel.getDownloadState(stickerSet: stickerSet).subscribe(onNext: { [weak self] (state) in
            if state.hasAdd {
                switch state.downloadState {
                case .downloaded:
                    self?.stateView.isUserInteractionEnabled = false
                default:
                    break
                }
            } else {
                self?.stateView.isUserInteractionEnabled = true
            }
        }).disposed(by: self.disposeBag)

        self.stateView.setHasPaid(hasPaid: stickerSet.hasPaid_p)
        self.stateView.addBtn.rx.tap.subscribe { [weak self] ( _ ) in
            if stickerSet.hasPaid_p {
                self?.viewModel.addEmotionPackage(stickerSet: stickerSet)
                StickerTracker.trackStickerSetAdded(from: .emotionSingleDetail, stickerID: stickerSet.stickerSetID, stickersCount: stickerSet.stickers.count)
            } else {
                self?.showUpgradeAlert()
            }
        }.disposed(by: disposeBag)
    }

    func fillStickerInfo(sticker: RustPB.Im_V1_Sticker) {
        self.showDownloadProgressLayer()
        self.imageView.bt.setLarkImage(with: .sticker(key: sticker.image.origin.key,
                                                      stickerSetID: sticker.stickerSetID),
                                       trackStart: {
                                        return TrackInfo(scene: .Chat, fromType: .sticker)
                                       },
                                       completion: { [weak self] _ in
                                        guard let self = self else { return }
                                        self.hideDownloadProgressLayer()
                                       })
        self.emotionNameLabel.text = sticker.description_p
    }

    func setupImageViewContent() {
        self.containerScrollView.delegate = self
        self.containerScrollView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height - bottomContainerHeight)
        self.view.addSubview(self.containerScrollView)
        self.containerScrollView.bouncesZoom = false

        self.view.addSubview(self.imageViewContainer)

        self.imageViewContainer.addSubview(emotionNameLabel)
        self.emotionNameLabel.sizeToFit()

        //imageView
        self.imageView.frame = CGRect(x: 0, y: 0, width: 180, height: 180)
        self.imageViewContainer.addSubview(imageView)
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.imageViewContainer.frame = CGRect(x: 0, y: 0, width: 180, height: 212)
        self.imageViewContainer.center = CGPoint(x: self.view.frame.size.width / 2, y: self.view.frame.size.height / 2 - 64)
        containerScrollView.contentSize = self.imageViewContainer.frame.size
    }

    func setupBottomContent() {
        //bottomContainer
        self.view.addSubview(self.bottomContainer)

        //avatorImageView
        self.avatorImageView.layer.cornerRadius = avatorHeight * 0.5
        self.avatorImageView.layer.masksToBounds = true
        self.bottomContainer.addSubview(self.avatorImageView)

        //titleLabel
        self.bottomContainer.addSubview(self.titleLabel)

        //subTitleLabel
        self.bottomContainer.addSubview(self.subTitleLabel)

        //stateView
        self.bottomContainer.addSubview(self.stateView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(bottomViewClick))
        self.bottomContainer.addGestureRecognizer(tapGesture)
    }

    func showUpgradeAlert() {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_Chat_StickerPackBuyToast, font: .systemFont(ofSize: 17))
        alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Chat_StickerPackKnow)
        self.viewModel.navigator.present(alertController, from: self)
    }

    // MARK: - 布局代码
    func layout() {
        //bottomContainer
        self.bottomContainer.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(bottomContainerHeight)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        //avatorImageView
        self.avatorImageView.snp.makeConstraints { (make) in
            make.left.top.equalTo(16)
            make.width.height.equalTo(avatorHeight)
        }

        self.stateView.snp.makeConstraints { (make) in
            make.right.equalTo(-16)
            make.top.equalTo(26)
            make.height.greaterThanOrEqualTo(28)
            make.width.greaterThanOrEqualTo(60)
        }

        self.emotionNameLabel.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        //titleLabel
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.avatorImageView.snp.right).offset(20)
            make.top.equalTo(18)
            make.right.equalTo(-100)
        }

        //subTitleLabel
        self.subTitleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.titleLabel.snp.left)
            make.top.equalTo(42)
            make.right.equalTo(-100)
        }
    }

    // MARK: - 点击事件
    @objc
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    @objc
    func bottomViewClick() {
        if let stickerSet = self.viewModel.stickerSet {
            let body = EmotionShopDetailBody(stickerSet: stickerSet)
            self.viewModel.navigator.push(body: body, from: self)
        } else {
            let body = EmotionShopDetailWithSetIDBody(stickerSetID: self.viewModel.stickerSetID)
            self.viewModel.navigator.push(body: body, from: self)
        }
    }

    @objc
    private func shareBtnTapped() {
        //右上角分享按钮点击
        let forwardbody = SendSingleEmotionBody(sticker: self.viewModel.sticker, message: self.viewModel.message)
        self.viewModel.navigator.present(
            body: forwardbody,
            from: self,
            prepare: { $0.modalPresentationStyle = .fullScreen })
    }
    // MARK: - UIScrollViewDelegate
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
}
