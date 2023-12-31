//
//  SpaceHomeTracker.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/25.
//

import Foundation
import SKFoundation
import SKCommon

struct SpaceHomeTracker: SpaceTracker {

    let bizParameter: SpaceBizParameter

    enum TabSource: String {
        static let key = "tab_source"
        case clickTab = "tab_click"
        case clickLink = "link_click"
    }

    func reportEnterHome(from: TabSource) {
        let p: P = [
            TabSource.key: from.rawValue
        ]
        DocsTracker.log(enumEvent: .clickEnterExplorerModule, parameters: p)
    }

    func reportDocsTabShow() {
        DocsTracker.log(enumEvent: .clickDocsTab, parameters: nil)
    }

    func reportAppear(module: PageModule, subModule: HomePageSubModule) {
        DocsTracker.reportSpaceHomePageView(module: module, subModule: subModule)
    }

    func reportAppear(module: PageModule) {
        switch module {
        case .favorites:
            DocsTracker.reportSpaceFavoritesPageView()
        case .offline:
            DocsTracker.reportSpaceOfflinePageView()
        case .personal:
            DocsTracker.reportSpacePersonalPageView()
        case .shared:
            DocsTracker.reportSpaceSharedPageView()
        case let .baseHomePage(context):
            DocsTracker.reportBitableHomePageView(context: context)
        default: break
        }
    }

}
