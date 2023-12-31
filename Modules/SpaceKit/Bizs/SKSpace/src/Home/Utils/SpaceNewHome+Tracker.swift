//
//  SpaceHome2.0+Tracker.swift
//  SKSpace
//
//  Created by majie.7 on 2023/9/18.
//

import Foundation
import SKCommon
import SKFoundation
import SKWorkspace
import SpaceInterface
import LarkDocsIcon

public struct SpaceNewHomeTracker {
    
    public static func reportSpaceHomePageView() {
        var dic: [String: Any] = ["space_version": "new_format"]
        dic.merge(other: SpaceBizParameter(module: .home(.homeTree)).params)
        DocsTracker.log(enumEvent: .spaceHomePageView, parameters: dic)
    }
    
    public static func reportUnsortedPageView() {
        let dic: [String: Any] = ["module": "unsorted"]
        DocsTracker.log(enumEvent: .spaceUnsortedPageView, parameters: dic)
    }
    
    public static func reportSpaceDrivePageView() {
        let dic: [String: Any] = [
            "space_version": "new_format",
            "module": "new_drive"
        ]
        DocsTracker.log(enumEvent: .spaceDrivePageView, parameters: dic)
    }
    
    public static func reportSpaceHomePageClick(params: SpacePageClickParameter) {
        DocsTracker.reportSpaceHomePageClick(
            params: params,
            bizParms: SpaceBizParameter(module: .home(.homeTree))
        )
    }

    public static func reportSpaceHomeTreeClick(scene: HomeTreeSectionScene, isExpand: Bool) {
        var dic: [String: Any] = ["space_version": "new_format", "target": "none"]
        switch scene {
        case .clipDocument:
            dic["location"] = "sidebar_pin_docs"
            dic["click"] = isExpand ? "expand_pindocs" : "collapse_pindocs"
        case .clipWikiSpace:
            dic["location"] = "sidebar_pin_wiki"
            dic["click"] = isExpand ? "expand_pinwiki" : "collapse_pinwiki"
        case .shared:
            dic["location"] = "sidebar_shared"
            dic["click"] = isExpand ? "expand_shared" : "collapse_shared"
        case .personal:
            dic["location"] = "sidebar_my_docs"
            dic["click"] = isExpand ? "expand_personal" : "collapse_personal"
        }
        DocsTracker.newLog(enumEvent: .wikiTreeClick, parameters: dic)
    }
    
    public static func reportSpaceHomeViewAllSharedClick() {
        let dic: [String: Any] = ["space_version": "new_format",
                                  "location": "sidebar_shared",
                                  "click": "view_all_shared",
                                  "target": "ccm_space_shared_page_view"]
        DocsTracker.newLog(enumEvent: .wikiTreeClick, parameters: dic)
    }
    
    public static func reportSpaceHomeTreeItemClick(docsType: DocsType?, scene: HomeTreeSectionScene) {
        var dic: [String: Any] = [
            "space_version": "new_format",
            "target": "ccm_docs_page_view",
            "click": "page"
        ]

        if let docsType {
            dic["file_type"] = docsType.name
        }
        switch scene {
        case .clipDocument:
            dic["location"] = "sidebar_pin_docs"
        case .clipWikiSpace:
            dic["location"] = "sidebar_pin_wiki"
        case .shared:
            dic["location"] = "sidebar_shared"
        case .personal:
            dic["location"] = "sidebar_my_docs"
        }
        DocsTracker.newLog(enumEvent: .wikiTreeClick, parameters: dic)
    }
}
