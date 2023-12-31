//
//  DocsVersionItemData.swift
//  SKCommon
//
//  Created by ByteDance on 2022/9/9.
//

import SKFoundation
import SKResource
import SpaceInterface

extension DocsType {
    public var supportVersionInfo: Bool {
        var validTypes: Set<DocsType> = [.docX]
        if UserScopeNoChangeFG.LJW.sheetVersionEnabled {
            validTypes.insert(.sheet)
        }
        return validTypes.contains(self)
    }
}

public struct CurrentVersionInfo {
    let hasMore: Bool
    let pageToken: String?
    
    public init(hasMore: Bool, pageToken: String?) {
        self.hasMore = hasMore
        self.pageToken = pageToken
    }
}

public final class DocsVersionItemData: Hashable {
    public var parent_token: String
    public var versionToken: String
    public var name: String
    public var version: String
    public var create_time: UInt64?
    public var update_time: UInt64?
    public var creator_name: String?
    public var creator_name_en: String?
    public var aliasInfo: UserAliasInfo?
    
    public init(docToken: String,
                versionToken: String,
                name: String,
                version: String,
                createtime: UInt64? = 0,
                updatetime: UInt64? = 0,
                creatorName: String? = nil,
                creatorNameEn: String? = nil,
                aliasInfo: UserAliasInfo? = nil) {
        self.parent_token = docToken
        self.versionToken = versionToken
        self.name = name
        self.version = version
        self.create_time = createtime
        self.update_time = updatetime
        self.creator_name = creatorName
        self.creator_name_en = creatorNameEn
        self.aliasInfo = aliasInfo
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(versionToken)
    }
        
    public static func == (lhs: DocsVersionItemData, rhs: DocsVersionItemData) -> Bool {
        return lhs.versionToken == rhs.versionToken
    }
    
    public var localizedCreateName: String {
        if let displayName = aliasInfo?.currentLanguageDisplayName {
            return displayName
        }
        switch DocsSDK.currentLanguage {
        case .zh_CN, .zh_HK, .zh_TW:
            return creator_name ?? ""
        default:
            return creator_name_en ?? ""
        }
    }
}

extension DocsVersionItemData: DocsVersionSavedCellPresenter {
    var mainTitle: String {
        return self.name
    }
    
    var subTitle: String {
        let time = Double(self.create_time!).stampDateFormatter
        let realStr = self.localizedCreateName
        return BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_View_SavernTime_Tooltip(realStr, time)
    }
}
