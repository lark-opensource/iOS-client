//
//  DocsType+Biz.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/4/26.
//  

import Foundation
import SKFoundation
import SKResource
import SpaceInterface

/// 对接新业务时，需要留意的参数
extension DocsType {

    /// Space 的业务方们
    static public var bizTypes: [DocsType] = [.doc, .sheet, .bitable, .wiki,
                                              .file, .mindnote, .slides, .docX]
    /// 副本目前只支持doc sheet mindnote file bitable docx
    static public var copyType: [DocsType] = [.doc, .docX, .sheet, .mindnote, .file, .bitable, .slides]

    /// 导出Word&PDF&Excel，目前只支持doc sheet, docX 需要等后端上线，有FG控制
    static public var exportType: [DocsType] = [.doc, .sheet, .docX]
    
    /// 添加离线使用
    static public var offlineType: [DocsType] = [.doc, .sheet, .file]
    
    /// 关注文档更新
    static public var subscribeType: [DocsType] = [.doc, .docX, .sheet]
    
    /// pano
    static public var panoType: [DocsType] = [.doc, .sheet]
    
    
    /// 创建模版
    static public var saveAsTemplateType: [DocsType] = {
        var supportType: [DocsType] = [.doc, .sheet, .bitable]
        let mindnoteEnable = LKFeatureGating.mindnoteEnable
        if mindnoteEnable {
            supportType.append(.mindnote)
        }
        if LKFeatureGating.templateDocXSaveToCustomEnable {
            supportType.append(.docX)
        }
        return supportType
    }()

    public var isBiz: Bool {
        return DocsType.bizTypes.contains(self)
    }

    public var isSupportCopy: Bool {        
        return DocsType.copyType.contains(self)
    }

    public var isSupportExport: Bool {
        return DocsType.exportType.contains(self)
    }
    
    public var isSupportOffline: Bool {
        return DocsType.offlineType.contains(self)
    }
    
    public var isSupportSubscribe: Bool {
        return DocsType.subscribeType.contains(self)
    }
    
    public var isSupportPano: Bool {
        return DocsType.panoType.contains(self)
    }

    public var isSupportSaveAsTemplate: Bool {
        return DocsType.saveAsTemplateType.contains(self)
    }

    public var untitledString: String {
        var title = " "
        switch self {
        case .doc, .docX, .wiki, .wikiCatalog:
            title = BundleI18n.SKResource.Doc_Facade_UntitledDocument
        case .sheet:
            title = BundleI18n.SKResource.Doc_Facade_UntitledSheet
        case .folder:
            title = BundleI18n.SKResource.Doc_Facade_UntitledDocument
        case .bitable, .baseAdd:
            title = BundleI18n.SKResource.Doc_Facade_UntitledBitable
        case .mindnote:
            title = BundleI18n.SKResource.Doc_Facade_UntitledMindnote
        case .slides:
            title = BundleI18n.SKResource.LarkCCM_Slides_Untitled
        case .file, .mediaFile:
            title = BundleI18n.SKResource.Doc_Facade_UntitledFile
        case .whiteboard:
            title = BundleI18n.SKResource.LarkCCM_Docx_Board
        case .sync:
            title = BundleI18n.SKResource.LarkCCM_Docs_Comments_SyncBlock_Title
        case .trash, .myFolder, .unknown, .minutes, .imMsgFile:
            title = "Untitled " + name
            DocsLogger.info("未知类型")
        }
        return title
    }
}
