//
//  EventEdit+AttachmentUploader.swift
//  Calendar
//
//  Created by Hongbin Liang on 2/26/23.
//

import Foundation
import RxSwift
import RxRelay
import LarkContainer

class EventAttachmentUploader: UserResolverWrapper {

    fileprivate static let calendarMountPoint = "calendar"

    private let disposeBag = DisposeBag()
    private let rxAttachmentsPool: PublishRelay<CalendarEventAttachmentEntity> = .init()
    private let rxDeletedAttachments: BehaviorRelay<[Int]> = .init(value: [])

    private weak var attachmentVM: EventEditAttachmentManager?

    @ScopedInjectedLazy var calendarDependecy: CalendarDependency?

    let userResolver: UserResolver

    private var creatorCalendarIdGetter: () -> String

    init(userResolver: UserResolver, attachmentVM: EventEditAttachmentManager, creatorCalendarIdGetter: @escaping () -> String) {
        self.userResolver = userResolver
        self.attachmentVM = attachmentVM
        self.creatorCalendarIdGetter = creatorCalendarIdGetter
        dataBinding()
    }

    private func dataBinding() {
        guard let attachmentVM = self.attachmentVM else { return }
        // Sync uploading
        rxAttachmentsPool
            .concatMap { [weak self, weak attachmentVM] attachment -> Observable<AttachmentUploadInfo> in
                guard let self = self, let attachmentVM = attachmentVM, let fileIndex = attachment.index else { return .empty() }

                return attachmentVM.rxAvailableStorage
                    .take(1)
                    .flatMap { storage -> Observable<AttachmentUploadInfo> in

                        EventEdit.logger.info("EventAttachment: before uploading \(fileIndex)")

                        guard storage >= attachment.size, let dep = self.calendarDependecy else {
                            EventEdit.logger.info("EventAttachment: uploading attachment \(fileIndex), size \(attachment.size) - over available storage \(storage)")
                            // UX 要一个 retry 时的 loading 态
                            return Observable.just(.init(status: .failed(I18n.Calendar_Upload_TryAgainMax), index: fileIndex)).delay(.milliseconds(300), scheduler: MainScheduler.instance)
                        }

                        EventEdit.logger.info("EventAttachment: start uploading attachment \(fileIndex)")

                        // DriveSDK 不会立即返回 progress 0，视图上会出现死等（awaiting），故补一下
                        let rxUploadResp = dep.uploadEventAttachment(
                            localPath: attachment.localPath,
                            fileName: attachment.name,
                            mountNodePoint: self.creatorCalendarIdGetter(),
                            mountPoint: Self.calendarMountPoint,
                            failedTip: I18n.Calendar_Upload_TryAgain
                        ).startWith(("", .uploading(0)))

                        // 上传过程中实时判断是否删除（包括正在上传的文件）
                        let rxHasBeenDeletedTrigger = self.rxDeletedAttachments.map { $0.contains(fileIndex) }.filter { $0 }
                            .do { _ in
                                EventEdit.logger.info("EventAttachment: uploading attachment \(fileIndex) - has been deleted")
                            }

                        return rxUploadResp.takeUntil(rxHasBeenDeletedTrigger)
                            .do(onError: { error in
                                EventEdit.logger.info("EventAttachment: uploading attachment \(fileIndex) - error \(error)")
                            })
                            .map { uploadResp in
                                return .init(status: uploadResp.1, index: fileIndex, token: uploadResp.fileToken)
                            }.catchErrorJustReturn(.init(status: .failed(I18n.Calendar_Upload_TryAgain), index: fileIndex))
                    }
            }
            .bind(to: attachmentVM.rxUploadInfoStream)
            .disposed(by: disposeBag)
    }

    func append(with attachment: CalendarEventAttachmentEntity) {
        rxAttachmentsPool.accept(attachment)
    }

    func delete(with index: Int) {
        var deletedArray = rxDeletedAttachments.value
        deletedArray.append(index)
        rxDeletedAttachments.accept(deletedArray)
    }
}
