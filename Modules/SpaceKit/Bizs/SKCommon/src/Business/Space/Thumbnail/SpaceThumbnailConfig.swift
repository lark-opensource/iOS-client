//
//  SpaceThumbnailConfig.swift
//  SKCommon
//
//  Created by Weston Wu on 2020/8/9.
//

import Foundation
import SKFoundation

public final class SpaceThumbnailConfig {
    private(set) var chatStacksCount: Int = 0
    private var needRefreshForTheFirstTime: Bool {
        return chatStacksCount != 0
    }
    private var requestedThumbnailKeys: Set<URL> = []

    public func notifyEnterChatPage() {
        chatStacksCount += 1
        DocsLogger.info("space.thumbnail.config --- entering chat page, stacks count: \(chatStacksCount)")
    }

    public func notifyLeaveChatPage() {
        guard chatStacksCount > 0 else {
            spaceAssertionFailure("space.thumbnail.config --- chat stacks count must be greater or equal to 0!")
            DocsLogger.error("space.thumbnail.config --- chat stacks count must be greater or equal to 0!")
            return
        }
        chatStacksCount -= 1
        DocsLogger.info("space.thumbnail.config --- leaving chat page, stacks count: \(chatStacksCount)")
        if chatStacksCount == 0 {
            DocsLogger.info("space.thumbnail.config --- chat page stacks is empty, cleaning keys.")
            requestedThumbnailKeys.removeAll()
        }
    }

    public func checkNeedRefresh(key: URL) -> Bool {
        guard needRefreshForTheFirstTime else { return false }
        if requestedThumbnailKeys.contains(key) {
            return false
        } else {
            requestedThumbnailKeys.insert(key)
            return true
        }
    }
}
