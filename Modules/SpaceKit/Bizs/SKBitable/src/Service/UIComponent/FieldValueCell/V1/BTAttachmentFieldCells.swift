//
// Created by duanxiaochen.7 on 2021/7/6.
// Affiliated with SKBitable.
//
// Description:

import SKFoundation
import SKCommon
import LarkTag
import SKResource
import SKBrowser
import RxSwift
import UniverseDesignProgressView
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignColor
import Kingfisher
import SKInfra
import SpaceInterface

// MARK: - Uploaded Attachment Cell

extension BTAttachmentField {
    // MARK: AttachmentCell
    final class AttachmentCell: UICollectionViewCell {

        var data: BTAttachmentModel?

        var waitingUploadData: PendingAttachment?

        weak var deleter: BTAttachmentDeleter?

        private var disposeBag = DisposeBag()

        private lazy var thumbnail = UIImageView().construct { it in
            it.contentMode = .scaleAspectFill
        }

        private lazy var defaultView = UIView()

        private lazy var fileIcon = UIImageView()

        private lazy var videoPlayIcon = UIImageView(image: UDIcon.getIconByKey(.playRoundColorful, size: CGSize(width: 40, height: 40)))

        override init(frame: CGRect) {
            super.init(frame: frame)
            contentView.layer.cornerRadius = 4
            contentView.layer.masksToBounds = true
            NotificationCenter.default.addObserver(self, selector: #selector(menuWillHide), name: UIMenuController.willHideMenuNotification, object: nil)
            setupLayout()
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setupLayout() {
            contentView.addSubview(defaultView)
            defaultView.addSubview(fileIcon)
            contentView.addSubview(thumbnail)
            thumbnail.isHidden = true
            contentView.addSubview(videoPlayIcon)
            videoPlayIcon.isHidden = true

            defaultView.snp.makeConstraints { it in
                it.edges.equalToSuperview()
            }
            fileIcon.snp.makeConstraints { it in
                it.center.equalToSuperview()
                it.width.height.equalTo(48)
            }
            thumbnail.snp.makeConstraints { it in
                it.edges.equalToSuperview()
            }
            videoPlayIcon.snp.makeConstraints { it in
                it.center.equalToSuperview()
                it.width.height.equalTo(40)
            }
        }
        
        /// 文件预览接入条件访问控制 https://bytedance.feishu.cn/docx/FghndycFjo22qbxWHGQcLdIanKg
        static func hasFilePreviewPermission(token: String?) -> Bool {
            guard UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation else {
                return legacyHasFilePreviewPermission(token: token)
            }
            guard let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self) else {
                DocsLogger.btError("hasFilePreviewPermission with exception, permissionSDK is nil")
                return false
            }
            let request = PermissionRequest(entity: .ccm(token: token ?? "",
                                                         type: .file),
                                            operation: .view,
                                            bizDomain: .ccm)
            return permissionSDK.validate(request: request).allow
        }

        @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
        private static func legacyHasFilePreviewPermission(token: String?) -> Bool {
            let result = CCMSecurityPolicyService.syncValidate(
                entityOperate: .ccmFilePreView,
                fileBizDomain: .ccm,
                docType: .file,
                token: token
            )
            return result.allow
        }

        func load(data: BTAttachmentModel, thumbnailProvider: BTAttachmentThumbnailProvider, localStorageURL: URL?) {
            self.data = data
            disposeBag = DisposeBag()
            defaultView.backgroundColor = data.backgroundColor
            fileIcon.image = data.iconImage
            videoPlayIcon.isHidden = !data.fileType.isVideo
            showBorder(false, isSelected: false)
            guard Self.hasFilePreviewPermission(token: data.attachmentToken) else {
                // 没有文件预览权限，不加载预览图
                return
            }
            if let localStorageURL = localStorageURL {
                let provider = LocalFileImageDataProvider(fileURL: localStorageURL)
                let processor = DownsamplingImageProcessor(size: CGSize(width: 360, height: 360))
                thumbnail.kf.setImage(with: provider, options: [.processor(processor)], completionHandler: { [weak self] result in
                    if let imageResult = try? result.get() {
                        self?.setThumbnailImage(imageResult.image)
                    }
                })
                return
            }
            if data.prefersThumbnail {
                thumbnailProvider.fetchThumbnail(info: data, resumeBag: disposeBag) { [weak self] thumbnailImage, token, error in
                    if let error = error {
                        DocsLogger.btError("[DATA] attachment thumbnail error: \((error as NSError).localizedDescription)")
                    } else if let thumbnailImage = thumbnailImage, data.attachmentToken == token { // token 校验，时序问题
                        DispatchQueue.main.async {
                            self?.setThumbnailImage(thumbnailImage)
                        }
                    }
                }
            }
        }

        func load(data: PendingAttachment) {
            DocsLogger.info("AttachmentCell data PendingAttachment")
            waitingUploadData = data
            let fileType = data.mediaInfo.driveType
            defaultView.backgroundColor = fileType.imageColor.background
            fileIcon.image = fileType.squareImage
            videoPlayIcon.isHidden = !fileType.isVideo
            showBorder(false, isSelected: false)
            guard Self.hasFilePreviewPermission(token: nil) else {
                // 没有文件预览权限，不加载预览图
                return
            }
            if !fileType.isVideo {
                let thumbnailLimitSize = 100_000_000
                if data.mediaInfo.byteSize > thumbnailLimitSize {
                    // 设置个大约 一百兆 的内存限制，避免 OOM，.kf.setImage 会把数据全量导入到内存
                    DocsLogger.warning("cancel preview size is \(data.mediaInfo.byteSize)")
                    return
                }
                let provider = LocalFileImageDataProvider(fileURL: data.mediaInfo.storageURL)
                let processor = DownsamplingImageProcessor(size: CGSize(width: 360, height: 360))
                thumbnail.kf.setImage(with: provider, options: [.processor(processor)], completionHandler: { [weak self] result in
                    if let imageResult = try? result.get() {
                        self?.setThumbnailImage(imageResult.image)
                    }
                })
            } else {
                if let image = data.mediaInfo.previewImage {
                    setThumbnailImage(image)
                }
            }
        }

        private func setThumbnailImage(_ image: UIImage) {
            thumbnail.image = image
            thumbnail.isHidden = false
            defaultView.isHidden = true
            showBorder(true, isSelected: false)
        }

        func showBorder(_ show: Bool, isSelected selected: Bool) {
            if show {
                contentView.layer.ud.setBorderColor(selected ? UDColor.primaryContentDefault : UDColor.lineBorderCard)
                contentView.layer.borderWidth = 1
            } else {
                contentView.layer.ud.setBorderColor(.clear)
                contentView.layer.borderWidth = 0
            }
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            data = nil
            waitingUploadData = nil
            thumbnail.image = nil
            thumbnail.isHidden = true
            defaultView.isHidden = false
        }

        // In order to make editing menu work, the cell (rather than collectionView) must implement the action's selector!
        @objc
        func deleteAttachment() {
            if let data = data {
                deleter?.deleteAttachment(data: data)
            }
            if let data = waitingUploadData {
                deleter?.deleteAttachment(data: data)
            }
        }

        @objc
        func menuWillHide() {
            showBorder(!thumbnail.isHidden, isSelected: false)
            deleter?.clearState()
        }
    }
}


// MARK: - Uploading Attachment Cell

extension BTAttachmentField {

    final class UploadingCell: UICollectionViewCell {

        private lazy var defaultView = UIView()

        private lazy var fileIcon = UIImageView()

        private lazy var dimmingMaskView = UIView().construct { it in
            it.backgroundColor = UDColor.bgMask
        }

        private lazy var progressBar = UDProgressView(config: UDProgressViewUIConfig(type: .linear,
                                                                                     barMetrics: .default,
                                                                                     layoutDirection: .horizontal,
                                                                                     showValue: false))

        weak var deleter: BTAttachmentDeleter?
                
        var info: BTMediaUploadInfo?
                
        private lazy var cancelUploadingButton = UIButton().construct { it in
            it.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.6)
            it.layer.cornerRadius = 9
            it.addTarget(self, action: #selector(cancelUploadingAttachment), for: .touchUpInside)
        }
        private var cancelUploadingIcon = UIImageView().construct { it in
            it.contentMode = .scaleAspectFit
            it.image = UDIcon.closeBoldOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.9))
        }
                
        private lazy var uploadingPercent = UILabel().construct { it in
            it.textAlignment = .center
            it.textColor = .white
            it.font = UIFont.systemFont(ofSize: 12)
        }
        override init(frame: CGRect) {
            super.init(frame: frame)
            contentView.layer.cornerRadius = 4
            contentView.layer.masksToBounds = true
            setupLayout()
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setupLayout() {
            contentView.addSubview(defaultView)
            defaultView.addSubview(fileIcon)
            contentView.addSubview(dimmingMaskView)
            contentView.addSubview(progressBar)
            contentView.addSubview(uploadingPercent)
            contentView.addSubview(cancelUploadingButton)
            cancelUploadingButton.addSubview(cancelUploadingIcon)
            
            defaultView.snp.makeConstraints { it in
                it.edges.equalToSuperview()
            }
            fileIcon.snp.makeConstraints { it in
                it.center.equalToSuperview()
                it.width.height.equalTo(48)
            }
            dimmingMaskView.snp.makeConstraints { it in
                it.edges.equalToSuperview()
            }
            progressBar.snp.makeConstraints { it in
                it.center.equalToSuperview()
                it.leading.trailing.equalToSuperview().inset(12)
            }
            cancelUploadingButton.snp.makeConstraints {it in
                it.width.height.equalTo(18)
                it.top.equalTo(dimmingMaskView.snp.top).offset(5)
                it.right.equalTo(dimmingMaskView.snp.right).offset(-5)
            }
            uploadingPercent.snp.makeConstraints { it in
                it.centerX.equalToSuperview()
                it.top.equalTo(progressBar.snp.bottom).offset(4)
            }
            cancelUploadingIcon.snp.makeConstraints { it in
                it.width.height.equalTo(8)
                it.centerY.equalToSuperview()
                it.centerX.equalToSuperview()
            }
        }

        func feed(info: BTMediaUploadInfo) {
            DocsLogger.btInfo(
                """
                [DATA] uploading job: \(info.jobKey),
                token '\(DocsTracker.encrypt(id: info.fileToken))',
                progress '\(info.progress)',
                status '\(info.status)'
                """
            )
            self.info = info
            let data = info.attachmentModel
            defaultView.backgroundColor = data.backgroundColor
            fileIcon.image = data.iconImage
            var uploadingProgress: Int
            if info.progress <= 0.01 {
                uploadingProgress = 1
            } else {
                let process = min(floor(info.progress * 100), 100)
                guard !process.isNaN, process.isFinite else { 
                    DocsLogger.error("UploadingCell uploading process: \(process)")
                    return 
                }
                uploadingProgress = Int(process)
            }
            progressBar.setProgress(CGFloat(uploadingProgress) / 100, animated: false)
            uploadingPercent.text = "\(uploadingProgress)%"
        }
        
        @objc
        func cancelUploadingAttachment() {
            if let info = info {
                deleter?.cancelAttachment(data: info)
            }
        }
    }
}
