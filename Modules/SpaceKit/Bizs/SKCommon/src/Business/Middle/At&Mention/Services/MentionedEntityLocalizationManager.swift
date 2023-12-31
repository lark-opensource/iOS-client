//
//  MentionedEntityLocalizationManager.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/5/13.
//  


import Foundation
import SKResource
import SKFoundation
import ThreadSafeDataStructure

/// mention实体国际化工具
final class MentionedEntityLocalizationManager {
    
    /// key: tenantID + userId 唯一标识,   value: 当前类实例
    private static var shared: SafeDictionary<String, MentionedEntityLocalizationManager> = [:] + .readWriteLock
    
    /// 用户信息，key: userId,   value: UserModel
    private var userCache = NSCache<NSString, MentionedEntity.UserModel>()
    
    /// 文档信息，key: token,   value: DocModel
    private var docsCache = NSCache<NSString, MentionedEntity.DocModel>()
    
    private init() {}
}

extension MentionedEntityLocalizationManager {
    
    static var current: MentionedEntityLocalizationManager {
        let id: String
        if let tenantID = User.current.info?.tenantID,
           let userId = User.current.info?.userID,
            !tenantID.isEmpty, !userId.isEmpty {
            id = "\(tenantID)_\(userId)"
        } else {
            id = "\(Self.self)_defaultId"
        }
        if let instance = shared[id] {
            return instance
        } else {
            let newInstance = MentionedEntityLocalizationManager()
            shared.updateValue(newInstance, forKey: id)
            return newInstance
        }
    }
}

extension MentionedEntityLocalizationManager {
    
    func updateUsers(_ users: [String: MentionedEntity.UserModel]) {
        for (id, user) in users {
            userCache.setObject(user, forKey: (id as NSString))
        }
    }
    
    func getUserById(_ id: String) -> MentionedEntity.UserModel? {
        return userCache.object(forKey: (id as NSString))
    }
}

extension MentionedEntityLocalizationManager {
    
    func updateDocMetas(_ metas: [String: MentionedEntity.DocModel]) {
        for (token, item) in metas {
            docsCache.setObject(item, forKey: (token as NSString))
        }
    }
    
    func getDocMetaByToken(_ token: String) -> MentionedEntity.DocModel? {
        return docsCache.object(forKey: (token as NSString))
    }
}

extension MentionedEntityLocalizationManager {
    
    /// 创建实例，仅用于单测
    static func createInstance() -> MentionedEntityLocalizationManager {
        return MentionedEntityLocalizationManager.init()
    }
}

extension MentionedEntity.UserModel {
    
    /// 国际化后的别名
    public var displayName: String {
        if let displayName = aliasInfo?.currentLanguageDisplayName {
            return displayName
        } else {
            return en_name
        }
    }
    
    /// 根据语言设置显示的名字
    public var localizedName: String {
        // TODO: displayName 待后续接入
//        displayName
        switch DocsSDK.currentLanguage {
        case .zh_CN, .zh_HK, .zh_TW:
            return cn_name
        default:
            return en_name
        }

    }
}

extension MentionedEntity.DocModel {
    
    /// 根据语言设置显示的标题
    public var localizedTitle: String? {
        let lang = DocsSDK.currentLanguage
        guard let title = title, title.isEmpty else { // 为空字符串则需要国际化
            DocsLogger.info("origin-title is empty:\(String(describing: self.title?.isEmpty))")
            return nil
        }
        let result: String
        switch doc_type {
        case .myFolder, .trash, .unknown, .minutes, .whiteboard:
            DocsLogger.info("no localized title for type: \(doc_type)")
            result = ""
        case .doc, .docX, .wiki, .wikiCatalog, .folder:
            result = BundleI18n.SKResource.Doc_Facade_UntitledDocument(lang: lang)
        case .sheet:
            result = BundleI18n.SKResource.Doc_Facade_UntitledSheet(lang: lang)
        case .bitable, .baseAdd:
            result = BundleI18n.SKResource.Doc_Facade_UntitledBitable(lang: lang)
        case .mindnote:
            result = BundleI18n.SKResource.Doc_Facade_UntitledMindnote(lang: lang)
        case .file, .mediaFile, .imMsgFile:
            result = BundleI18n.SKResource.Doc_Facade_UntitledFile(lang: lang)
        case .slides:
            result = BundleI18n.SKResource.LarkCCM_Slides_Untitled(lang: lang)
        case .sync:
            result = BundleI18n.SKResource.LarkCCM_Docs_Comments_SyncBlock_Title(lang: lang)
        }
        return result
    }
}
