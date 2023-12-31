//
//  DocItem.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/8/12.
//

import Foundation
import LarkTimeFormatUtils
import UIKit
import SwiftUI

public struct DocItem: Codable, Equatable {

    /// 文档 token，用作为其他请求参数
    public var token: String

    /// 文档名称
    public var title: String

    /// 文档类型
    public var type: Int

    /// 文档链接
    public var url: String

    /// 文档最近打开时间
    public var activityTime: Double?

    /// 附加信息
    public var extra: DocItemExtra?

    /// 封面图链接
    public var cover: String?

    public var appLink: URL? {
        guard let link = URL(string: WidgetLink.docsDetail) else { return nil }
        return link.appendingQueryParameters(["url": url])
    }

    public var realType: Int {
        if type == 16, let subtype = extra?.wikiSubtype {
            return subtype
        } else {
            return type
        }
    }

    public var docType: DocType {
        switch realType {
        case 0:         return .folder
        case 2, 22:     return .doc
        case 3, 15:     return .sheet
        case 8:         return .bitable
        case 11:        return .mindnote
        case 12:
            guard let suffix = getFileSuffix() else { return .general }
            switch suffix {
            case "pdf":                             return .pdf
            case "jpg", "jpeg", "png":              return .image
            case "dot", "dotx", "docx", "pages", "wps":    return .word
            case "xls", "xlsx", "numbers", "et":          return .excel
            case "ppt", "pptx", "key":              return .ppt
            default:                                return .general
            }
        default:        return .general
        }
    }

    public var typeIconName: String {
        return docType.iconName
    }

    public var displayName: String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            return trimmedTitle
        }
        switch docType {
        case .folder:   return BundleI18n.LarkWidget.CreationMobile_Common_UntitledFolder
        case .doc:      return BundleI18n.LarkWidget.Doc_Facade_UntitledDocument
        case .sheet:    return BundleI18n.LarkWidget.Doc_Facade_UntitledSheet
        case .bitable:  return BundleI18n.LarkWidget.Doc_Facade_UntitledBitable
        case .mindnote: return BundleI18n.LarkWidget.Doc_Facade_UntitledMindnote
        default:        return BundleI18n.LarkWidget.Doc_Facade_UntitledFile
        }
    }

    public var lastOpenTimeDesc: String {
        var lastOpenDate = Date()
        if let lastOpenTime = activityTime {
            lastOpenDate = Date(timeIntervalSince1970: lastOpenTime)
        }
        var options = TimeFormatUtils.defaultOptions
        options.is12HourStyle = false
        options.timePrecisionType = .minute
        options.dateStatusType = .relative
        options.timeFormatType = .long
        options.lang = WidgetI18n.language
        let timeString = TimeFormatUtils.formatDateTime(from: lastOpenDate, with: options)
        return BundleI18n.LarkWidget.Doc_List_LastOpenTime(timeString).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    enum CodingKeys: String, CodingKey {
        case url
        case type
        case extra
        case title = "name"
        case token = "obj_token"
        case activityTime = "open_time"
    }

    public init(token: String, title: String, type: Int, url: String, activityTime: Double? = nil) {
        self.token = token
        self.title = title
        self.type = type
        self.url = url
        self.activityTime = activityTime
    }

    func getFileSuffix() -> String? {
        guard title.contains("."),
                let suffix = title.split(separator: ".").last else { return nil }
        return String(suffix).lowercased()
    }
}

public struct DocItemExtra: Codable, Equatable {

    public var wikiSubtype: Int?

    public init(subType: Int) {
        self.wikiSubtype = subType
    }

    enum CodingKeys: String, CodingKey {
        case wikiSubtype = "wiki_subtype"
    }
}

public enum DocType {
    case general
    case folder
    case doc
    case sheet
    case bitable
    case mindnote
    case pdf
    case image
    case word
    case excel
    case ppt

    public var iconName: String {
        switch self {
        case .general:  return "icon_file-link-otherfile_outlined"
        case .folder:   return "icon_folder_outlined"
        case .doc:      return "icon_file-link-docx_outlined"
        case .sheet:    return "icon_file-link-sheet_outlined"
        case .bitable:  return "icon_file-link-bitable_outlined"
        case .mindnote: return "icon_file-link-mindnote_outlined"
        case .pdf:      return "icon_file-link-pdf_outlined"
        case .image:    return "icon_image_outlined"
        case .word:     return "icon_file-link-word2_outlined"
        case .excel:    return "icon_file-link-excel_outlined"
        case .ppt:      return "icon_file-link-ppt_outlined"
        }
    }

    public var iconNameFilled: String {
        switch self {
        case .general:  return "icon_wiki-otherfile_colorful"
        case .folder:   return "icon_file-folder_colorful"
        case .doc:      return "icon_file-docx_colorful"
        case .sheet:    return "icon_file-sheet_colorful"
        case .bitable:  return "icon_file-bitable_colorful"
        case .mindnote: return "icon_file-mindnote_colorful"
        case .pdf:      return "icon_file-pdf_colorful"
        case .image:    return "icon_image-square_colorful"
        case .word:     return "icon_file-word_colorful"
        case .excel:    return "icon_file-excel_colorful"
        case .ppt:      return "icon_file-ppt_colorful"
        }
    }

    @available(iOS 13.0, *)
    public var themeColor: Color {
        switch self {
        case .general:  return UDColor.B100
        case .folder:   return UDColor.Y100
        case .doc:      return UDColor.B100
        case .sheet:    return UDColor.G100
        case .bitable:  return UDColor.P100
        case .mindnote: return UDColor.W100
        case .pdf:      return UDColor.R100
        case .image:    return UDColor.O100
        case .word:     return UDColor.B100
        case .excel:    return UDColor.G100
        case .ppt:      return UDColor.O100
        }
    }
}
