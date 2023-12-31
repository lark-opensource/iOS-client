//
//  MinutesStatus.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/2/28.
//

import Foundation

public struct MinutesFetchingDataStatus: OptionSet, Codable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let empty = MinutesFetchingDataStatus(rawValue: 0)
    static let basicInfo = MinutesFetchingDataStatus(rawValue: 1 << 0)
    static let participants = MinutesFetchingDataStatus(rawValue: 1 << 1)
    static let files = MinutesFetchingDataStatus(rawValue: 1 << 2)
    static let subtitles = MinutesFetchingDataStatus(rawValue: 1 << 3)
    static let keywords = MinutesFetchingDataStatus(rawValue: 1 << 4)
    static let comments = MinutesFetchingDataStatus(rawValue: 1 << 5)
    static let summaries = MinutesFetchingDataStatus(rawValue: 1 << 6)
    static let allInfo: MinutesFetchingDataStatus = [basicInfo, summaries]
    static let allData: MinutesFetchingDataStatus = [subtitles]
}

public enum MinutesInfoStatus: Equatable {
    public static func ==(lhs: MinutesInfoStatus, rhs: MinutesInfoStatus) -> Bool {
        switch (lhs, rhs) {
        case (.unkown, .unkown),
             (.ready, .ready),
             (.authFailed, .authFailed),
             (.noPermission, .noPermission),
             (.pathNotFound, .pathNotFound),
             (.resourceDeleted, .resourceDeleted),
             (.serverError, .serverError),
             (.otherError, .otherError),
             (.processing, .processing),
             (.complete, .complete),
             (.transcoding, .transcoding),
             (.audioRecording, .audioRecording):
            return true
        case (.fetchingData(let lstatus), .fetchingData(let rstatus)):
            return lstatus == rstatus
        default:
            return false
        }
    }

    case unkown
    case fetchingData(MinutesFetchingDataStatus)
    case ready
    case authFailed
    case noPermission
    case pathNotFound
    case resourceDeleted
    case serverError
    case transcoding
    case complete
    case audioRecording
    case processing
    case otherError(Error)

    public func isFetching() -> Bool {
        switch self {
        case .fetchingData:
            return true
        default:
            return false
        }
    }

    public func isFinal() -> Bool {
        switch self {
        case .unkown, .fetchingData, .complete, .processing:
            return false
        default:
            return true
        }
    }

    public func isOtherError() -> Bool {
        switch self {
        case .otherError:
            return true
        default:
            return false
        }
    }

    public func updatingFetchingStatus(with status: MinutesFetchingDataStatus) -> MinutesInfoStatus {
        switch self {
        case .fetchingData(let old):
            let newStatus: MinutesFetchingDataStatus = [old, status]
            if newStatus.contains(.allInfo) {
                return .ready
            } else {
                return .fetchingData(newStatus)
            }
        case .ready, .unkown, .complete, .processing:
            return .fetchingData(status)
        default:
            return self
        }
    }

    static func status(from: Error) -> MinutesInfoStatus {
        if let error = from as? ResponseError {
            switch error {
            case .authFailed:
                return .authFailed
            case .noPermission:
                return .noPermission
            case .pathNotFound:
                return .pathNotFound
            case .resourceDeleted:
                return .resourceDeleted
            case .serverError:
                return .serverError
            default:
                return .otherError(from)
            }
        } else {
            return .otherError(from)
        }
    }

    public static func status(from: ObjectStatus, objectType type: ObjectType? = nil) -> MinutesInfoStatus {
        switch from {
        case .deleted, .trash:
            return .resourceDeleted
        case .complete:
            return .complete
        case .failed, .fileCorrupted:
            return .pathNotFound
        case .audioRecording, .audioRecordPause:
            return .audioRecording
        case .waitASR, .audioRecordUploading, .audioRecordCompleteUpload, .audioRecordUploadingForced:
            return .processing
        case .cutting:
            return .processing
        default:
            if type != .recording {
                return .transcoding
            } else {
                return .processing
            }
        }
    }
}

public enum MinutesDataStatus: Equatable {
    public static func ==(lhs: MinutesDataStatus, rhs: MinutesDataStatus) -> Bool {
        switch (lhs, rhs) {
        case (.unkown, .unkown),
             (.ready, .ready),
             (.otherError, .otherError):
            return true
        case (.fetchingData(let lstatus), .fetchingData(let rstatus)):
            return lstatus == rstatus
        default:
            return false
        }
    }

    case unkown
    case fetchingData(MinutesFetchingDataStatus)
    case ready
    case otherError(Error)

    public func isFetching() -> Bool {
        switch self {
        case .fetchingData:
            return true
        default:
            return false
        }
    }

    public func isError() -> Bool {
        switch self {
        case .otherError:
            return true
        default:
            return false
        }
    }

    public func updatingFetchingStatus(with status: MinutesFetchingDataStatus) -> MinutesDataStatus {
        switch self {
        case .fetchingData(let old):
            let newStatus: MinutesFetchingDataStatus = [old, status]
            if newStatus.contains(.allData) {
                return .ready
            } else {
                return .fetchingData(newStatus)
            }
        case .unkown:
            return .fetchingData(status)
        default:
            return self
        }
    }

}
