//
//  WorkspaceTracker.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/5/11.
//

import Foundation
import SKFoundation

public enum WorkspaceTracker {

    private typealias P = [AnyHashable: Any]

    public enum RedirectReason: String {
        case hitCache = "hit_cache"
        case missCache = "miss_cache"
        case noCache = "no_cache"
        case wrongCache = "wrong_cache"
        case mismatchCache = "mismatch_cache"
    }
    public static func reportWorkspaceRedirectEvent(record: WorkspaceCrossRouteRecord, reason: RedirectReason) {
        let params: P = [
            "wiki_token": DocsTracker.encrypt(id: record.wikiToken),
            "obj_token": DocsTracker.encrypt(id: record.objToken),
            "obj_type": record.objType.rawValue,
            "redirect_to": record.inWiki ? "wiki" : "space",
            "redirect_reason": reason.rawValue,
            "log_id": record.logID ?? "null"
        ]
        DocsTracker.newLog(enumEvent: .workspaceRedirectEvent, parameters: params)
    }
}
