//
//  WikiMainTreeViewModel+Sync.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/7/29.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import SKFoundation
import SKCommon
import SpaceInterface

// MARK: - Tree Sync
extension WikiMainTreeViewModel {
    // 注意所有 handle 方法都要在主线程调用
    // swiftlint:disable:next function_body_length
    func setupSyncProcessor() {
        treeSyncDispatchHandler.addDispather(spaceId: self.spaceID, synergyUUID: synergyUUID)
    }
}
