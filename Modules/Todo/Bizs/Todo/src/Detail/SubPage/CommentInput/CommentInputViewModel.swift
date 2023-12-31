//
//  CommentInputViewModel.swift
//  Todo
//
//  Created by 张威 on 2021/3/6.
//

import RxSwift
import RxCocoa
import LarkContainer
import Photos
import TodoInterface
import LarkAccountInterface
import CTFoundation

/// Keyboard - Input - ViewModel

final class CommentInputViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    /// Input
    /// 输入框输入内容
    let rxInputText = BehaviorRelay(value: AttrText())

    /// Send 是否可用
    let rxSendEnable = BehaviorRelay(value: false)

    /// 选择图片是否可用
    let rxPictureEnable = BehaviorRelay(value: false)

    /// 图片状态
    let rxImageStates = BehaviorRelay(value: [ImageState]())

    /// 文件附件
    let reloadAttachmentNoti = PublishRelay<Void>()
    let rxAttachmentHeight = PublishRelay<CGFloat>()
    let rxAttachmentIsHidden = PublishRelay<Bool>()
    private var fileAttachments = [Rust.Attachment]()
    let rxAttachmentCellDatas = BehaviorRelay(value: [DetailAttachmentContentCellData]())

    let todoId: String

    var errorToastCallback: ((String) -> Void)?

    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy
    private var messengerDependency: MessengerDependency?
    @ScopedInjectedLazy
    private var attachmentService: AttachmentService?
    @ScopedInjectedLazy private var fetchApi: TodoFetchApi?
    private var uploadingDisposables = [String: Disposable]()

    private(set) lazy var attachmentScene = AttachmentScene.comment(taskGuid: todoId)

    private static let maxImageCount = 12

    init(resolver: UserResolver, todoId: String) {
        self.userResolver = resolver
        self.todoId = todoId
        Observable.combineLatest(rxInputText, rxImageStates, rxAttachmentCellDatas)
            .map { (attrText, imageStates, attachmentCellDatas) -> Bool in
                if imageStates.contains(where: { $0.isUploading }) || attachmentCellDatas.contains(where: {
                    if case .attachmentService = $0.source { return true } else { return false }
                }) {
                    return false
                }
                let trimmedText = attrText.string.trimmingCharacters(in: .whitespacesAndNewlines)
                return !imageStates.isEmpty || !trimmedText.isEmpty || !attachmentCellDatas.isEmpty
            }
            .bind(to: rxSendEnable)
            .disposed(by: disposeBag)
        rxImageStates.map({ $0.count < Self.maxImageCount }).bind(to: rxPictureEnable).disposed(by: disposeBag)
        listenToAttachmentService()
    }

    func makeAttachments() -> [Rust.Attachment] {
        var ret = [Rust.Attachment]()
        for imageState in rxImageStates.value {
            switch imageState {
            case .rustMeta(_, var attachment):
                attachment.position = Int32(ret.count)
                ret.append(attachment)
            case .uploaded(_, let extra):
                var attachment = Rust.Attachment()
                attachment.fileToken = extra.token
                attachment.type = .image
                attachment.imageSet = Rust.ImageSet()
                attachment.imageSet.thumbnail.key = extra.token
                attachment.imageSet.middle.key = extra.token
                attachment.imageSet.origin.key = extra.token
                attachment.uploaderUserID = userResolver.userID
                attachment.position = Int32(ret.count)
                ret.append(attachment)
            case .uploading:
                assertionFailure()
            }
        }
        return ret
    }

    func resetImageStates(with imageStates: [ImageState]) {
        rxImageStates.accept(imageStates)
    }

    func makeFileAttachments() -> [Rust.Attachment] {
        return fileAttachments
    }

    func resetFileAttachments(_ attachments: [Rust.Attachment]) {
        fileAttachments = attachments
        reloadAttachment()
    }
}

// MARK: - Image

extension CommentInputViewModel {

    /// 新增了上传中的图片，update ImageStates
    private func appendImageStates(with uploadingItems: [(image: UIImage, uploadId: String)]) {
        guard !uploadingItems.isEmpty else {
            assertionFailure()
            return
        }
        var states = rxImageStates.value
        guard states.count + uploadingItems.count <= Self.maxImageCount else {
            assertionFailure()
            return
        }
        var i = 0
        while i < uploadingItems.count && states.count < Self.maxImageCount {
            let (image, uploadId) = uploadingItems[i]
            states.append(.uploading(data: image, uploadId: uploadId))
            i += 1
        }
        rxImageStates.accept(states)
    }

    /// 有图片上传完了，update ImageStates
    private func updateImageState(withUploadId uploadId: String, token: String) {
        var states = rxImageStates.value
        var needsUpdate = false
        for i in 0..<states.count {
            if case .uploading(let image, let upId) = states[i], upId == uploadId {
                let extra = ImageAttachment(token: token, position: i, imageSet: nil)
                states[i] = .uploaded(data: image, extra: extra)
                needsUpdate = true
            }
        }
        if needsUpdate { rxImageStates.accept(states) }
    }

    private func deleteImageState(at index: Int) {
        var states = rxImageStates.value
        guard index >= 0 && index < states.count else {
            assertionFailure()
            return
        }
        let state = states.remove(at: index)
        rxImageStates.accept(states)
        if case .uploading(_, let uploadId) = state {
            uploadingDisposables[uploadId]?.dispose()
        }
    }

    enum ImageState {
        /// 上传中
        case uploading(data: UIImage, uploadId: String)
        /// 上传完成
        case uploaded(data: UIImage, extra: ImageAttachment)
        /// rust
        case rustMeta(Rust.ImageSet, extra: Rust.Attachment)

        var isUploading: Bool {
            if case .uploading = self { return true }
            return false
        }

        var imageItem: CommentInputImageGalleryView.ImageItem {
            switch self {
            case .uploaded(let data, _):
                return .uploaded(data: data)
            case .uploading(let data, _):
                return .uploading(data: data)
            case .rustMeta(let imageSet, _):
                return .rustMeta(imageSet)
            }
        }
    }

    /// 插入拍摄的照片
    func appendTakenPhoto(_ photo: UIImage) {
        Detail.logger.info("append photo")
        DispatchQueue.global().async {
            self.doAppendTakenPhoto(photo)
        }
    }

    func appendSelectedPhotos(_ photos: [PHAsset], isOriginal: Bool) {
        DispatchQueue.global().async {
            self.doAppendSelectedPhotos(photos, isOriginal: isOriginal)
        }
    }

    /// 删除图片
    func deleteImage(at position: Int) {
        Detail.logger.info("delete image at \(position)")
        deleteImageState(at: position)
    }

    /// 可选图片的数量
    func seletableImageCount() -> Int {
        return max(Self.maxImageCount - rxImageStates.value.count, 0)
    }

    private func doAppendTakenPhoto(_ photo: UIImage) {
        guard let messengerDependency = messengerDependency else { return }
        let uploadId = UUID().uuidString
        let observable = messengerDependency.uploadTakenPhoto(photo, callback: { [weak self] img in
            self?.appendImageStates(with: [(img, uploadId)])
        })
        doUpload(observable, uploadId: uploadId)
    }

    private func doAppendSelectedPhotos(_ assets: [PHAsset], isOriginal: Bool) {
        guard let messengerDependency = messengerDependency else { return }
        for asset in assets {
            let uploadId = UUID().uuidString
            let observable = messengerDependency.uploadPhotoAsset(asset, isOriginal: isOriginal, callback: { [weak self] img in
                self?.appendImageStates(with: [(img, uploadId)])
            })
            doUpload(observable, uploadId: uploadId)
        }
    }

    private func doUpload(_ observable: Observable<String>, uploadId: String) {
        let disposable = observable
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self] token in
                    Detail.logger.info("upload image succeed. token: \(token)")
                    guard let self = self else { return }
                    self.updateImageState(withUploadId: uploadId, token: token)
                    self.uploadingDisposables.removeValue(forKey: uploadId)
                    Detail.tracker(
                        .todo_comment,
                        params: [
                            "action": "upload_image",
                            "source": "task_detail",
                            "task_id": self.todoId
                        ]
                    )
                },
                onError: { [weak self] err in
                    if let errMsg = self?.messengerDependency?.parseImageUploaderError(err) {
                        self?.errorToastCallback?(errMsg)
                    }
                    Detail.logger.error("upload image failed. err: \(err)")
                }
            )
        disposable.disposed(by: disposeBag)
        uploadingDisposables[uploadId] = disposable
    }
}

// MARK: - User

extension CommentInputViewModel {

    func fetchTodoUser(with id: String, onSuccess: @escaping (User) -> Void) {
        guard !id.isEmpty else { return }
        fetchApi?.getUsers(byIds: [id]).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { users in
                    guard let first = users.first else { return }
                    onSuccess(User(pb: first))
                },
                onError: { err in
                    Detail.logger.info("fetch users failed, error:\(err)")
                }
            )
            .disposed(by: disposeBag)
    }

}

// MARK: - Attachment

extension CommentInputViewModel {
    func listenToAttachmentService() {
        attachmentService?.updateNoti
            .debounce(.milliseconds(100), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (scene, _) in
                guard let self = self, self.attachmentScene == scene else { return }
                self.reloadAttachment()
            }).disposed(by: disposeBag)
    }

    private func reloadAttachment() {
        var attachments = fileAttachments.filter { $0.type == .file }
        var infos = attachmentService?.getInfos(by: attachmentScene) ?? []
        DetailAttachment.logger.info("comment reload. attas: \(attachments.map(\.guid)), infos: \(infos.map(\.uploadInfo.uploadKey))")

        let successInfos = infos.filter { $0.uploadInfo.uploadStatus == .success }
        if !successInfos.isEmpty {
            infos = infos.filter { $0.uploadInfo.uploadStatus != .success }
            attachmentService?.batchRemoveFromDic(attachmentScene, successInfos)
            let newAttachments = DetailAttachment.infos2Attachments(successInfos)
            DetailAttachment.logger.info("comment reload. covert infos: \(successInfos.map(\.uploadInfo.uploadKey)) to :\(newAttachments.map(\.guid))")
            attachments.append(contentsOf: newAttachments)
            fileAttachments = attachments
        }

        var cellDatas = DetailAttachment.attachments2CellDatas(attachments)
        cellDatas.append(contentsOf: DetailAttachment.infos2CellDatas(infos))
        cellDatas.sort(by: { $0.uploadTime < $1.uploadTime })
        rxAttachmentCellDatas.accept(cellDatas)
        DetailAttachment.logger.info("comment reload. total count: \(cellDatas.count)")

        if cellDatas.isEmpty {
            rxAttachmentIsHidden.accept(true)
        } else {
            let cellsHeight = cellDatas.reduce(0, { $0 + $1.cellHeight })
            let maxHeightMultiplier = CGFloat(2.5)
            let maxHeight = DetailAttachment.cellHeight * maxHeightMultiplier
            rxAttachmentHeight.accept(min(cellsHeight, maxHeight))
            reloadAttachmentNoti.accept(void)
            rxAttachmentIsHidden.accept(false)
        }
    }

    func doSelectedFiles(_ infos: [TaskFileInfo]) {
        DetailAttachment.logger.info("comment doSelectedFiles, count: \(infos.count)")
        for info in infos {
            attachmentService?.upload(scene: attachmentScene, fileInfo: info)
        }
    }

    func getRemainingCount() -> Int {
        return DetailAttachment.CommentLimit - rxAttachmentCellDatas.value.count
    }

    func doDeleteAttachment(with data: DetailAttachmentContentCellData) {
        switch data.source {
        case .rust(let attachment):
            guard let index = fileAttachments.firstIndex(where: { $0.guid == attachment.guid }) else {
                DetailAttachment.logger.error("delete failed, not find guid: \(attachment.guid), totalCount: \(fileAttachments.count)")
                reloadAttachment()
                return
            }
            DetailAttachment.logger.info("comment do delete at index: \(index), guid: \(attachment.guid)")
            fileAttachments.remove(at: index)
            reloadAttachment()
        case .attachmentService(let info):
            guard let key = info.uploadInfo.uploadKey else { return }
            switch info.uploadInfo.uploadStatus {
            case .uploading:
                attachmentService?.cancelUpload(
                    key: key,
                    onSuccess: {
                        DetailAttachment.logger.info("comment cancelUpload success")
                    },
                    onError: { [weak self] err in
                        guard let self = self else { return }
                        DetailAttachment.logger.error("comment cancelUpload, err: \(err)")
                        self.attachmentService?.batchRemoveFromDic(self.attachmentScene, [info])
                        self.reloadAttachment()
                    }
                )
            default:
                DetailAttachment.logger.info("comment cancelUpload, type: \(info.uploadInfo.uploadStatus.rawValue)")
                attachmentService?.batchRemoveFromDic(attachmentScene, [info])
                reloadAttachment()
            }
        }
    }
}
