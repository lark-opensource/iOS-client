//
//  DocsType.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/20.
//  从SKCommon下层

import Foundation
import LarkContainer
/// ref: https://wiki.bytedance.net/pages/viewpage.action?pageId=145986898
/// 保持 DocsType 的纯洁性，不要随意加对外接口 -- xurunkang
public enum CCMDocsType: Equatable, Hashable {
    
    private struct ConstRawValue {
        static let baseAdd: Int = 84
    }
    
    /// 文件夹
    case folder
    
    /// 回收站
    case trash
    
    /// 文档
    case doc
    
    /// 表格
    case sheet
    
    /// 我的文档
    case myFolder
    
    /// Bitable
    case bitable
    
    /// 多维表格记录快捷新建
    case baseAdd
    
    /// 思维笔记
    case mindnote
    
    /// Drive 文件
    case file
    
    /// Slide
    case slides
    
    case wiki
    /*
     后端不会下发mediaFile，mediaFile 和 SpaceEntry没有任何关系。mediaFile 只用于新建模板页面上传图片入口展示。
     由来： 新建文档模板 DocsCreateView,上传这一列有 “图片”mediaFile 、“文件”file 两个入口，弹出不同的选择视图,
     mediaFile用来标识”图片“这个入口
     实际上，两个入口选中的内容被上传后都是file类型，因此也不要用mediaFile去做其它业务的逻辑判断。
     */
    case mediaFile
    
    case imMsgFile  // IM消息中文件实体
    
    case docX
    
    case sync //同步块
    
    // wiki 目录类型，理论上不会在 space 中单独出现，必须作为 wiki 的子类型
    case wikiCatalog
    
    /// 妙计(28)
    case minutes
    
    /// 画板(38)
    case whiteboard
    
    /// 未知文件
    case unknown(_ value: Int)

    // nolint-next-line: magic number
    public static let unknownDefaultType: CCMDocsType = .unknown(999)

    // nolint-next-line: magic number
    public static let spaceShortcut: CCMDocsType = .unknown(25)

    // nolint: magic number
    // nolint: cyclomatic_complexity
    public init(rawValue: Int) {
        switch rawValue {
        case 0: do { self = .folder }
        case 1: do { self = .trash }
        case 2: do { self = .doc }
        case 3: do { self = .sheet }
        case 4: do { self = .myFolder }
        case 8: do { self = .bitable }
        case 11: do { self = .mindnote }
        case 12: do { self = .file }
        case 30: do { self = .slides }
        case 16: do { self = .wiki }
        case 22: do { self = .docX }
        case 28: do { self = .minutes }
        case 38: do { self = .whiteboard }
        case 44: do { self = .sync }
        case 111: do { self = .wikiCatalog }
        case 997: do { self = .mediaFile }
        case 998: do { self = .imMsgFile }
        case ConstRawValue.baseAdd: do { self = .baseAdd }
        default: do { self = .unknown(rawValue) }
        }
    }
    // enable-lint: magic number

    // swiftlint:enable cyclomatic_complexity
    // nolint: magic number
    public var rawValue: Int {
        switch self {
        case .folder:        return 0
        case .trash:         return 1
        case .doc:           return 2
        case .sheet:         return 3
        case .myFolder:      return 4
        case .bitable:       return 8
        case .baseAdd:       return ConstRawValue.baseAdd
        case .mindnote:      return 11
        case .file:          return 12
        case .slides:         return 30
        case .wiki:          return 16
        case .docX:          return 22
        case .sync:          return 44
        case .wikiCatalog:   return 111
        case .mediaFile:     return 997
        case .imMsgFile:     return 998
        case .minutes:       return 28
        case .whiteboard:    return 38
        case .unknown(let v):   return v
        }
    }
    // enable-lint: magic number

    /// PB原始值，对应RustPB.Basic_V1_Doc.TypeEnum （部分业务方依赖，但不希望在SpaceInterface引入rustpb, 所以提供pbRawValue）
    // nolint: magic number
    public var pbRawValue: Int {
        switch self {
        case .doc:      return 1
        case .sheet:    return 2
        case .bitable:  return 3
        case .mindnote: return 4
        case .file:     return 5
        case .wiki:     return 7
        case .docX:     return 8
        case .folder:   return 9
        case .wikiCatalog:  return 10
        case .slides:   return 11
        case .baseAdd:  return ConstRawValue.baseAdd
        case .sync:     return 13
        default:        return 0
        }
    }
    // enable-lint: magic number

    public var name: String {
        var str = ""
        switch self {
        case .folder:
            str = "folder"
        case .trash:
            str = "trash"
        case .doc:
            str = "doc"
        case .sheet:
            str = "sheet"
        case .bitable:
            str = "bitable"
        case .mindnote:
            str = "mindnote"
        case .file:
            str = "file"
        case .slides:
            str = "slides"
        case .mediaFile:
            str = "mediaFile"
        case .myFolder:
            str = "folder"
        case .wiki:
            str = "wiki"
        case .docX:
            str = "docx"
        case .sync:
            str = "sync"
        case .wikiCatalog:
            str = "catalog"
        case .whiteboard:
            str = "whiteboard"
        case .baseAdd:
            str = "baseAdd"
        default:
            str = "unknow"
        }
        return str
    }
    
    
    public init?(name: String) {
        var realName = name
        //当前方法后续会整个进行改造，不再内部依赖userResolver
        let pathConfig = try? Container.shared.getCurrentUserResolver().resolve(type: H5UrlPathConfig.self)
        if let productMap = pathConfig?.defaultH5UrlPathConfig["productMap"].dictionaryObject as? [String: String] {
            realName = productMap[name] ?? name
        }
        if let type = CCMDocsType.typeNameMap[realName] {
            self = type
        } else {
            return nil
        }
    }
    
    static let typeNameMap: [String: CCMDocsType] = {
        let supportedTypes: [CCMDocsType] = [.doc, .sheet, .bitable, .mindnote, .trash, .folder, .file, .slides, .wiki, .docX, .whiteboard, .sync, .baseAdd]
        var typeNameMap: [String: CCMDocsType] = [:]
        supportedTypes.forEach { typeNameMap[$0.name] = $0 }
        return typeNameMap
    }()
}
