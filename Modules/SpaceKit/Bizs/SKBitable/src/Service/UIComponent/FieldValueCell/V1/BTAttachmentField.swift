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
import SKInfra
import SpaceInterface

final class BTAttachmentField: BTBaseField, BTFieldAttachmentCellProtocol, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var sourceAddView: UIView {
        return addButton
    }
    
    var sourceAddRect: CGRect {
        return CGRect(x: addButton.addIcon.frame.origin.x,
                      y: addButton.addIcon.frame.origin.y,
                      width: addButton.addIcon.frame.width + 16,
                      height: addButton.addIcon.frame.height)
    }
    

    private lazy var flowLayout = UICollectionViewFlowLayout().construct { it in
        it.minimumLineSpacing = 4
        it.minimumInteritemSpacing = 4
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
    }

    // MARK: attachment data
    private let thumbnailProvider = BTAttachmentThumbnailProvider()

    var localStorageURLs: [String: URL] = [:]

    private var latestSnapshot = BTAttachment(fieldID: "", attachments: [])

    // MARK: add button

    lazy var addButton = AddButton().construct { it in
        it.addTarget(self, action: #selector(uploadAttachment), for: .touchUpInside)
        let allow = checkUploadAttachmentPermission()
        if allow {
            it.iconStyle = .normal
        } else {
            it.iconStyle = .disable
        }
    }

    // MARK: configurations
    
    var onlyCamera: Bool = false {
        didSet {
            updateAddButton()
        }
    }

    private lazy var tapGR = UITapGestureRecognizer(target: self, action: #selector(onTappingEmptyContainer)).construct { it in
        it.cancelsTouchesInView = false
    }

    var showingMenuIndexPath: IndexPath?

    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        let oldFieldID = fieldModel.fieldID
        let oldRecordID = fieldModel.recordID
        super.loadModel(model, layout: layout)

        onlyCamera = model.onlyCamera
        localStorageURLs = fieldModel.localStorageURLs
        let newAttachments = assembleAttachments(from: model)
        relayout(allAttachments: newAttachments)
        if attachmentView.window != nil, model.fieldID == oldFieldID && model.recordID == oldRecordID {
            diffModel(oldModel: latestSnapshot, newModel: BTAttachment(fieldID: fieldID, attachments: newAttachments))
        } else {
            latestSnapshot = BTAttachment(fieldID: model.fieldID, attachments: newAttachments)
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

    private func relayout(allAttachments: [BTAttachmentType]) {
        attachmentView.removeFromSuperview()
        addButton.removeFromSuperview()
        if fieldModel.editable {
            containerView.addSubview(addButton)
            // 有编辑权限，不能弹 toast
            containerView.removeGestureRecognizer(tapGR)
            if allAttachments.isEmpty {
                addButton.snp.remakeConstraints { it in
                    it.edges.equalToSuperview()
                }
                addButton.layer.cornerRadius = 6
                if fieldModel.isEditing || !fieldModel.errorMsg.isEmpty {
                    addButton.shouldAddNewBorder = false
                    containerView.layer.borderWidth = BTFieldLayout.Const.containerBorderWidth
                } else {
                    addButton.shouldAddNewBorder = true
                    containerView.layer.borderWidth = 0 // 为了让 add button 的虚线边框显示出来
                }
            } else {
                containerView.addSubview(attachmentView)
                attachmentView.snp.remakeConstraints { it in
                    it.left.top.right.equalToSuperview().inset(BTFieldLayout.Const.containerPadding)
                    it.bottom.equalToSuperview().inset(BTFieldLayout.Const.containerPadding + BTFieldLayout.Const.tableItemHeight + BTFieldLayout.Const.containerPadding)
                }
                addButton.snp.remakeConstraints { it in
                    it.left.right.bottom.equalToSuperview().inset(BTFieldLayout.Const.containerPadding)
                    it.height.equalTo(BTFieldLayout.Const.tableItemHeight)
                }
                addButton.layer.cornerRadius = 4
                addButton.shouldAddNewBorder = true
                containerView.layer.borderWidth = BTFieldLayout.Const.containerBorderWidth
            }
        } else {
            containerView.layer.borderWidth = 0
            if allAttachments.isEmpty {
                // 无编辑权限，仅在 collectionView 为空时弹 toast
                containerView.addGestureRecognizer(tapGR)
            } else {
                // 无编辑权限，但 collectionView 有内容时，允许用户查看附件，不弹 toast
                containerView.removeGestureRecognizer(tapGR)
                containerView.addSubview(attachmentView)
                attachmentView.snp.remakeConstraints { it in
                    it.left.top.right.bottom.equalToSuperview().inset(BTFieldLayout.Const.containerPadding)
                }
            }
        }
        layoutIfNeeded()
    }

    func updateAddButton() {
        let iconType: UDIconType = onlyCamera ? .cameraOutlined : .addOutlined
        addButton.update(iconType: iconType)
    }

    func panelDidStartEditing() {
        updateBorderMode(.editing)
        delegate?.panelDidStartEditingField(self, scrollPosition: .bottom)
    }
    
    @objc
    private func onTappingEmptyContainer() {
        if !fieldModel.editable {
            showUneditableToast()
        }
    }

    @objc
    private func uploadAttachment() {
        if fieldModel.editable {
            delegate?.didClickAddAttachment(inField: self)
        } else {
            showUneditableToast()
        }
    }

    func stopEditing() {
        let newAttachments = assembleAttachments(from: self.fieldModel)
        relayout(allAttachments: newAttachments)
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
        let defaultLength = BTFieldLayout.Const.attachmentCellLength
        let width = fieldModel.width - BTFieldLayout.Const.containerLeftRightMargin * 2 - BTFieldLayout.Const.containerPadding * 2
        guard width < 500 else { return CGSize(width: defaultLength, height: defaultLength) }
        var itemLength = (width - BTFieldLayout.Const.attachmentCellHSpacing * 2) / 3.0
        itemLength = floor(itemLength)
        return CGSize(width: itemLength, height: itemLength)
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


protocol BTAttachmentDeleter: AnyObject {
    func deleteAttachment(data: BTAttachmentModel)
    func deleteAttachment(data: PendingAttachment)
    func cancelAttachment(data: BTMediaUploadInfo)
    func clearState()
}

extension BTAttachmentField: BTAttachmentDeleter {
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

// MARK: PermissionSDK
extension BTAttachmentField {
    private func checkUploadAttachmentPermission() -> Bool {
        guard UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation else {
            return legacyCheckUploadAttachmentPermission()
        }
        guard let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self) else {
            DocsLogger.btError("checkUploadAttachmentPermission with exception, permissionSDK is nil")
            return false
        }
        let request = PermissionRequest(entity: .ccm(token: "",
                                                     type: .bitable),
                                        operation: .uploadAttachment,
                                        bizDomain: .ccm)
        let response = permissionSDK.validate(request: request)
        return response.allow
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func legacyCheckUploadAttachmentPermission() -> Bool {
        let validation = CCMSecurityPolicyService.syncValidate(
            entityOperate: .ccmAttachmentUpload,
            fileBizDomain: .ccm,
            docType: .bitable,
            token: nil
        )
        return validation.allow
    }
}
