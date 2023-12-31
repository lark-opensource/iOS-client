//
//  DetailAttachmentViewModel.swift
//  Todo
//
//  Created by baiyantao on 2022/12/21.
//

import Foundation
import RxSwift
import RxCocoa
import LarkRichTextCore
import TodoInterface
import LarkContainer

final class DetailAttachmentViewModel: UserResolverWrapper {
    let userResolver: LarkContainer.UserResolver
    enum ViewState {
        case content
        case empty
        case hidden
    }

    // view drivers
    let rxViewState = BehaviorRelay<ViewState>(value: .empty)
    let rxHeaderData = BehaviorRelay<DetailAttachmentHeaderViewData>(value: .init())
    let rxFooterData = BehaviorRelay<DetailAttachmentFooterViewData>(value: .init())
    let reloadNoti = PublishRelay<Void>()
    let rxContentHeight = PublishRelay<CGFloat>()
    private(set) var cellDatas: [DetailAttachmentContentCellData] = []

    // 依赖
    @ScopedInjectedLazy private var attachmentService: AttachmentService?
    private let store: DetailModuleStore
    private let disposeBag = DisposeBag()

    // 内部状态
    private var needFold = true
    private(set) lazy var attachmentScene = initAttachmentScene()

    init(resolver: UserResolver, store: DetailModuleStore) {
        self.userResolver = resolver
        self.store = store
    }

    func setup() {
        store.rxValue(forKeyPath: \.attachments).distinctUntilChanged()
            .debounce(.milliseconds(100), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                self?.reloadData()
            }).disposed(by: disposeBag)
        attachmentService?.updateNoti
            .debounce(.milliseconds(100), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] (scene, _) in
                guard let self = self, self.attachmentScene == scene else { return }
                self.reloadData()
            }).disposed(by: disposeBag)
        store.rxValue(forKeyPath: \.permissions).distinctUntilChanged(\.attachment)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] permissions in
                guard let self = self else { return }
                var data = self.rxFooterData.value
                data.isAddViewHidden = !permissions.attachment.isEditable
                self.rxFooterData.accept(data)
            }).disposed(by: disposeBag)
    }

    private func reloadData() {
        var attachments = store.state.attachments
            .filter { $0.type == .file }
            .sorted(by: { $0.uploadMilliTime < $1.uploadMilliTime })
        var infos = attachmentService?.getInfos(by: attachmentScene) ?? []
        DetailAttachment.logger.info("task reload. attas: \(attachments.map(\.guid)), infos: \(infos.map(\.uploadInfo.uploadKey))")

        if infos.contains(where: { $0.uploadInfo.uploadStatus == .success }) {
            let successInfos = infos.filter { $0.uploadInfo.uploadStatus == .success }
            // 创建场景下，需要 infos 中 success 的 item 转化为 attachment
            if store.state.scene.isForCreating {
                infos = infos.filter { $0.uploadInfo.uploadStatus != .success }
                attachmentService?.batchRemoveFromDic(attachmentScene, successInfos)
                let newAttachments = DetailAttachment.infos2Attachments(successInfos)
                DetailAttachment.logger.info("task reload. covert infos: \(successInfos.map(\.uploadInfo.uploadKey)) to :\(newAttachments.map(\.guid))")
                attachments.append(contentsOf: newAttachments)
                attachments.sort(by: { $0.uploadMilliTime < $1.uploadMilliTime })
                store.dispatch(.localUpdateAttachments(attachments))
            }
            // 编辑场景下，则等待 sdk 的推送，有一个转化结束的 attachment 过来，就删除一个 info
            else {
                let attachmentIdSet = Set(attachments.map(\.guid))
                let infoIdSet = Set(successInfos.map(\.uploadInfo.guid))
                let intersectionIdSet = attachmentIdSet.intersection(infoIdSet)

                if !intersectionIdSet.isEmpty {
                    infos = infos.filter { !intersectionIdSet.contains($0.uploadInfo.guid) }
                    let needDeleteInfos = successInfos.filter { intersectionIdSet.contains($0.uploadInfo.guid) }
                    attachmentService?.batchRemoveFromDic(attachmentScene, needDeleteInfos)
                }
            }
        }
        store.dispatch(.updateUploadingAttachments(infos))

        let attachmentsSize = attachments.reduce(0, { $0 + (UInt($1.fileSize) ?? 0) })
        let successInfos = infos.filter { $0.uploadInfo.uploadStatus == .success }
        let succeessInfosSize = successInfos.reduce(0, { $0 + ($1.fileInfo.size ?? 0) })
        rxHeaderData.accept(.init(
            attachmentCount: attachments.count + successInfos.count,
            fileSizeText: DetailAttachment.getSizeText(intVal: attachmentsSize + succeessInfosSize)
        ))
        var cellDatas = [DetailAttachmentContentCellData]()
        let permission = store.state.permissions.attachment
        if self.needFold {
            let isFold = attachments.count > DetailAttachment.foldCount
            rxFooterData.accept(.init(
                hasMoreState: isFold ? .hasMore(moreCount: attachments.count - DetailAttachment.foldCount) : .noMore,
                isAddViewHidden: !permission.isEditable
            ))
            cellDatas = DetailAttachment.attachments2CellDatas(Array(attachments.prefix(DetailAttachment.foldCount)))
        } else {
            rxFooterData.accept(.init(
                hasMoreState: .noMore,
                isAddViewHidden: !permission.isEditable
            ))
            cellDatas = DetailAttachment.attachments2CellDatas(attachments)
        }
        cellDatas.append(contentsOf: DetailAttachment.infos2CellDatas(infos))
        cellDatas.sort(by: { $0.uploadTime < $1.uploadTime })
        self.cellDatas = cellDatas
        DetailAttachment.logger.info("task reload. total count: \(cellDatas.count)")

        if cellDatas.isEmpty {
            rxViewState.accept(.empty)
        } else {
            reloadNoti.accept(void)
            rxViewState.accept(.content)
        }
        rxContentHeight.accept(getContentHeight())
    }

    private func getContentHeight() -> CGFloat {
        switch rxViewState.value {
        case .empty:
            return DetailAttachment.emptyViewHeight
        case .content:
            let headerHeight = rxHeaderData.value.headerHeight
            let footerHeight = rxFooterData.value.footerHeight
            let cellsHeight = cellDatas.reduce(0, { $0 + $1.cellHeight })
            return headerHeight + footerHeight + cellsHeight
        case .hidden:
            return CGFloat.zero
        }
    }

    private func initAttachmentScene() -> AttachmentScene {
        switch store.state.scene {
        case .create:
            return .taskCreate
        case .edit(let guid, _):
            return .taskEdit(taskGuid: guid)
        }
    }
}

// MARK: - View Action

extension DetailAttachmentViewModel {
    func doExpandMore() {
        DetailAttachment.logger.info("task doExpandMore")
        needFold = false
        reloadData()
    }

    func doSelectedFiles(_ infos: [TaskFileInfo]) {
        DetailAttachment.logger.info("task doSelectedFiles, count: \(infos.count)")
        needFold = false
        for info in infos {
            attachmentService?.upload(scene: attachmentScene, fileInfo: info)
        }
    }

    func getRemainingCount() -> Int {
        return DetailAttachment.TaskLimit - store.state.attachments.count
    }

    func hasEditPermission() -> Bool {
        store.state.permissions.attachment.isEditable
    }

    func doDelete(with data: DetailAttachmentContentCellData) {
        switch data.source {
        case .rust(let attachment):
            store.dispatch(.removeAttachments([attachment]))
        case .attachmentService(let info):
            guard let key = info.uploadInfo.uploadKey else { return }
            switch info.uploadInfo.uploadStatus {
            case .uploading:
                attachmentService?.cancelUpload(
                    key: key,
                    onSuccess: {
                        DetailAttachment.logger.info("task cancelUpload success")
                    },
                    onError: { [weak self] err in
                        guard let self = self else { return }
                        DetailAttachment.logger.error("task cancelUpload, err: \(err)")
                        self.attachmentService?.batchRemoveFromDic(self.attachmentScene, [info])
                        self.reloadData()
                    }
                )
            default:
                DetailAttachment.logger.info("task cancelUpload, type: \(info.uploadInfo.uploadStatus.rawValue)")
                attachmentService?.batchRemoveFromDic(attachmentScene, [info])
                reloadData()
            }
        }
    }
}
