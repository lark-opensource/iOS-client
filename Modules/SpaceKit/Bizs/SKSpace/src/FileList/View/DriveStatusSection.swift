//
//  DriveStatusSection.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/3/1.
//
// disable-lint: magic number

import Foundation
import SKCommon
import RxDataSources

extension DriveStatusItem: IdentifiableType, Equatable {
    public var identity: String {
        return "drive_status_item_identity"
    }
    public static func == (lhs: DriveStatusItem, rhs: DriveStatusItem) -> Bool {
        return lhs.status == rhs.status
            && lhs.progress == rhs.progress
            && lhs.count == rhs.count
    }
}

extension DriveStatusItem: SpaceListData {
    public var dataType: ListDataType {
        return .driveFileUploadStatus
    }
    public var height: CGFloat {
        return 62.0
    }
    public var file: SpaceEntry? {
        return nil
    }
}
