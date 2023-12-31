//
//  DocFilterType.swift
//  LarkSearch
//
//  Created by SuPeng on 5/5/19.
//

import UIKit
import Foundation
import LarkModel
import LarkSDKInterface

public extension DocFormatType {
    static func filterType(with filterString: String) -> DocFormatType {
        return DocFormatType.allCases.first(where: { $0.filterString == filterString }) ?? .all
    }

    static func filterTypes(with filterStrings: [String]) -> [DocFormatType] {
        let filterSet = Set(filterStrings)
        let types = filterSet.map { DocFormatType.filterType(with: $0) }
        if types.contains(.all) {
            return [.all]
        } else if types.count == DocFormatType.allCases.count - 1 {
            return [.all]
        } else {
            return types
        }
    }

    var filterString: String {
        switch self {
        case .all:
            return ""
        case .doc:
            return "doc"
        case .sheet:
            return "sheet"
        case .slide:
            return "slide"
        case .slides:
            return "slides"
        case .mindNote:
            return "mindnote"
        case .bitale:
            return "bitable"
        case .file:
            return "file"
        @unknown default:
            assert(false, "new value")
            return "unknown"
        }
    }

    var title: String {
        switch self {
        case .all:
            return BundleI18n.LarkSearchFilter.Lark_Legacy_All
        case .doc:
            return BundleI18n.LarkSearchFilter.Lark_Search_DocSearchFilter
        case .sheet:
            return BundleI18n.LarkSearchFilter.Lark_Search_SheetSearchFilter
        case .slide:
            return BundleI18n.LarkSearchFilter.Lark_Search_SlideSearchFilter
        case .slides:
            return BundleI18n.LarkSearchFilter.Lark_ASLSearch_SearchDocsTab_FilterOption_Slides
        case .mindNote:
            return BundleI18n.LarkSearchFilter.Lark_Search_MindNoteSearchFilter
        case .bitale:
            return BundleI18n.LarkSearchFilter.Lark_Search_BitableSearchFilter
        case .file:
            return BundleI18n.LarkSearchFilter.Lark_Search_FileSearchFilter
        @unknown default:
            fatalError("new value")
        }
    }

    var image: UIImage {
        switch self {
        case .all:
            return Resources.doc_filter_all
        case .doc:
            return Resources.doc_filter_doc
        case .sheet:
            return Resources.doc_filter_sheet
        case .slide:
            return Resources.doc_filter_slide
        case .slides:
            return Resources.doc_filter_slides
        case .mindNote:
            return Resources.doc_filter_mindnote
        case .bitale:
            return Resources.doc_filter_bitable
        case .file:
            return Resources.doc_filter_file
        @unknown default:
            fatalError("new value")
        }
    }

    // 埋点信息
    var trackInfo: String {
        switch self {
        case .all:
            return "all"
        case .doc:
            return "doc"
        case .sheet:
            return "sheet"
        case .slide:
            return "slide"
        case .slides:
            return "slides"
        case .mindNote:
            return "mindnote"
        case .bitale:
            return "bitable"
        case .file:
            return "file"
        @unknown default:
            assert(false, "new value")
            return "unknown"
        }
    }
}
