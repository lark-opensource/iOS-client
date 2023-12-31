//
//  WikiTreeMoreProvider+Offline.swift
//  SKWorkspace
//
//  Created by Wenjun Chen on 2023/9/20.
//

import Foundation
import SKCommon
import SKFoundation
import SKInfra
import SKResource
import SpaceInterface

extension WikiMainTreeMoreProvider {
    func toggleOfflineAccess(meta: WikiTreeNodeMeta) {
        guard let entry = meta.transformFileEntry() as? WikiEntry else {
            return
        }

        let docsInfo = meta.transform()
        let isSetManualOffline = docsInfo.checkIsSetManualOffline()

        // Reuse the logic of adding offline access in document details page,
        // because the wiki document may not be in the Space list.
        ManualOfflineHelper.handleManualOfflineFromDetailPage(
            entry: entry,
            wikiInfo: entry.wikiInfo,
            isAdd: !isSetManualOffline
        )
        WikiStatistic.clickWikiTreeMore(
            click: isSetManualOffline ? .removeOffline : .addOffline,
            isFavorites: meta.isExplorerStar,
            target: DocsTracker.EventType.wikiTreeMoreView.rawValue,
            meta: meta
        )

        if isSetManualOffline {
            self.showSuccess(with: BundleI18n.SKResource.Doc_Facade_RemoveSuccessfully)
        } else {
            self.showSuccess(with: BundleI18n.SKResource.Doc_Facade_EnableManualCache)
        }
    }
}
