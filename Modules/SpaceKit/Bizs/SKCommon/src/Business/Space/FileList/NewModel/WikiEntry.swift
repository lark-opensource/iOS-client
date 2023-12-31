//
//  WikiEntry.swift
//  SKCommon
//
//  Created by guoqp on 2020/9/8.
//

import Foundation
import SKResource
import UniverseDesignIcon
import SKFoundation
import SpaceInterface
import SKInfra
import LarkDocsIcon

open class WikiEntry: SpaceEntry {

    public private(set) var wikiInfo: WikiInfo?
    
    // wiki文档的真实objToken
    public override var realToken: String {
        return self.wikiInfo?.objToken ?? super.realToken
    }
    
    // 内容是否仍然存在于 wiki 中，如收藏 wiki 后，将文档移动到 space 里，值为 false
    public var contentExistInWiki: Bool {
        // 后端值的含义是文档是否被移出 wiki，为了表意清晰端上取反表示
        let notWikiObj = extra?["not_wiki_obj"] as? Bool ?? false
        return !notWikiObj
    }

    /// 是否在 Wiki 容器中
    /// extra 结构体中biz_type字段，1：表示space容器，2：表示wiki容器，-1：表示不存在容器或者未知类型
    public var isInWiki: Bool {
        if let bizType = extra?["biz_type"] as? Int {
            return bizType == 2
        }
        return true
    }

    public func update(wikiInfo: WikiInfo) {
        self.wikiInfo = wikiInfo
    }

    public override func updateExtra() {
        super.updateExtra()
        guard let extraDic = extra else { return }
        if let subtype = extraDic["wiki_subtype"] as? Int,
           let realToken = extraDic["wiki_sub_token"] as? String,
           let spaceId = extraDic["wiki_space_id"] as? String {
            DocsLogger.info("updateExtra get wiki \(realToken.prefix(6))")
            self.wikiInfo = WikiInfo(wikiToken: self.objToken,
                                     objToken: realToken,
                                     docsType: DocsType(rawValue: subtype),
                                     spaceId: spaceId,
                                     shareUrl: shareUrl)
        } else {
            DocsLogger.error("wikiEntry extra数据解析错误")
        }
    }
    
    public override var canOpenWhenOffline: Bool {
        guard let wikiInfo = wikiInfo else {
            return false
        }
        guard wikiInfo.docsType.offLineEnable else { return false }
        guard wikiInfo.docsType == .file else {
            // 非drive类型wiki 走父类实现
            return super.canOpenWhenOffline
        }
        
        guard secretKeyDelete != true else {
            return false
        }
        guard wikiInfo.docsType.offLineEnable else {
            return false
        }
        let fileExt = SKFilePath.getFileExtension(from: name)
        return DocsContainer.shared.resolve(DriveCacheServiceBase.self)?.canOpenOffline(token: wikiInfo.objToken,
                                                                                        dataVersion: nil,
                                                                                        fileExtension: fileExt) ?? false
    }

    public override func makeCopy(newNodeToken: String? = nil, newObjToken: String? = nil) -> SpaceEntry {
        let another = super.makeCopy(newNodeToken: newNodeToken, newObjToken: newObjToken)
        if let wikiEntry = another as? WikiEntry {
            wikiEntry.wikiInfo = wikiInfo
        }
        return another
    }

    public override func equalTo(_ another: SpaceEntry) -> Bool {
        guard let compareEntry = another as? WikiEntry else { return false }
        return super.equalTo(compareEntry) &&
            wikiInfo?.wikiToken == compareEntry.wikiInfo?.wikiToken
    }

    public override var description: String {
        return "WikiEntry - " + super.description
    }

    public override var defaultIcon: UIImage {
        guard let contentSubType = wikiInfo?.docsType else {
            return UDIcon.getIconByKeyNoLimitSize(.fileRoundUnknowColorful)
        }
        return Self.wikiListIcon(contentType: contentSubType, name: name)
    }

    public override var colorfulIcon: UIImage {
        guard let contentSubType = wikiInfo?.docsType else {
            return UDIcon.getIconByKey(.fileDocColorful, size: CGSize(width: 48, height: 48))
        }
        return Self.wikiColorfulIcon(contentType: contentSubType)
    }

    public static func wikiListIcon(contentType: DocsType, name: String) -> UIImage {
        switch contentType {
        case .file:
            let ext = SKFilePath.getFileExtension(from: name)
            let fileType = DriveFileType(fileExtension: ext)
            return fileType.roundImage
                ?? UDIcon.getIconByKeyNoLimitSize(.fileRoundUnknowColorful)
        default:
            return UDIcon.getIconByKeyNoLimitSize(contentType.roundColorfulIconKey)
        }
    }

    public static func wikiColorfulIcon(contentType: DocsType) -> UIImage {
        return UDIcon.getIconByKey(contentType.roundColorfulIconKey, size: CGSize(width: 48, height: 48))
    }

    public override var preloadKey: PreloadKey {
        return PreloadKey(objToken: objToken,
                          type: type,
                          wikiInfo: wikiInfo)
    }

    public override func transform() -> DocsInfo {
        let docsInfo = super.transform()
        if !contentExistInWiki, let wikiInfo {
            /// 对于收藏/快速访问列表中会出现的已经不存在于wiki的wiki文档，将token和type转化为实体的数据
            docsInfo.objToken = wikiInfo.objToken
            docsInfo.type = wikiInfo.docsType
        } else {
            docsInfo.wikiInfo = wikiInfo
        }
        return docsInfo
    }
    
    // 是否允许设置手动离线
    public override var canSetManualOffline: Bool {
        // 密钥删除状态，禁止设置手动离线
        guard secretKeyDelete != true else {
            return false
        }
        if let wikiInfo {
            return ManualOfflineConfig.enableFileType(wikiInfo.docsType)
        } else {
            return false
        }
    }

    public override var isEnableShowInList: Bool {
        if wikiInfo?.docsType == .slides {
            return true
        }
        return super.isEnableShowInList && wikiInfo?.docsType.enabledByFeatureGating ?? false
    }

}
