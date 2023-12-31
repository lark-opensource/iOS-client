//
//  AttachmentEntity.swift
//  Calendar
//
//  Created by sunxiaolei on 2019/11/12.
//

import CTFoundation
import LarkTimeFormatUtils
import UniverseDesignColor
import UIKit

public enum UploadStatus {
    case awaiting
    case uploading(_ progress: Float)
    case success
    case failed(_ alertTip: String)
    case cancel

    static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.awaiting, .awaiting):
                return true
            case (.uploading, .uploading):
                return true
            case (.success, .success):
                return true
            case (.failed, .failed):
                return true
            case (.cancel, .cancel):
                return true
            default:
                return false
            }
        }
}

public struct AttachmentUploadInfo {
    public let index: Int
    public let token: String
    public let size: UInt64
    public var status: UploadStatus

    public init(status: UploadStatus, index: Int = -1, token: String = "", size: UInt64 = 0) {
        self.index = index
        self.token = token
        self.size = size
        self.status = status
    }
}

struct CalendarEventAttachmentEntity: Equatable {
    static func == (lhs: CalendarEventAttachmentEntity, rhs: CalendarEventAttachmentEntity) -> Bool {
        return lhs.token == rhs.token
    }

    var pb: CalendarEventAttachment

    var fileRiskTag = Server.FileRiskTag()

    var token: String {
        get { pb.fileToken }
        set { pb.fileToken = newValue }
    }

    var localPath: String { pb.localPath }

    var isDeleted: Bool {
        get { pb.isDeleted }
        set { pb.isDeleted = newValue }
    }
    
    var googleDriveLink: String {
        return pb.googleDriveLink
    }
    
    var urlLink: String {
        return pb.urlLink
    }

    var status: UploadStatus

    var index: Int?

    init(pb: CalendarEventAttachment) {
        self.pb = pb
        status = .success
    }

    init(name: String, path: String, fileSize: UInt64, isDeleted: Bool = false, type: AttachmentType = .local, status: UploadStatus = .awaiting) {
        var pb = CalendarEventAttachment()
        pb.isDeleted = isDeleted
        pb.type = type
        pb.fileSize = String(fileSize)
        pb.name = name
        pb.localPath = path
        pb.expireTime = 0
        self.pb = pb
        self.status = status
    }
}

extension CalendarEventAttachmentEntity: AttachmentUIData {
    var type: CalendarEventAttachment.TypeEnum {
        return pb.type
    }
    
    var isFileRisk: Bool {
        return fileRiskTag.isRiskFile ?? false
    }

    var name: String {
        return pb.name
    }

    var size: UInt64 {
        if let number = UInt64(pb.fileSize) {
            return number
        }
        return 0
    }

    var isLargeAttachments: Bool {
        return pb.type == .largeAttachment
    }

    var expireTip: (String?, UIColor) {
        guard isLargeAttachments else { return (nil, .clear) }

        let expireTime = pb.expireTime
        let currentTime = Date().timeIntervalSince1970
        let today = JulianDayUtil.julianDay(from: Date(), in: .current)
        let expireDay = JulianDayUtil.julianDay(from: expireTime, in: .current)
        let expireDayInterval = expireDay - today

        if Double(expireTime) < currentTime {
            // 已失效
            return (I18n.Calendar_Attachments_Expired, UDColor.functionDangerContentDefault)
        } else if expireTime < JulianDayUtil.endOfDay(for: today, in: .current) {
            // 今天内失效
            return (I18n.Calendar_Attachments_ExpiredToday, UDColor.functionWarningContentPressed)
        } else if expireDayInterval <= 15 {
            // n天后失效
            let color = (expireDayInterval <= 3) ? UDColor.functionWarningContentPressed : UDColor.textPlaceholder
            return (I18n.Calendar_Attachments_DaysExpired(day: expireDayInterval), color)
        } else {
            // xx/xx/xx 失效
            let option = Options(timeFormatType: .long, datePrecisionType: .day, dateStatusType: .absolute)
            let expireDate = Date(timeIntervalSince1970: Double(expireTime))
            let dateString = TimeFormatUtils.formatDate(from: expireDate, with: option)
            return (I18n.Calendar_Attachment_ExpireDateFuture(ExpireDate: dateString), UDColor.textPlaceholder)
        }
    }

    private var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: TimeFormatUtils.languageIdentifier)
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }
}

extension CalendarEventAttachmentEntity {
    static func sizeString(for byteCount: UInt64) -> String {
        var size = Double(byteCount)
        let unit = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB", "BB"]
        var index: Int = 0
        while size >= 1024 && (index + 1) < unit.count {
            size /= 1024
            index += 1
        }
        return String(format: "%.1f", Double(size)) + unit[index]
    }

    func sizeString() -> String {
        let totalSize = Self.sizeString(for: size)

        var ratioToCompute: Float = 1
        if case .uploading(let uploadingRatio) = status {
            ratioToCompute = uploadingRatio
        }

        if ratioToCompute == 1 {
            return totalSize
        } else if let partialSize = UInt64(exactly: ratioToCompute * Float(size)) {
            return "\(Self.sizeString(for: partialSize)) / \(totalSize)"
        } else {
            EventEdit.logger.error("size transform error \(ratioToCompute) \(size)")
            return "\(Self.sizeString(for: 0)) / \(totalSize)"
        }
    }
}
