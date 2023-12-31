//
//  MoreVCGuideConfig.swift
//  SKECM
//
//  Created by lijuyou on 2020/7/14.
//  


import Foundation
import SKFoundation
import SpaceInterface
import SKInfra

// 先把大家写的红点逻辑收拢到这里
// 现在MoreViewController有两套逻辑
// 1. 打开后显示红点，无论点不点击，都会设置红点消失
// 2. 打开后显示红点，点不点击才会红点消失
// 3. 打开后显示红点，点不点击才会红点消失，还要受前端控制
// 暂时使用这块，后续统一后集中处理

public enum MoreVCGuideConfig {
    /// 用于判断特殊红点逻辑
    public static func shouldDisplaySpecialGuide(docsType: DocsType,
                                                 itemType: MoreItemType,
                                                 controlByFrontend: [String]?) -> Bool {
        return showNewFeatureIfNeedWithType(itemType)
    }

    public static func showNewFeatureIfNeedWithType(_ type: MoreItemType) -> Bool {
        guard let identifier = type.newTagIdentifiler else {
            return false
        }
        return !CCMKeyValue.globalUserDefault.bool(forKey: identifier)
    }

    public static func updateNewTapDataIfNeed(docsType: DocsType, type: MoreItemType) {
        guard let identifier = type.newTagIdentifiler,
              CCMKeyValue.globalUserDefault.bool(forKey: identifier) == false else {
            return
        }
        if type == .share, !docsType.isSupportShareNewTag {
            return
        }
        CCMKeyValue.globalUserDefault.set(true, forKey: identifier)
    }
    
    
    /// 判断更多菜单是否需要展示小红点引导，isOwner 目前仅用于文档单品内分享按钮的判断
    public static func shouldDisplayGuide(docsType: DocsType, itemType: MoreItemType, isOwner: Bool) -> Bool {
        guard let configKey = remoteConfigGuideId(item: itemType, docsType: docsType) else { return false }
        guard let dic = CCMKeyValue.globalUserDefault.dictionary(forKey: UserDefaultKeys.moreVCNewFeature) else { return false }
        let everDisplay = CCMKeyValue.globalUserDefault.bool(forKey: guideKey(docsType: docsType, itemType: itemType))
        var remoteAllowDisplay = false
        if let remoteFlag = dic[configKey] as? Bool, remoteFlag == true {
            remoteAllowDisplay = true
        }
        return !everDisplay && remoteAllowDisplay
    }
    public static func remoteConfigGuideId(item: MoreItemType, docsType: DocsType) -> String? {
        let searchIdentifier = "search"
        let importAsDocs = "import_docs"
        let translateIdentifier = "translate"
        let saveAsTemplateIdentifier = "save_as_template"

        let mapping: [MoreItemType: String] = [.searchReplace: searchIdentifier,
                                               .importAsDocs(docsType.fileTypeForSta): importAsDocs,
                                               .translate: translateIdentifier,
                                               .saveAsTemplate: saveAsTemplateIdentifier]
        let guideIdentifier = mapping[item]
        guard let realId = guideIdentifier else { return nil }        
        let allowMapping: [String: [DocsType]] = [searchIdentifier: [.sheet],
                                                  importAsDocs: [.file],
                                                  translateIdentifier: [.doc],
                                                  saveAsTemplateIdentifier: [.doc, .sheet, .mindnote]]
        let allowTypes = allowMapping[realId]?.filter({ (type) -> Bool in
            return type == docsType
        })

        if let types = allowTypes, !types.isEmpty {
            return guideIdentifier
        }
        return nil
    }

    public static func markHasFinishGuide(docsType: DocsType, itemType: MoreItemType) {
        CCMKeyValue.globalUserDefault.set(true, forKey: guideKey(docsType: docsType, itemType: itemType))
    }

    public static func guideKey(docsType: DocsType, itemType: MoreItemType) -> String {
        let guideId = remoteConfigGuideId(item: itemType, docsType: docsType) ?? "default"
        let key = "com.bytedance.ee.docs.guidedisplay." + docsType.name + guideId
        return key
    }
}


extension DocsType {
    fileprivate var isSupportShareNewTag: Bool {
        return self.isOpenByWebview //对齐安卓逻辑，只有creation文档支持分享红点
    }
}
