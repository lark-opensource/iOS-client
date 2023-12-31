//
//  FileOperateDebugEntityType.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2022/12/22.
//

import Foundation
import ServerPB

enum FileOperateDebugEntityType: String, CaseIterable {
    case unknown

    case any

    case user

    case imImage

    case imVideo

    case imFile

    /// doc
    case ccmDoc

    /// sheet
    case ccmSheet

    /// bitable
    case ccmBitable

    /// mindnote
    case ccmMindnote

    /// doc-file
    case ccmFile

    /// slide
    case ccmSlide
}

extension FileOperateDebugEntityType {
    var entityType: ServerPB_Authorization_EntityType {
        switch self {
        case .unknown:
            return .unknown
        case .any:
            return .any
        case .user:
            return .user
        case .imImage:
            return .imImage
        case .imVideo:
            return .imVideo
        case .imFile:
            return .imFile
        case .ccmDoc:
            return .ccmDoc
        case .ccmSheet:
            return .ccmSheet
        case .ccmBitable:
            return .ccmBitable
        case .ccmMindnote:
            return .ccmMindnote
        case .ccmFile:
            return .ccmFile
        case .ccmSlide:
            return .ccmSlide
        }
    }
}
