//
//  EventEditAttachmentManager.swift
//  Calendar
//
//  Created by Hongbin Liang on 2/14/23.
//

import Foundation
import RxSwift
import RxRelay
import LarkContainer
import LarkSecurityAudit

// TODO: - 梳理下数据流 by @Hongbin Liang

/// 日程编辑 - 附件管理
final class EventEditAttachmentManager: EventEditModelManager<[CalendarEventAttachmentEntity]> {

    fileprivate static let EventAttachmentSizeLimit: Int64 = 25 * 1000 * 1000

    @ScopedInjectedLazy var calendarAPI: CalendarRustAPI?
    var attachmentUploader: EventAttachmentUploader?

    private(set) var rxDisplayingAttachmentsInfo: BehaviorRelay<(attachments: [CalendarEventAttachmentEntity], needResetAll: Bool)>
    private(set) var rxUploadInfoStream: PublishRelay<AttachmentUploadInfo> = .init()
    private(set) var rxAvailableStorage: BehaviorRelay<Int64> = .init(value: EventAttachmentSizeLimit)
    private(set) var rxRiskTags: BehaviorRelay<[Server.FileRiskTag]> = .init(value: [])
    private(set) var securityAudit = SecurityAudit()

    init(userResolver: UserResolver, input: EventEditInput, identifier: String) {
        var rxModel: BehaviorRelay<[CalendarEventAttachmentEntity]>
        switch input {
        case .createWithContext, .editFromLocal, .createWebinar:
            rxModel = .init(value: [])
        case .editFrom(let pbEvent, _):
            rxModel = .init(value: pbEvent.attachments.map { .init(pb: $0) })
        case .copyWithEvent(let event, _):
            if event.source == .google || event.source == .exchange {
                rxModel = .init(value: [])
            } else {
                rxModel = .init(value: event.attachments.map { .init(pb: $0) })
            }
        case .editWebinar(pbEvent: let pbEvent, _):
            rxModel = .init(value: pbEvent.attachments.map { .init(pb: $0) })
        }

        rxDisplayingAttachmentsInfo = .init(value: (rxModel.value, true))

        super.init(userResolver: userResolver, identifier: identifier, rxModel: rxModel)

        rxDisplayingAttachmentsInfo.skip(1)
            .map { $0.attachments.filter { !$0.token.isEmpty } }
            .bind(to: rxModel)
            .disposed(by: initBag)

        rxUploadInfoStream
            .subscribe(onNext: { [weak self] updateInfo in
                guard let self = self else { return }
                let displayingInfo = self.rxDisplayingAttachmentsInfo.value
                var attachments = displayingInfo.attachments
                guard let attachment = attachments[safeIndex: updateInfo.index] else { return }

                var attachmentToUpadate = attachment
                attachmentToUpadate.token = updateInfo.token
                attachmentToUpadate.status = updateInfo.status

                attachments[updateInfo.index] = attachmentToUpadate

                self.rxDisplayingAttachmentsInfo.accept((attachments, false))
            }).disposed(by: initBag)

        rxModel.map { attachments -> Int64 in
            return attachments.filter { !$0.isDeleted }
                .reduce(Self.EventAttachmentSizeLimit) { $0 - Int64($1.size) }
        }
        .bind(to: rxAvailableStorage)
        .disposed(by: initBag)

        rxModel.map {
            $0.compactMap {
                if !$0.isDeleted && !$0.token.isEmpty {
                    return $0.token
                } else { return nil }
            }
        }.flatMap { [weak self] tokens -> Observable<[Server.FileRiskTag]> in
            guard let self = self else { return .empty() }
            return self.calendarAPI?.fetchAttachmentRiskTags(fileTokens: tokens)
                .catchErrorJustReturn([]) ?? .empty()
        }
        .bind(to: rxRiskTags)
        .disposed(by: initBag)
    }

    func appendAttachment(with attachment: CalendarEventAttachmentEntity) {
        var attachmentsShowed = rxDisplayingAttachmentsInfo.value.attachments
        attachmentsShowed.append(attachment)
        rxDisplayingAttachmentsInfo.accept((attachmentsShowed, true))
        attachmentUploader?.append(with: attachment)
    }

    func deleteAttachment(with index: Int) {
        if let attachmentToDelete = rxDisplayingAttachmentsInfo.value.attachments[safeIndex: index] {
            var attachments = rxDisplayingAttachmentsInfo.value.attachments
            var attachment = attachmentToDelete
            attachment.isDeleted = true
            attachments[index] = attachment
            rxDisplayingAttachmentsInfo.accept((attachments, true))
            attachmentUploader?.delete(with: index)
        } else {
            EventEdit.logger.error("index out of range while deleting attachments")
        }
    }
}
