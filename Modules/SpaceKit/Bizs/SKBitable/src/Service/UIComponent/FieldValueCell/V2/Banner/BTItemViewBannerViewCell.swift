//
//  BTItemViewBannerViewCell.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/8/3.
//

import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignFont
import SKUIKit
import RxSwift
import SKCommon
import UniverseDesignIcon
import UniverseDesignProgressView
import Kingfisher

final class BTItemViewBannerViewCell: UICollectionViewCell {
    static private let defaultImageWidth = 1280

    private let thumbnailProvider = BTAttachmentThumbnailProvider()

    private var disposeBag = DisposeBag()

    // 用来避免图片下拉放大时不会左右超出遮挡其他 cell
    private lazy var contentWrapper = UIView().construct { it in
        it.layer.masksToBounds = true
        it.backgroundColor = UDColor.bgBodyOverlay
    }

    lazy var bannnerContentView = UIView().construct { it in
        it.backgroundColor = .clear
    }

    private lazy var backgroundContentView = UIView()

    private lazy var backgroundImageView = UIImageView().construct { it in
        it.contentMode = .scaleAspectFill
    }

    private lazy var blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .regular)
        let view = UIVisualEffectView(effect: blurEffect)
        view.contentView.backgroundColor = .clear
        return view
    }()

    private lazy var fileIcon = UIImageView()

    private lazy var imageView = UIImageView().construct { it in
        it.contentMode = .scaleAspectFit
    }

    private lazy var loadingView = UIImageView().construct { it in
        let loadingIcon = UDIcon.getIconByKey(
            .loadingOutlined,
            iconColor: UIColor.ud.iconDisabled,
            size: CGSize(width: 52, height: 52)
        )
        it.image = loadingIcon
        it.isHidden = true
    }

    private static let videoPlayIconSize: CGFloat = 64
    private lazy var videoPlayIcon = UIView().construct { it in
        it.layer.masksToBounds = true
        it.layer.cornerRadius = Self.videoPlayIconSize * 0.5
        it.isHidden = true
        it.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.7)
    }

    private var currentData: BTAttachmentModel? = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        contentView.addSubview(contentWrapper)
        contentWrapper.addSubview(bannnerContentView)

        bannnerContentView.addSubview(backgroundContentView)
        backgroundContentView.addSubview(backgroundImageView)
        backgroundContentView.addSubview(blurView)

        bannnerContentView.addSubview(imageView)
        contentWrapper.addSubview(loadingView)
        imageView.addSubview(fileIcon)
        imageView.addSubview(videoPlayIcon)
        setupVideoBtn()

        contentWrapper.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(BTItemViewTiTleCell.cornerRadii)
            make.height.equalTo(contentWrapper.snp.width).multipliedBy(2)
        }
        bannnerContentView.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
        backgroundContentView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(contentView)
            make.bottom.equalTo(contentWrapper)
        }
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        fileIcon.snp.makeConstraints { it in
            it.centerX.equalToSuperview()
            it.centerY.equalToSuperview().offset(BTItemViewTiTleCell.cornerRadii/2)
            it.width.height.equalTo(80)
        }
        imageView.snp.makeConstraints { (make) in
            make.edges.equalTo(contentView)
        }
        loadingView.snp.makeConstraints { make in
            make.center.equalTo(contentView)
            make.width.height.equalTo(52)
        }
        videoPlayIcon.snp.makeConstraints { it in
            it.centerX.equalToSuperview()
            it.centerY.equalToSuperview().offset(BTItemViewTiTleCell.cornerRadii/2)
            it.width.height.equalTo(64)
        }
    }

    private func setupVideoBtn() {
        let image = UDIcon.playFilled.ud.resized(to: CGSize(width: 24, height: 24)).ud.withTintColor(UDColor.staticWhite)
        let imageView = UIImageView(image: image)
        videoPlayIcon.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.center.equalToSuperview()
        }
    }

    func update(image: UIImage) {
        imageView.image = image
        backgroundImageView.image = image
    }

    private func startAnimation() {
        DispatchQueue.main.async {
            self.loadingView.isHidden = false
            BTUtil.startRotationAnimation(view: self.loadingView)
            self.fileIcon.isHidden = true
            self.videoPlayIcon.isHidden = true
        }
    }

    private func stopAnimation(success: Bool, showFileIcon: Bool) {
        DispatchQueue.main.async {
            self.loadingView.isHidden = true
            BTUtil.stopRotationAnimation(view: self.loadingView)
            self.fileIcon.isHidden = !showFileIcon
            if showFileIcon {
                self.fileIcon.image = self.currentData?.iconImage
            }
            self.videoPlayIcon.isHidden = self.currentData?.fileType.isVideo == false
            if !success {
                self.contentWrapper.backgroundColor = self.currentData?.backgroundColor ?? UIColor.ud.primaryPri100
            } else {
                self.contentWrapper.backgroundColor = UDColor.bgBodyOverlay
            }
        }
    }
}

extension BTItemViewBannerViewCell {
    func load(data: BTAttachmentModel, localStorageURL: URL?) {
        currentData = data
        stopAnimation(success: false, showFileIcon: false)
        clearImage()
        videoPlayIcon.isHidden = !data.fileType.isVideo
        DispatchQueue.main.async {
            self.contentWrapper.backgroundColor = UDColor.bgBodyOverlay
        }
        DocsLogger.btInfo("[DATA] attachment thumbnail start load")
        guard BTAttachmentField.AttachmentCell.hasFilePreviewPermission(token: data.attachmentToken) else {
            // 没有文件预览权限，不加载预览图
            DocsLogger.btInfo("[DATA] attachment thumbnail no permission")
            stopAnimation(success: false, showFileIcon: true)
            return
        }
        var imageWidth = Self.defaultImageWidth
        // size 大于附件大小, 会导致生成失败
        if let width = data.width,
           let height = data.height {
            let maxWidth = max(width, height)
            imageWidth = min(maxWidth, imageWidth)
        }
        let imageSize = CGSize(width: imageWidth, height: imageWidth)

        DocsLogger.btInfo("[DATA] attachment thumbnail start fetch \(imageWidth)")
        if let localStorageURL = localStorageURL {
            startAnimation()
            let provider = LocalFileImageDataProvider(fileURL: localStorageURL)
            let processor = DownsamplingImageProcessor(size: imageSize)
            imageView.kf.setImage(with: provider, options: [.processor(processor)], completionHandler: { [weak self] result in
                if let imageResult = try? result.get() {
                    self?.setImage(imageResult.image)
                    self?.stopAnimation(success: true, showFileIcon: false)
                    DocsLogger.btInfo("[DATA] attachment thumbnail start fetch success from localStorageURL")
                } else {
                    DocsLogger.btError("[DATA] attachment kf.setImage fail")
                    self?.stopAnimation(success: false, showFileIcon: true)
                }
            })
            return
        }
        if data.prefersThumbnail {
            startAnimation()
            thumbnailProvider.fetchThumbnail(info: data, resumeBag: disposeBag, size: imageSize) { [weak self] thumbnailImage, token, error in
                if let error = error {
                    self?.stopAnimation(success: false, showFileIcon: true)
                    DocsLogger.btError("[DATA] attachment thumbnail error: \((error as NSError).localizedDescription)")
                } else if let thumbnailImage = thumbnailImage, data.attachmentToken == token { // token 校验，时序问题
                    self?.setImage(thumbnailImage)
                    self?.stopAnimation(success: true, showFileIcon: false)
                    DocsLogger.btInfo("[DATA] attachment thumbnail start fetch success from drive")
                } else {
                    DocsLogger.btError("[DATA] attachment thumbnail fail: error nil，image nil")
                    self?.stopAnimation(success: false, showFileIcon: true)
                }
            }
        } else {
            stopAnimation(success: false, showFileIcon: true)
        }
    }

    private func setImage(_ image: UIImage) {
        DispatchQueue.main.async {
            self.blurView.isHidden = false
            self.imageView.image = image
            self.backgroundImageView.image = image
        }
    }

    private func clearImage() {
        DispatchQueue.main.async {
            self.blurView.isHidden = true
            self.imageView.image = nil
            self.backgroundImageView.image = nil
            self.fileIcon.image = nil
        }
    }
}
