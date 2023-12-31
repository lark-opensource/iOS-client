//
//  CCMTypeFilterOption.swift
//  CCMMod
//
//  Created by Weston Wu on 2023/5/17.
//

import Foundation
import SKFoundation
import RustPB
import SpaceInterface
import SKCommon
import SKResource

private typealias R = SKResource.BundleI18n.SKResource

enum CCMTypeFilterOption: Equatable, Hashable, CaseIterable {
    // Document Type
    case document
    case sheet
    case mindnote
    case base
    // TODO: 待大搜支持细分drive类型后移除此选项
    case file
    // File Type
    case video
    case audio
    case image
    case pdf
    case otherFile
    // Folder
    case folder

    static var allDocumentTypes: [CCMTypeFilterOption] {
        [
            .document,
            .sheet,
            .mindnote,
            .base,
            .file
        ]
    }

    static var allFileTypes: [CCMTypeFilterOption] {
        [
            .video,
            .audio,
            .image,
            .pdf,
            .otherFile
        ]
    }

    var displayTitle: String {
        switch self {
        case .document:
            return DocsType.docX.i18Name
        case .sheet:
            return DocsType.sheet.i18Name
        case .mindnote:
            return DocsType.mindnote.i18Name
        case .base:
            return DocsType.bitable.i18Name
        case .file:
            return DocsType.file.i18Name
        case .video:
            return R.Doc_Search_Videos
        case .audio:
            return R.Doc_Search_Audio
        case .image:
            return R.Doc_Search_Images
        case .pdf:
            return R.Doc_Search_PDFS
        case .otherFile:
            return R.Doc_Search_Other
        case .folder:
            return DocsType.folder.i18Name
        }
    }

    var searchType: [Basic_V1_Doc.TypeEnum] {
        switch self {
        case .document:
            return [.doc, .docx]
        case .sheet:
            return [.sheet]
        case .mindnote:
            return [.mindnote]
        case .base:
            return [.bitable]
        case .file:
            return [.file]
        case .video:
            spaceAssertionFailure("video sub file type unsupport")
            return [.file]
        case .audio:
            spaceAssertionFailure("video sub file type unsupport")
            return [.file]
        case .image:
            spaceAssertionFailure("video sub file type unsupport")
            return [.file]
        case .pdf:
            spaceAssertionFailure("video sub file type unsupport")
            return [.file]
        case .otherFile:
            spaceAssertionFailure("video sub file type unsupport")
            return [.file]
        case .folder:
            return [.folder]
        }
    }
}
