//
//  WikiHomePageSpaceCollectionViewCell.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/9/26.
//  

import UIKit
import SnapKit
import SKCommon
import SKResource
import SKFoundation

public protocol WikiHomePageSpaceCollectionProtocol {
    var displayTitle: String { get }
    var displayDescription: String { get }

    var displayBackgroundColor: UIColor { get }
    var displayBackgroundImageURL: URL? { get }
    var coverImageURL: URL? { get }

    var displayIsDarkStyle: Bool { get }

    var displayIsStar: Bool { get }

    var isPublic: Bool { get }
    
    var isOpenSharing: Bool { get }

    func getDisplayTag(preferTagFromServer: Bool,
                       currentTenantID: String?) -> String?
}

public protocol WikiSpaceCellRepresentable: UICollectionViewCell {
    func updateUI(item: WikiHomePageSpaceCollectionProtocol)
    func set(enable: Bool)
}

extension WikiSpace: WikiHomePageSpaceCollectionProtocol {
    public var coverImageURL: URL? {
        return cover.coverURL
    }

    public var displayTitle: String {
        let libraryName = UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? BundleI18n.SKResource.LarkCCM_NewCM_Personal_Title : BundleI18n.SKResource.LarkCCM_CM_MyLib_Menu
        return isLibraryOwner ? libraryName : spaceName
    }

    public var displayDescription: String {
        if wikiDescription.isEmpty {
            return BundleI18n.SKResource.Doc_Wiki_Home_DescriptionEmptyText
        } else {
            return wikiDescription
        }
    }

    public var displayIsStar: Bool {
        return isStar ?? false
    }

    public var displayBackgroundColor: UIColor {
        return cover.backgroundColor
    }

    public var displayBackgroundImageURL: URL? {
        return cover.thumbnailURL
    }

    public var displayIsDarkStyle: Bool {
        return cover.isDarkStyle
    }
    
    public var isOpenSharing: Bool {
        return sharingType == .open
    }

    /// 计算需要展示的 tag 文案
    /// - Parameters:
    ///   - preferTagFromServer: 是否优先使用后端返回的 tag 信息
    ///   - currentTenantID: 当前用户的 tenantID，与当前知识库租户不一致时，屏蔽公开标签
    /// - Returns: tag 文案，nil 表示不需要展示
    public func getDisplayTag(preferTagFromServer: Bool,
                              currentTenantID: String?) -> String? {
        if preferTagFromServer, let displayTag {
            // 用后端返回的数据展示
            if displayTag.isPublicType,
               let currentTenantID,
               let tenantID,
               currentTenantID != tenantID {
                // 非同租户不展示 publicTag
                return nil
            }
            return displayTag.tagValue
        } else {
            // 旧的本地判断逻辑
            if let currentTenantID,
               let tenantID,
               currentTenantID != tenantID {
                return nil
            }
            if isOpenSharing {
                return BundleI18n.SKResource.LarkCCM_Wiki_WebAccess_Tag
            } else if isPublic {
                return BundleI18n.SKResource.LarkCCM_Wiki_OrgAccess_Tag
            } else {
                return nil
            }
        }
    }
}
