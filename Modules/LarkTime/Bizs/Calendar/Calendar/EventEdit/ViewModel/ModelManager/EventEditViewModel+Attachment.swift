//
//  EventEditViewModel+Attachment.swift
//  Calendar
//
//  Created by Hongbin Liang on 2/27/23.
//

import Foundation
import CalendarFoundation

// MARK: Setup Attachment

extension EventEditViewModel {

    var attachmentModel: EventEditAttachmentManager? {
        self.models[EventEditModelType.attachment] as? EventEditAttachmentManager
    }

    func makeAttachmentModel() -> EventEditModelManager<[CalendarEventAttachmentEntity]> {
        let attachment_model = EventEditAttachmentManager(userResolver: self.userResolver,
                                                          input: self.input,
                                                          identifier: EventEditModelType.attachment.rawValue)
        attachment_model.initMethod = { [weak self, weak attachment_model] observer in
            guard let self = self, let attachment_model = attachment_model else {
                assertionFailureLog()
                return
            }
            attachment_model.attachmentUploader = .init(userResolver: self.userResolver,
                                                        attachmentVM: attachment_model,
                                                        creatorCalendarIdGetter: { [weak self] in
                self?.eventModel?.rxModel?.value.creatorCalendarId ?? ""
            })
            observer.onCompleted()
        }
        return attachment_model
    }
}
