//
//  EmptyListAutoRefresher.swift
//  SKECM
//
//  Created by Weston Wu on 2020/7/26.
//

import Foundation
import SKCommon

/// 空实现，不会触发自动刷新，用于 FG 关的场景
class EmptyListAutoRefresher: SpaceListAutoRefresher {
    var actionHandler: NotifyRefreshHandler?

    func setup() {}

    func start() {}

    func stop() {}

    func notifySyncEvent() {}

    func notifyFileDeleted(token: FileListDefine.ObjToken) {}
}
