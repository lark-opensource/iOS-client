//
//  FilterItem.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/5/30.
//  

import SKFoundation
import SKResource
import SpaceInterface

public struct FilterItem: Codable, Equatable {
    enum EncodedKeys: String, CodingKey {
        case isSelected, lastLabel, filterType
    }
    //   1. 文档、表格、数据表格、演示文稿、思维笔记
    public enum FilterType: Int {
        case all = 0
        case doc
        case sheet
        case bitable
        case slides
        case mindnote
        case file
        case document
        case wiki
        case folder

        public var reportName: String {
            switch self {
            case .all:
                return "all"
            case .document:
                return "document"
            case .file:
                return "file"
            case .doc:
                return "doc"
            case .sheet:
                return "sheet"
            case .bitable:
                return "bitable"
            case .slides:
                return "slides"
            case .mindnote:
                return "mindnote"
            case .wiki:
                return "wiki"
            case .folder:
                return "folder"
            }
        }
        public var reportNameV2: String {
            switch self {
            case .all:
                return "all"
            case .document:
                return "document"
            case .file:
                return "drive"
            case .doc:
                return "docs"
            case .sheet:
                return "sheets"
            case .bitable:
                return "bitable"
            case .slides:
                return "slides"
            case .mindnote:
                return "mindnotes"
            case .wiki:
                return "wiki"
            case .folder:
                return "folder"
            }
        }
    }

    public init(isSelected: Bool, filterType: FilterType) {
        self.isSelected = isSelected

        self.filterType = filterType
    }
    public var filterType: FilterType
    public var isSelected = false

    public var lastLabel = ""

    /*
        即请求参数中的值obj_type
     */
    public var currentObjTypes: [DocsType] {
        return FilterItem.convertType(filterType: filterType)
    }

    public static func == (lhs: FilterItem, rhs: FilterItem) -> Bool {
        lhs.filterType == rhs.filterType
    }

    public static func convertType(filterType: FilterType) -> [DocsType] {

        switch filterType {
        case .document:
            return [.doc, .sheet, .bitable, .mindnote, .slides] //  obj_type=2&obj_type=3&obj_type=8&obj_type=11&obj_type=15
        case .file:
            return [.file] // 同时：- forbidden_file_type 字段传：photo, file_type 不传,obj_type=12
        case .all:
            return []  // obj_type,file_type、forbidden_file_type，不传，不传的意思是，没有这个key
        case .doc:
            return [.doc, .docX]
        case .sheet:
            return [.sheet]
        case .bitable:
            return [.bitable]
        case .slides:
            return [.slides]
        case .mindnote:
            return [.mindnote]
        case .wiki:
            return [.wiki]
        case .folder:
            return [.folder]
        }
    }

    public var displayName: String {
        switch filterType {
        case .all:
            return BundleI18n.SKResource.Doc_List_Filter_All
        case .document:
            return BundleI18n.SKResource.Doc_List_FIlter_Document
        case .file:
            return BundleI18n.SKResource.LarkCCM_Docs_LocalFile_Menu_Mob
        case .doc:
            return  BundleI18n.SKResource.Doc_Facade_Document
        case .sheet:
            return  BundleI18n.SKResource.Doc_Facade_CreateSheet
        case .bitable:
            return  BundleI18n.SKResource.Doc_List_Filter_Bitable
        case .slides:
            return  BundleI18n.SKResource.LarkCCM_Slides_ProductName
        case .mindnote:
            return  BundleI18n.SKResource.Doc_Facade_MindNote
        case .wiki:
            return BundleI18n.SKResource.Doc_Facade_Wiki
        case .folder:
            return BundleI18n.SKResource.Doc_Facade_Folder
        }
    }

    public var reportName: String {
        return filterType.reportName
    }

    public var typeName: String {
        return BundleI18n.SKResource.Doc_List_Filter_By_Type
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: EncodedKeys.self)
        isSelected = try values.decode(Bool.self, forKey: .isSelected)
        lastLabel = try values.decode(String.self, forKey: .lastLabel)
        let typeRaw = try values.decode(Int.self, forKey: .filterType)
        filterType = FilterType(rawValue: typeRaw) ?? .all
    }

    public func encode(to encoder: Encoder) throws {
        do {
            var container = encoder.container(keyedBy: EncodedKeys.self)
            try container.encode(isSelected, forKey: .isSelected)
            try container.encode(filterType.rawValue, forKey: .filterType)
            try container.encode(lastLabel, forKey: .lastLabel)
        } catch {
            DocsLogger.error("error in encode filter item", extraInfo: nil, error: error, component: nil)
        }
    }
}
