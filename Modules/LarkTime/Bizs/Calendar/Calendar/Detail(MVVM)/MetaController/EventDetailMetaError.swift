//
//  EventDetailMetaError.swift
//  Calendar
//
//  Created by Rico on 2021/9/18.
//

import Foundation
import UIKit
import CalendarFoundation
import UniverseDesignEmpty
import LarkRustClient
import RustPB

enum EventDetailMetaError: Error {

    case unknown

    case selfNil

    case chatMeetingsEmpty

    case couldNotGetCalendar

    case serverPBNotExist

    case apiError(_ error: Error)

    case noPermission

    case couldNotGetEvent

    case notInEvent

    case undecryptable
}

extension EventDetailMetaError {

    func toViewStatusError() -> EventDetailViewStatus.ErrorInfo? {
        var code: Int?
        var tipImage: UIImage?
        var tips: String?
        var canRetry: Bool = true
        switch self {
        case let .apiError(error):
            let codeType = error.errorType()
            tips = error.getTitle(errorScene: .eventDetail)

            let errs: [CalendarFoundation.ErrorType] = [.inValidApplinkEventErr, .invalidCalendarEvent, .calendarEventIsRemovedOrDeletedErr, .calendarEventIsPrivacyErr]

            let encryptErrs: [CalendarFoundation.ErrorType] = [.disableEncryptEvent, .eventEncryptErr, .eventCreateEncryptErr, .eventUpdateEncryptErr, .eventDecryptErr]

            if errs.contains(codeType) {
                tips = I18n.Calendar_Share_EventExpired
                canRetry = false
                if codeType == .inValidApplinkEventErr {
                    tips = error.getServerDisplayMessage()
                }
            } else if encryptErrs.contains(codeType) {
                tipImage = UDEmptyType.ccmDocumentKeyUnavailable.defaultImage()
                canRetry = false
            } else {
                return nil
            }
        case .noPermission:
            tips = I18n.Calendar_G_NoPermissionViewEvent
            canRetry = false
        case .notInEvent:
            tips = I18n.Calendar_Share_SingleEventNoInfo
            canRetry = false
        case .undecryptable:
            tipImage = UDEmptyType.ccmDocumentKeyUnavailable.defaultImage()
            tips = I18n.Calendar_EventExpired_GreyText
            canRetry = false
        default:
            return nil
        }
        return .init(code: code ?? 0,
                     tipImage: tipImage ?? UDEmptyType.noSchedule.defaultImage(),
                     tips: tips ?? I18n.Calendar_Toast_LoadErrorToast2,
                     canRetry: canRetry)
    }

    func toViewStatusErrorOrDefault() -> EventDetailViewStatus.ErrorInfo {
        if let err = toViewStatusError() {
            return err
        } else {
            return .init(code: 0,
                         tipImage: UDEmptyType.noSchedule.defaultImage(),
                         tips: I18n.Calendar_Toast_LoadErrorToast2,
                         canRetry: true)
        }
    }
}

// RxSwift不能定义error类型，所以加一层桥接转换
extension Error {

    var asDetailError: EventDetailMetaError {
        if let error = self as? EventDetailMetaError {
            return error
        }
        if let error = self as? RCError {
            return .apiError(error)
        }
        return EventDetailMetaError.unknown
    }
}
