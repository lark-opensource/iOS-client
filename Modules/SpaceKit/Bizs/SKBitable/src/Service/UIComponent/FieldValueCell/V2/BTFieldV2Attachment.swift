//
// Created by duanxiaochen.7 on 2020/1/29.
// Affiliated with SKBitable.
//
// Description:

import SKFoundation
import SKCommon
import LarkTag
import SKResource
import SKBrowser
import RxSwift
import RxDataSources
import UniverseDesignProgressView
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignFont
import Kingfisher
import SKInfra
import SpaceInterface

struct BTFieldUIDataAttachment: BTFieldUIData {
    struct Const {
        static let itemSize: CGFloat = 40.0
        static let itemSpace: CGFloat = 12.0
        static let itemRadius: CGFloat = 4.0
        
        static let fileIconSize: CGFloat = 28.0
    }
}

class AttachmentFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let layoutAttributes = super.layoutAttributesForElements(in: rect)

        var leftMargin: CGFloat = sectionInset.left
        
        for attributes in layoutAttributes ?? [] {
            if attributes.representedElementCategory == .cell {
                let origin = attributes.frame.origin
                
                if origin.x == sectionInset.left {
                    leftMargin = sectionInset.left
                }
                
                attributes.frame.origin.x = leftMargin
                leftMargin += attributes.frame.width + minimumInteritemSpacing
            }
        }
        
        return layoutAttributes
    }
}


final class BTFieldV2Attachment: BTFieldV2Base, BTFieldAttachmentCellProtocol, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var sourceAddView: UIView {
        return editBtn
    }
    
    var sourceAddRect: CGRect {
        return editBtn.bounds
    }
    
    var onlyCamera: Bool = false
    private lazy var flowLayout = AttachmentFlowLayout().construct { it in
        it.minimumLineSpacing = BTFieldUIDataAttachment.Const.itemSpace
        it.minimumInteritemSpacing = BTFieldUIDataAttachment.Const.itemSpace
    }

    // MARK: attachment views
    private lazy var attachmentView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout).construct { it in
        it.delegate = self
        it.dataSource = self
        it.backgroundColor = .clear
        it.insetsLayoutMarginsFromSafeArea = false
        it.contentInsetAdjustmentBehavior = .never
        it.bounces = false
        it.isScrollEnabled = UserScopeNoChangeFG.ZJ.btCellLargeContentOpt
        it.delaysContentTouches = false
        it.showsVerticalScrollIndicator = false
        it.showsHorizontalScrollIndicator = false
        it.register(AttachmentCell.self, forCellWithReuseIdentifier: AttachmentCell.reuseIdentifier)
        it.register(UploadingCell.self, forCellWithReuseIdentifier: UploadingCell.reuseIdentifier)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onAttachmentCellOutsideClick(_:)))
        tap.delegate = self
        it.addGestureRecognizer(tap)
    }

    // MARK: attachment data
    private let thumbnailProvider = BTAttachmentThumbnailProvider()

    var localStorageURLs: [String: URL] = [:]

    private var latestSnapshot = BTAttachment(fieldID: "", attachments: [])

    // MARK: configurations
    var showingMenuIndexPath: IndexPath?
    
    override func subviewsInit() {
        super.subviewsInit()
        containerView.addSubview(attachmentView)
        attachmentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        let oldFieldID = fieldModel.fieldID
        let oldRecordID = fieldModel.recordID
        super.loadModel(model, layout: layout)
        reloadData(fieldChange: fieldModel.fieldID != oldFieldID || fieldModel.recordID != oldRecordID)
    }
    
    private func reloadData(fieldChange: Bool) {
        onlyCamera = fieldModel.onlyCamera
        localStorageURLs = fieldModel.localStorageURLs
        let newAttachments = assembleAttachments(from: fieldModel)
        if attachmentView.window != nil, !fieldChange {
            diffModel(oldModel: latestSnapshot, newModel: BTAttachment(fieldID: fieldID, attachments: newAttachments))
        } else {
            latestSnapshot = BTAttachment(fieldID: fieldModel.fieldID, attachments: newAttachments)
            attachmentView.reloadData()
        }
    }

    func diffModel(oldModel: BTAttachment, newModel: BTAttachment) {
        var differences = [Changeset<BTAttachment>]()
        do {
            differences = try Diff.differencesForSectionedView(initialSections: [oldModel], finalSections: [newModel])
        } catch {
            DocsLogger.btError("[DIFF] [Attachment] diffing attachment model failed with error \(error.localizedDescription)")
        }

        guard !differences.isEmpty else { return }

        UIView.performWithoutAnimation {
            for difference in differences {
                guard let finalSectionForThisStep = difference.finalSections.first else {
                    latestSnapshot = newModel
                    attachmentView.reloadData()
                    return
                }
                if latestSnapshot.items.isEmpty || finalSectionForThisStep.items.isEmpty {
                    latestSnapshot = finalSectionForThisStep
                    attachmentView.reloadData()
                } else {
                    attachmentView.performBatchUpdates {
                        latestSnapshot = finalSectionForThisStep

                        deleteItems(at: difference.deletedItems.map { IndexPath(item: $0.itemIndex, section: $0.sectionIndex) })
                        insertItems(at: difference.insertedItems.map { IndexPath(item: $0.itemIndex, section: $0.sectionIndex) })
                        updateItems(at: difference.updatedItems.map { IndexPath(item: $0.itemIndex, section: $0.sectionIndex) })
                        difference.movedItems.forEach { (from: ItemPath, to: ItemPath) in
                            moveItem(from: IndexPath(item: from.itemIndex, section: from.sectionIndex),
                                     to: IndexPath(item: to.itemIndex, section: to.sectionIndex))
                        }
                    }
                }
            }
        }
    }

    private func assembleAttachments(from model: BTFieldModel) -> [BTAttachmentType] {
        var newAttachments: [BTAttachmentType] = []
        let uploadingAttachments = fieldModel.uploadingAttachments
        DocsLogger.btInfo("[DATA] \(model.recordID) \(fieldID) uploading attachment data count: \(uploadingAttachments.count)")
        uploadingAttachments.forEach { info in
            newAttachments.append(.uploading(info))
        }
        let existingAttachments = fieldModel.attachmentValue
        DocsLogger.btInfo("[DATA] \(model.recordID) \(fieldID) existing attachment data count: \(existingAttachments.count)")
        existingAttachments.forEach { model in
            newAttachments.append(.existing(model))
        }
        let pendingAttachments = fieldModel.pendingAttachments
        DocsLogger.btInfo("[DATA] \(model.recordID) \(fieldID) pending attachment data count: \(pendingAttachments.count)")
        pendingAttachments.forEach { pa in
            newAttachments.append(.pending(pa))
        }
        return newAttachments
    }
    
    @objc
    override func onFieldEditBtnClick(_ sender: UIButton) {
        uploadAttachment()
    }
    
    @objc
    override func onFieldValueEnlargeAreaClick(_ sender: UITapGestureRecognizer) {
        uploadAttachment()
    }
    
    @objc
    private func onAttachmentCellOutsideClick(_ sender: UITapGestureRecognizer) {
        uploadAttachment()
    }

    func panelDidStartEditing() {
        fieldModel.update(isEditing: true)
        updateEditingStyle()
        delegate?.panelDidStartEditingField(self, scrollPosition: .bottom)
    }

    private func uploadAttachment() {
        if fieldModel.editable {
            delegate?.didClickAddAttachment(inField: self)
        } else {
            showUneditableToast()
        }
    }

    func stopEditing() {
        fieldModel.update(isEditing: false)
        updateEditingStyle()
        reloadData(fieldChange: false)
        delegate?.stopEditingField(self, scrollPosition: nil)
    }


    func deleteItems(at indexPaths: [IndexPath]) {
        guard !indexPaths.isEmpty else { return }
        DocsLogger.btInfo("[DIFF] [Attachment] delete attachment \(indexPaths), current items count: \(latestSnapshot.items.count)")
        attachmentView.deleteItems(at: indexPaths)
    }

    func insertItems(at indexPaths: [IndexPath]) {
        guard !indexPaths.isEmpty else { return }
        DocsLogger.btInfo("[DIFF] [Attachment] insert attachment \(indexPaths), current items count: \(latestSnapshot.items.count)")
        attachmentView.insertItems(at: indexPaths)
    }

    func updateItems(at indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let index = indexPath.item
            guard 0 <= index, index < latestSnapshot.items.count else {
                spaceAssertionFailure("[DIFF] [Attachment] index out of bounds")
                return
            }
            DocsLogger.btInfo("[DIFF] [Attachment] update attachment item \(index), current items count: \(latestSnapshot.items.count)")
            let attachment = latestSnapshot.items[index]
            if attachmentView.indexPathsForVisibleItems.contains(indexPath), let cell = attachmentView.cellForItem(at: indexPath) {
                switch attachment {
                case .pending(let pendingAttachment):
                    if let cell = cell as? AttachmentCell {
                        cell.deleter = self
                        cell.load(data: pendingAttachment)
                    }

                case .uploading(let uploadingAttachment):
                    if let cell = cell as? UploadingCell {
                        cell.deleter = self
                        cell.feed(info: uploadingAttachment)
                    }

                case .existing(let existingAttachment):
                    if let cell = cell as? AttachmentCell {
                        cell.deleter = self
                        cell.load(data: existingAttachment,
                                  thumbnailProvider: thumbnailProvider,
                                  localStorageURL: localStorageURLs[existingAttachment.attachmentToken])
                    }
                }
            }
        }
    }

    func moveItem(from oldIndexPath: IndexPath, to newIndexPath: IndexPath) {
        DocsLogger.btInfo("[DIFF] [Attachment] move attachment from \(oldIndexPath) to \(newIndexPath), current items count: \(latestSnapshot.items.count)")
        attachmentView.moveItem(at: oldIndexPath, to: newIndexPath)
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return latestSnapshot.items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard 0 <= indexPath.item, indexPath.item < latestSnapshot.items.count else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: AttachmentCell.reuseIdentifier, for: indexPath)
        }
        let attachment = latestSnapshot.items[indexPath.item]
        switch attachment {
        case .pending(let pendingAttachment):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AttachmentCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? AttachmentCell {
                cell.deleter = self
                cell.load(data: pendingAttachment)
            }
            return cell

        case .uploading(let uploadingAttachment):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UploadingCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? UploadingCell {
                cell.deleter = self
                cell.feed(info: uploadingAttachment)
            }
            return cell

        case .existing(let existingAttachment):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AttachmentCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? AttachmentCell {
                cell.deleter = self
                cell.load(data: existingAttachment,
                          thumbnailProvider: thumbnailProvider,
                          localStorageURL: localStorageURLs[existingAttachment.attachmentToken])
            }
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: BTFieldUIDataAttachment.Const.itemSize, height: BTFieldUIDataAttachment.Const.itemSize)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? AttachmentCell else {
            return
        }
        if let data = cell.data {
            let attachments = latestSnapshot.items.compactMap { item -> BTAttachmentModel? in
                if case .existing(let attachment) = item {
                    return attachment
                } else {
                    return nil
                }
            }
            guard !attachments.isEmpty, let previewIndex = attachments.firstIndex(of: data) else {
                spaceAssertionFailure("preview attachment failed")
                return
            }
            delegate?.previewAttachments(attachments, atIndex: previewIndex, inFieldWithID: fieldID)
        } else if let data = cell.waitingUploadData {
            let pendingAttachments = latestSnapshot.items.compactMap { item -> PendingAttachment? in
                if case .pending(let attachment) = item {
                    return attachment
                } else {
                    return nil
                }
            }
            guard !pendingAttachments.isEmpty, let previewIndex = pendingAttachments.firstIndex(of: data) else {
                spaceAssertionFailure("preview pending attachment failed")
                return
            }
            delegate?.previewAttachments(pendingAttachments, atIndex: previewIndex)
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        guard fieldModel.editable else { return false }
        if let showingMenuIndexPath = showingMenuIndexPath,
           showingMenuIndexPath != indexPath,
           let highlightedCell = collectionView.cellForItem(at: showingMenuIndexPath) as? AttachmentCell {
            highlightedCell.menuWillHide()
            return false
        }
        guard let cell = collectionView.cellForItem(at: indexPath) as? AttachmentCell else { return false }
        let deleteItem = UIMenuItem(title: BundleI18n.SKResource.Doc_Facade_Delete, action: #selector(AttachmentCell.deleteAttachment))
        UIMenuController.shared.menuItems = [deleteItem]
        delegate?.generateHapticFeedback()
        cell.showBorder(true, isSelected: true)
        showingMenuIndexPath = indexPath
        return true
    }

    func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        action == #selector(AttachmentCell.deleteAttachment)
    }

    func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        // 这个方法根本不会调用，但是如果不实现的话则无法呼出 menu
    }
}

extension BTFieldV2Attachment: BTAttachmentDeleter {
    func deleteAttachment(data: BTAttachmentModel) {
        DocsLogger.btInfo("[ACTION] delete existing attachment")
        delegate?.deleteAttachment(data: data, inFieldWithID: fieldID)
    }

    func deleteAttachment(data: PendingAttachment) {
        DocsLogger.btInfo("[ACTION] delete pending attachment")
        delegate?.deleteAttachment(data: data, inFieldWithID: fieldID)
    }
    func cancelAttachment(data: BTMediaUploadInfo) {
        DocsLogger.btInfo("[ACTION] cancel uploading attachment")
        delegate?.cancelAttachment(data: data, inFieldWithID: fieldID)
    }

    func clearState() {
        showingMenuIndexPath = nil
    }
}

extension BTFieldV2Attachment {
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer.view == attachmentView {
            let point = touch.location(in: attachmentView)
            for cell in attachmentView.visibleCells {
                if cell.frame.contains(point) {
                    return false
                }
            }
            return true
        }
        return super.gestureRecognizer(gestureRecognizer, shouldReceive: touch)
    }
}


// MARK: - Uploaded Attachment Cell

extension BTFieldV2Attachment {
    // MARK: AttachmentCell
    final class AttachmentCell: UICollectionViewCell {
        
        private struct Const {
            static let videoPlayIconSize: CGFloat = 24
        }

        var data: BTAttachmentModel?

        var waitingUploadData: PendingAttachment?

        weak var deleter: BTAttachmentDeleter?

        private var disposeBag = DisposeBag()

        private lazy var thumbnail = UIImageView().construct { it in
            it.contentMode = .scaleAspectFill
        }

        private lazy var defaultView = UIView()

        private lazy var fileIcon = UIImageView()

        private lazy var videoPlayIcon: UIImageView = UIImageView().construct { it in
            it.image = UDIcon.playFilled.ud.resized(to: CGSize(width: 10, height: 10)).ud.withTintColor(UDColor.staticWhite)
            it.contentMode = .center
            it.backgroundColor = UDColor.bgMask
        }

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
        
        override func layoutSubviews() {
            super.layoutSubviews()
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
                it.size.equalTo(BTFieldUIDataAttachment.Const.fileIconSize)
            }
            thumbnail.snp.makeConstraints { it in
                it.edges.equalToSuperview()
            }
            videoPlayIcon.snp.makeConstraints { it in
                it.center.equalToSuperview()
                it.width.height.equalTo(Const.videoPlayIconSize)
            }
            videoPlayIcon.layer.masksToBounds = true
            videoPlayIcon.layer.cornerRadius = Const.videoPlayIconSize * 0.5
        }
        
        /// 文件预览接入条件访问控制 https://bytedance.feishu.cn/docx/FghndycFjo22qbxWHGQcLdIanKg
        private func hasFilePreviewPermission(token: String?) -> Bool {
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
        private func legacyHasFilePreviewPermission(token: String?) -> Bool {
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
            guard hasFilePreviewPermission(token: data.attachmentToken) else {
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
            guard hasFilePreviewPermission(token: nil) else {
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
                contentView.layer.borderWidth = 0.5
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

extension BTFieldV2Attachment {
    final class UploadingCell: UICollectionViewCell {
        
        private struct Const {
            static let cancelBtnSize: CGFloat = 16
        }

        private lazy var defaultView = UIView()

        private lazy var fileIcon = UIImageView()

        private lazy var dimmingMaskView = UIView().construct { it in
            it.backgroundColor = UDColor.bgMask
        }

        private lazy var progressBar = UDProgressView(
            config: UDProgressViewUIConfig(
                type: .linear,
                barMetrics: .default,
                layoutDirection: .horizontal,
                showValue: false
            )
        )

        weak var deleter: BTAttachmentDeleter?
                
        var info: BTMediaUploadInfo?
                
        private lazy var cancelUploadingButton: UIButton = UIButton().construct { it in
            it.backgroundColor = UIColor.ud.bgMask
            it.setImage(UDIcon.closeBoldOutlined.ud.resized(to: CGSize(width: 8, height: 8)).ud.withTintColor(UDColor.staticWhite), for: .normal)
            it.addTarget(self, action: #selector(cancelUploadingAttachment), for: .touchUpInside)
        }
                
        private lazy var uploadingPercent = UILabel().construct { it in
            it.textAlignment = .center
            it.textColor = UDColor.staticWhite
            it.font = UDFont.caption2
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
            
            defaultView.snp.makeConstraints { it in
                it.edges.equalToSuperview()
            }
            fileIcon.snp.makeConstraints { it in
                it.center.equalToSuperview()
                it.size.equalTo(BTFieldUIDataAttachment.Const.fileIconSize)
            }
            dimmingMaskView.snp.makeConstraints { it in
                it.edges.equalToSuperview()
            }
            progressBar.snp.makeConstraints { it in
                it.center.equalToSuperview()
                it.height.equalTo(4)
                it.leading.trailing.equalToSuperview().inset(4)
            }
            cancelUploadingButton.snp.makeConstraints {it in
                it.width.height.equalTo(Const.cancelBtnSize)
                it.top.right.equalToSuperview().inset(1)
            }
            uploadingPercent.snp.makeConstraints { it in
                it.left.right.centerX.equalToSuperview()
                it.top.equalTo(progressBar.snp.bottom)
            }
            
            cancelUploadingButton.layer.masksToBounds = true
            cancelUploadingButton.layer.cornerRadius = Const.cancelBtnSize * 0.5
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
